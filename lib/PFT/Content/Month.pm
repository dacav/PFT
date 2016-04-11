package PFT::Content::Month v0.5.2;

=encoding utf8

=head1 NAME

PFT::Content::Month - A monthly blog page

=head1 SYNOPSIS

    use PFT::Content::Month;

    my $f1 = PFT::Content::Month->new({
        tree => $tree,
        path => $path,
        name => $name,  # optional, defaults to basename($path)
    });

=head1 DESCRIPTION

Extends C<PFT::Content::Blog>.
Retains the same interface.

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use parent 'PFT::Content::Blog';

1
