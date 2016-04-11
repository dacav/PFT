package PFT::Content::Tag v0.5.1;

=encoding utf8

=head1 NAME

PFT::Content::Tag - Tag content page describing a Tag

=head1 SYNOPSIS

    use PFT::Content::Tag;

    my $f1 = PFT::Content::Tag->new({
        tree => $tree,
        path => $path,
        name => $name,  # optional, defaults to basename($path)
    });

=head1 DESCRIPTION

Extends C<PFT::Content::Page>.
Retains the same interface.

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use parent 'PFT::Content::Page';

1
