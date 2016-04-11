package PFT::Content::Page v0.5.2;

=encoding utf8

=head1 NAME

PFT::Content::Page - A content page

=head1 SYNOPSIS

    use PFT::Content::Page;

    my $f1 = PFT::Content::Page->new({
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
