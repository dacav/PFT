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

    my $node = PFT::Map::Node->($from, $kind, $seqid, $resolver);

=over 1

=item C<$from> can either be a C<PFT::Header> or a C<PFT::Content::Base>;

=item Valid vaulues for C<$kind> match C</^[bmpt]$/>;

=item C<$seqid> is a numeric sequence number.

=head1 DESCRIPTION

=cut

use Carp;
use WeakRef;

use PFT::Text;

sub new {
    my($cls, $from, $kind, $seqnr) = @_;

    my($hdr, $file);
    if ($from->isa('PFT::Header')) {
        $hdr = $from;
    } else {
        confess 'Allowed only PFT::Header or PFT::Content::Base'
            unless $from->isa('PFT::Content::File');
        $file = $from;
        $hdr = $from->header if $from->isa('PFT::Content::Page');
    }
    $kind =~ /^[bmptia]$/
        or confess "Invalid kind $kind. Valid: b|m|p|t|i|a";

    bless {
        kind => $kind,
        id => do {
            my $id = $kind;
            $id .= '.' . $hdr->date->repr('.') if $kind =~ '[bm]';

            # [m]onths have no slug;
            # [b]log [p]ages and [t]ags do have headers
            # [a]ttachments and [i]mages have files
            $kind eq 'm'     ? $id :
            $kind =~ '[bpt]' ? $id . '.' . $hdr->slug :
            $kind =~ '[ai]'  ? join '.', $id, $file->relpath :
            confess "What is '$id'?";
        },
        seqnr => $seqnr,
        hdr => $hdr,
        file => $file,
    }, $cls;
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

=item file

The file associated with this node. This property could return undefined
for the nodes which do not correspond to any content. In this case we talk
about I<virtual files>, in that the node should be represented anyway in a
compiled PFT site.

=cut

sub file { shift->{file} }

sub kind { shift->{kind} }
sub date { shift->{hdr}->date }
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
