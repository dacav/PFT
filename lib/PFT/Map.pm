package PFT::Map v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Map - Map of a PFT site

=head1 SYNOPSIS

    my $tree = PFT::Content->new($basedir);
    PFT::Map->new($tree);

=head1 DESCRIPTION

Map of a PFT site

=cut

use Carp;
use WeakRef;
use File::Spec;

use PFT::Map::Node;
use PFT::Map::Resolver qw/resolve/;
use PFT::Text;
use PFT::Header;

sub new {
    my $cls = shift;
    my $tree = shift;
    confess 'want a PFT::Content, got ', ref($tree)
        unless $tree->isa('PFT::Content');

    my $self = bless {
        tree => $tree,
        idx => {},
        next => 0,
        toresolve => [],
    }, $cls;

    $self->_scan_pages;
    $self->_scan_blog;
    $self->_scan_tags;
    $self->_scan_attach;
    $self->_scan_pics;
    $self->_resolve;
    $self;
}

sub _resolve {
    # Resolving items in $self->{toresolve}. They are inserted in _mknod.
    my $self = shift;

    for my $node (@{$self->{toresolve}}) {
        for my $s ($node->symbols) {
            if (my $resolved = resolve($self, $node, $s)) {
                $resolved->isa('PFT::Map::Node') or confess
                    "Buggy resolver: searching $s",
                    ', expected node, got ',
                    ref($resolved) || $resolved;
                $node->add_outlink($resolved);
            }
            else {
                $node->symbols_unres($s)
            }
        }
    }
    delete $self->{toresolve}
};

sub _content_id {
    # Given a PFT::Content::Base (or any subclass) object, returns a
    # string uniquely identifying it across the site. E.g.:
    #
    #     my $id = $map->_content_id($content);
    #     my $id = $map->_content_id($virtual_page, $hdr);
    #     my $id = $map->_content_id(undef, $hdr);
    #
    # Form 1: for any content

    my($self, $cntnt, $hdr) = @_;

    unless (defined $cntnt) {
        confess 'No content, no header?' unless defined $hdr;
        $cntnt = $self->{tree}->entry($hdr);
    }

    ref($cntnt) =~ /PFT::Content::(Page|Blog|Picture|Attachment|Tag|Month)/
        or confess 'Unsupported in content to id: ' . ref($cntnt);

    if ($1 eq 'Page') {
        'p:' . ($hdr || $cntnt->header)->slug
    } elsif ($1 eq 'Tag') {
        't:' . ($hdr || $cntnt->header)->slug
    } elsif ($1 eq 'Blog') {
        my $hdr = ($hdr || $cntnt->header);
        'b:' . $hdr->date->repr('') . ':' . $hdr->slug
    } elsif ($1 eq 'Month') {
        my $hdr = ($hdr || $cntnt->header);
        'm:' . $hdr->date->repr('')
    } elsif ($1 eq 'Picture') {
        'i:' . join '/', $cntnt->relpath # No need for portability
    } elsif ($1 eq 'Attachment') {
        'a:' . join '/', $cntnt->relpath # Ditto
    } else { die };
}

sub _mknod {
    my $self = shift;
    my($cntnt, $hdr) = @_;

    my $node = PFT::Map::Node->new(
        $self->{next} ++,
        (my $id = $self->_content_id(@_)),
        @_,
    );

    if ($cntnt and $cntnt->isa('PFT::Content::Entry') and $cntnt->exists) {
        push @{$self->{toresolve}}, $node
    }
    die if exists $self->{idx}{$id};
    $self->{idx}{$id} = $node;
}

sub _scan_pages {
    my $self = shift;
    $self->_mknod($_) foreach $self->{tree}->pages_ls;
}

sub _scan_blog {
    my $self = shift;
    my $tree = $self->{tree};
    my @blog = map $self->_mknod($_),
        grep !$_->isa('PFT::Content::Month'), $tree->blog_ls;

    my($prev, $prev_month, $last_month);
    foreach (sort { $a->date <=> $b->date } @blog) {
        $_->prev($prev) if defined $prev;

        $_->month(do {
            my $m_date = $_->date->derive(d => undef);

            if (!defined($prev_month) or $prev_month->date <=> $m_date) {
                my $m_hdr = PFT::Header->new(
                    date => $m_date,
                    encoding => $_->header->encoding,
                );
                my $m_page = $tree->entry($m_hdr);
                my $n = $self->_mknod($m_page,
                    $m_page->exists ? $m_page->header : $m_hdr
                );
                $n->prev($prev_month) if defined $prev_month;
                $last_month = $prev_month = $n;
            }
            $prev_month
        });

        $prev = $_;
    }

    @{$self}{'last', 'last_month'} = ($prev, $last_month);
}

