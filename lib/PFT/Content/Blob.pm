package PFT::Content::Blob v0.5.2;

use v5.16;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Content::Blob - Binary file

=head1 SYNOPSIS

    use PFT::Content::Blob;

    my $p = PFT::Content::Blob->new({
        tree    => $tree,
        path    => $path,
        relpath => ['animals', 'cats', 'meow.png'], # decoded strings
    })

=head1 DESCRIPTION

C<PFT::Content::Blob> is the basetype for all binary-based content files.
It inherits from C<PFT::Content::File> and has two specific subtypes:
C<PFT::Content::Picture> and C<PFT::Content::Attachment>.

=cut

use parent 'PFT::Content::File';

use Carp;

sub new {
    my $cls = shift;
    my $params = shift;

    my $self = $cls->SUPER::new($params);
    my $relpath = $params->{relpath};
    confess 'Invalid relpath' unless ref $relpath eq 'ARRAY';
    $self->{relpath} = $relpath;
    $self;
}

=head2 Properties

=over

=item relpath

Relative path in form of a list.

A good use for it could be, concatenating it using File::Spec->catfile.

=cut

sub relpath {
    @{shift->{relpath}}
}

=back

=cut

1
