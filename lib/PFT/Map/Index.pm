# Copyright 2014-2016 - Giovanni Simoni
#
# This file is part of PFT.
#
# PFT is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# PFT is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PFT.  If not, see <http://www.gnu.org/licenses/>.

package PFT::Map::Index v0.6.0;

=encoding utf8

=head1 NAME

PFT::Map::Resolver - Resolve symbols in PFT Entries

=head1 SYNOPSIS

    use PFT::Map::Resolver 'resolve';

    die unless $map->isa('PFT::Map');
    die unless $node->isa('PFT::Map::Node');
    die unless $sym->isa('PFT::Text::Symbol');

    my $result = resolve($map, $node, $sym);

=head1 DESCRIPTION

This module only exports one function, named C<resolve>.

The function resolves a symbol retrieved from the text of a
C<PFT::Map::Node>. The returned value will be one of the following:

=over

=item A node (i.e. a C<PFT::Map::Node> instance);

=item A string (e.g. C<http://manpages.org>);

=item The C<undef> value (meaning: failed resolution).

=back

=cut

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;

sub new {
    my($cls, $map) = @_;
    bless \$map, $cls;
}

=head2 Properties

=over

=item map

Reference to the associated map

=cut

sub map { return ${shift()} }

=back

=head2 Methods

=over

=item content_id

Given a PFT::Content::Base (or any subclass) object, returns a
string uniquely identifying it across the site. E.g.:

     my $id = $resolver->content_id($content);
     my $id = $resolver->content_id($virtual_page, $hdr);
     my $id = $resolver->content_id(undef, $hdr);

The header is optional for the first two forms: unless supplied it will be
retrieved by the content. In the third form the content is not supplied,
so the header is mandatory.

=cut

sub content_id {
    my($self, $cntnt, $hdr) = @_;

    unless (defined $cntnt) {
        confess 'No content, no header?' unless defined $hdr;
        $cntnt = $self->map->{tree}->entry($hdr);
    }

    ref($cntnt) =~ /PFT::Content::(Page|Blog|Picture|Attachment|Tag|Month)/
        or confess 'Unsupported in content to id: ' . ref($cntnt);

    if ($1 eq 'Page') {
        'p:' . ($hdr || $cntnt->header)->slug
    } elsif ($1 eq 'Tag') {
        't:' . ($hdr || $cntnt->header)->slug
    } elsif ($1 eq 'Blog') {
        my $hdr = ($hdr || $cntnt->header);
        'b:' . $hdr->date->repr . ':' . $hdr->slug
    } elsif ($1 eq 'Month') {
        my $hdr = ($hdr || $cntnt->header);
        'm:' . $hdr->date->repr
    } elsif ($1 eq 'Picture') {
        'i:' . join '/', $cntnt->relpath # No need for portability
    } elsif ($1 eq 'Attachment') {
        'a:' . join '/', $cntnt->relpath # Ditto
    } else { die };
}

=back

=cut

1;