sub _scan_tags {
    my $self = shift;
    my $tree = $self->{tree};
    my %tags;

    for my $node (sort { $a <=> $b } values %{$self->{idx}}) {
        foreach (sort $node->header->tags_slug) {
            my $t_node = exists $tags{$_} ? $tags{$_} : do {
                my $t_hdr = PFT::Header->new(
                    title => $_,
                    encoding => $node->header->encoding,
                );
                my $t_page = $tree->tag($t_hdr);
                $tags{$_} = $self->_mknod($t_page,
                    $t_page->exists ? $t_page->header : $t_hdr
                );
            };
            $node->add_tag($t_node);
        }
    }
}

sub _scan_attach {
    my $self = shift;
    $self->_mknod($_) for $self->{tree}->attachments_ls;
}

sub _scan_pics {
    my $self = shift;
    $self->_mknod($_) for $self->{tree}->pics_ls;
}

=head2 Properties

=over

=item nodes

List the nodes

=cut

sub nodes { values %{shift->{idx}} }

=item tree

The associated content tree

=cut

sub tree { shift->{tree} }

=item pages

List page nodes

=cut

sub _grep_content {
    my($self, $type) = @_;
    grep{ $_->content_type eq $type } $self->nodes
}

sub pages { shift->_grep_content('PFT::Content::Page') }

=item months

List month nodes

=cut

sub months { shift->_grep_content('PFT::Content::Month') }

=item tags

List tag nodes

=cut

sub tags { shift->_grep_content('PFT::Content::Tag') }

=item dump

Dump of the nodes in a easy-to-display form, that is a list of dictionaries.

This method is used mainly or solely for testing.

=cut

sub dump {
    my $node_dump = sub {
        my $node = shift;
        my %out = (
            id => $node->seqnr,
            tt => $node->title || do {
                do {
                    my $cnt = $node->content;
                    $cnt->isa('PFT::Content::Month') ? '<month>' :
                    $cnt->isa('PFT::Content::Attachment') ? '<attachment>' :
                    $cnt->isa('PFT::Content::Picture')    ? '<picture>'    :
                    confess "what is $node?";
                }
            },
        );

        if (defined(my $prev = $node->prev)) { $out{'<'} = $prev->seqnr }
        if (defined(my $next = $node->next)) { $out{'>'} = $next->seqnr }
        if (defined(my $month = $node->month)) { $out{'^'} = $month->seqnr }
        if (defined($node->header)
                and defined(my $date = $node->header->date)) {
            $out{d} = "$date"
        }
        if (my @l = $node->days) {
            $out{v} = [sort { $a <=> $b } map{ $_->seqnr } @l]
        }
        if (my @l = $node->tags) {
            $out{t} = [sort { $a <=> $b } map{ $_->seqnr } @l]
        }
        if (my @l = $node->tagged) {
            $out{'.'} = [sort { $a <=> $b } map{ $_->seqnr } @l]
        }

        \%out
    };

    my $self = shift;
    map{ $node_dump->($_) }
        sort{ $a <=> $b }
        values %{$self->{idx}}
}

=back

=head2 Methods

=cut

=item node_of

Given a PFT::Content::Base (or any subclass) object, returns the
associated node, or undef if such node does not exist.

=cut

sub node_of {
    my $self = shift;
    my $id = $self->_content_id(@_);

    exists $self->{idx}{$id} ? $self->{idx}{$id} : undef
}

=item recent_blog

The I<N> most recent blog nodes.

The number I<N> is given as parameter, and defaults to 1. The method
returns up to I<N> nodes, ordered by date, from most to least recent.

=cut

sub _recent {
    my($self, $key, $n) = @_;

    $n = 1 unless defined $n;
    confess "Requires N > 0, got $n" if $n < 1;

    my @out;
    my $cursor = $self->{$key};
    while ($n -- && defined $cursor) {
        push @out, $cursor;
        $cursor = $cursor->prev;
    }

    @out;
}

sub recent_blog { shift->_recent('last', shift) }

=item recent_months

The I<N> most recent months node.

The number I<N> is given as parameter, and defaults to 1. The method
returns up to I<N> nodes, ordered by date, from most to least recent.

=cut

sub recent_months { shift->_recent('last_month', shift) }

=back

=cut

1;
