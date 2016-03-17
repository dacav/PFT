package PFT::Content::Blob v0.0.1;

use v5.10;

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
        tree => $tree,
        path => $path,
    })

=head1 DESCRIPTION

=cut

use parent 'PFT::Content::File';

1
