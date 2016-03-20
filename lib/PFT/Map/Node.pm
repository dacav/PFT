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

=over 1

=head1 DESCRIPTION

=cut

use Carp;
use WeakRef;

sub new {
    my($cls, $seqnr, $id, $cont, $hdr) = @_;
    confess 'Need content or header' unless $cont || $hdr;

    my $self = {
        seqnr   => $seqnr,
        id      => $id,
    };

    if (defined $cont) {
        confess "Not content: $cont"
            unless $cont->isa('PFT::Content::Base');
        $self->{cont} = $cont;
    }
    if (defined $hdr) {
        confess "Not header $hdr"
            unless $hdr->isa('PFT::Header');
        $self->{hdr} = $hdr;
    }

    bless $self, $cls;
}

=head2 Properties

=over 1

=item header

Header associated with this node. This property could return undefined for
the nodes which are associated with a non-textual content (like images or
attachments). A header will exist for non-existent pages (like tags which
do not have a tag page).

=cut

sub header {
    my $self = shift;
    exists $self->{hdr}
        ? $self->{hdr}
        : do {
            my $cont = $self->{cont};
            $self->{hdr} = $cont->isa('PFT::Content::Entry')
                ? $cont->header
                : undef
        }
}

=item content

The content associated with this node. This property could return
undefined for the nodes which do not correspond to any content. In this
case we talk about I<virtual files>, in that the node should be
represented anyway in a compiled PFT site.

=cut

sub content { shift->{cont} }

sub kind { substr(shift->{id}, 0, 1) }

sub date {
    my $self = shift;
    $self->header
        ? $self->{hdr}->date
        : undef
}

sub next { shift->{next} }
sub seqnr { shift->{seqnr} }
sub id { shift->{id} }

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

=back

=cut

use overload
    '<=>' => sub {
        my($self, $oth, $swap) = @_;
        my $out = $self->{seqnr} <=> $oth->{seqnr};
        $swap ? -$out : $out;
    },
    '""' => sub {
        'PFT::Map::Node[id='.shift->{id}.']'
    },
;

1;
