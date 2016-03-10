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
use PFT::Map::Node;
use WeakRef;

sub new {
    my $cls = shift;
    my $tree = shift;
    confess 'want a PFT::Content, got ', ref($tree)
        unless $tree->isa('PFT::Content');

    my $self = bless {
        tree => $tree,
        idx => {},
        next => 0,
    }, $cls;

    $self->_scan_pages;
    $self->_scan_blog;
    $self->_scan_tags;
    $self;
}

sub _mknod {
    my $self = shift;
    my $node = PFT::Map::Node->new(
        shift,      # from: header | page
        shift,      # kind p|b|m|t
        $self->{next} ++,
    );
    $self->{idx}{$node->id} = $node;
}

sub _scan_pages {
    my $self = shift;
    $self->_mknod($_, 'p') foreach $self->{tree}->pages_ls;
}

sub _scan_blog {
    my $self = shift;
    my $tree = $self->{tree};
    my @blog = map $self->_mknod($_, 'b'), $tree->blog_ls;

    my($prev, $prev_month);
    foreach (sort { $a->date <=> $b->date } @blog) {
        $_->prev($prev) if defined $prev;

        $_->month(do {
            my $m_date = $_->date->derive(d => undef);

            if (!defined($prev_month) or $prev_month->date <=> $m_date) {
                my $m_hdr = PFT::Header->new(date => $m_date);
                my $m_page = $tree->entry($m_hdr);
                my $n = $self->_mknod(
                    $m_page->exists ? $m_page : $m_hdr,
                    'm',
                );
                $n->prev($prev_month) if defined $prev_month;
                $prev_month = $n;
            }
            $prev_month
        });

        $prev = $_;
    }
}

sub _scan_tags {
    my $self = shift;
    my $tree = $self->{tree};
    my %tags;

    for my $node (sort { $a <=> $b } values %{$self->{idx}}) {
        foreach (sort @{$node->header->tags}) {
            my $t_node = exists $tags{$_} ? $tags{$_} : do {
                my $t_hdr = PFT::Header->new(title => $_);
                my $t_page = $tree->tag($t_hdr);
                $tags{$_} = $self->_mknod(
                    $t_page->exists ? $t_page : $t_hdr,
                    't',
                );
            };
            $node->add_tag($t_node);
        }
    }
}

=head2 Properties

=over

=item nodes

List the nodes

=cut

sub nodes { values %{shift->{idx}} }

=item dump

Dump of the nodes in a easy-to-display form, that is a list of dictionaries.

This method is used mainly or solely for testing.

=cut

sub dump {
    my $node_dump = sub {
        my $node = shift;
        my %out = (
            id => $node->seqnr,
            tt => $node->header->title || '<month>',
        );

        if (defined(my $prev = $node->prev)) { $out{'<'} = $prev->seqnr }
        if (defined(my $next = $node->next)) { $out{'>'} = $next->seqnr }
        if (defined(my $month = $node->month)) { $out{'^'} = $month->seqnr }
        if (defined(my $date = $node->header->date)) { $out{d} = "$date" }
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

=cut

1;
