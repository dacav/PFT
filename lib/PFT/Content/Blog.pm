package PFT::Content::Blog v0.5.3;

=encoding utf8

=head1 NAME

PFT::Content::Blog - A text entry with date.

=head1 SYNOPSIS

    use PFT::Content::Blog;

    my $f1 = PFT::Content::Blog->new({
        tree => $tree,
        path => $path,
        name => $name,  # optional, defaults to basename($path)
    });

=head1 DESCRIPTION

Extends C<PFT::Content::Entry>.
Retains the same interface.

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use parent 'PFT::Content::Entry';

1
