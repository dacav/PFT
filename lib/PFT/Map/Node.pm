package PFT::Map::Node v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Map::Node - Node of a PFT site map

=head1 SYNOPSIS

    PFT::Map::Node->new($seqnr, $id, $content);
    PFT::Map::Node->new($seqnr, $id, undef, $header);
    PFT::Map::Node->new($seqnr, $id, $content, $header);

Nodes are created within a PFT::Map object. The constructor should
therefore not be called directly.

Each node is identified by a unique sequence number and by a mnemonic
identifier. This details are used within PFT::Map.

=over 1

=head1 DESCRIPTION

=cut

use Carp;
use WeakRef;

sub new {
    my($cls, $seqnr, $id, $cont, $hdr) = @_;
    confess 'Need content or header' unless $cont || $hdr;
    confess "Not content: $cont" unless $cont->isa('PFT::Content::Base');

    bless {
        seqnr   => $seqnr,
        id      => $id,
        cont    => $cont,

        # Rule of the game: header might be obtained by content, but if
        # content is virtual (i.e. !$coontent->exists) it must be
        # provided. Only PFT::Content::Entry object have headers.
        hdr     => defined $hdr
            ? $hdr
            : $cont->isa('PFT::Content::Entry')
                ? do {
                    $cont->exists or confess
                        "No header for virtual content $cont";
                    $cont->header
                }
                : undef
    }, $cls
}

=head2 Properties

=over 1

=item header

Header associated with this node. This property could return undefined for
the nodes which are associated with a non-textual content (like images or
attachments). A header will exist for non-existent pages (like tags which
do not have a tag page).

=cut

sub header { shift->{hdr} }

=item content

The content associated with this node. This property could return
undefined for the nodes which do not correspond to any content. In this
case we talk about I<virtual files>, in that the node should be
represented anyway in a compiled PFT site.

=cut

sub content { shift->{cont} }

=item date

Returns the date of the content, or undef if the content is not recording
any date.

=cut

sub date {
    my $hdr = shift->header;
    $hdr ? $hdr->date : undef
}

=item seqnr

Returns the sequential id of the node w.r.t. the map

=cut

sub seqnr { shift->{seqnr} }

=item id

Returns the mnemonic unique identifier.

=cut

sub id { shift->{id} }

=item title

Returns the title of the content, if any

=cut

sub title {
    my $self = shift;
    my $hdr = $self->header;
    unless (defined $hdr) { return undef }
    my $title = $hdr->title;
    if (!defined($title) && $self->content->isa('PFT::Content::Month')) {
        sprintf("%04d / %02d", @{$hdr->date}[0, 1])
    } else {
        $title;
    }
}

=item virtual

Returns 1 if the node is virtual.

A virtual node C<$n> does not correspond with an existing content file.

=cut

sub virtual { !shift->{cont}->exists }

=item content_type

Returns the type of the content. Short for C<ref($node-E<gt>content)>

=cut

sub content_type { ref(shift->content) }

sub next { shift->{next} }

sub prev {
    my $self = shift;
    return $self->{prev} unless @_;

    my $p = shift;
    weaken($self->{prev} = $p);
    weaken($p->{next} = $self);
}

sub month {
    my $self = shift;
    unless (@_) {
        exists $self->{month} ? $self->{month} : undef;
    } else {
        confess 'Must be dated and date-complete'
            unless eval{ $self->{hdr}->date->complete };

        my $m = shift;
        weaken($self->{month} = $m);

        push @{$m->{days}}, $self;
        weaken($m->{days}[-1]);
    }
}

sub _add {
    my($self, $linked, $ka, $kb) = @_;

    push @{$self->{$ka}}, $linked;
    weaken($self->{$ka}[-1]);

    push @{$linked->{$kb}}, $self;
    weaken($linked->{$kb}[-1]);
}

sub add_outlink { shift->_add(shift, 'olns', 'inls') }
sub add_tag { shift->_add(shift, 'tags', 'tagged') }

sub _list {
    my($self, $name) = @_;
    exists $self->{$name}
        ? wantarray ? @{$self->{$name}} : $self->{$name}
        : wantarray ? () : undef
}

sub tags { shift->_list('tags') }
sub tagged { shift->_list('tagged') }
sub days { shift->_list('days') }
sub inlinks { shift->_list('ilns') }
sub outlinks { shift->_list('olns') }

sub children {
    my $self = shift;
    $self->_list('tagged'),
    $self->_list('days'),
}

sub unresolved {
    my $self = shift;
    unless (@_) {
        exists $self->{unres_syms}
            ? @{$self->{unres_syms}}
            : ()
    } else {
        push @{$self->{unres_syms}}, @_
    }
}

=item html

Expand HTML of the content, translating outbound links into
hyper-references (hrefs).

Requires as parameter a callback mapping a PFT::Map::Node object into
a string representing path within the site. The callback is applied to all
symbols, and the resulting string will replace the symbol placeholder in
the HTML.

Returns a string with encoded HTML, or an empty string if the node is
virtual.

=cut

sub html {
    my $self = shift;
    return undef if $self->virtual;

    my $mkhref = shift;
    PFT::Text->new($self->content)->html_resolved(
        map $mkhref->($_), $self->outlinks
    );
}

=back

=cut

use overload
    '<=>' => sub {
        my($self, $oth, $swap) = @_;
        my $out = $self->{seqnr} <=> $oth->{seqnr};
        $swap ? -$out : $out;
    },
    '""' => sub {
        my $self = shift;
        'PFT::Map::Node[id=' . $self->id
            . ', virtual=' . ($self->virtual ? 'yes' : 'no')
            . ']'
    },
;

1;
