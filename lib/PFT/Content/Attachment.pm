package PFT::Content::Attachment v0.5.2;

=encoding utf8

=head1 NAME

PFT::Content::Attachment - Binary attachment

=head1 SYNOPSIS

    use PFT::Content::Attachment;

    my $f1 = PFT::Content::Attachment->new({
        tree => $tree,
        path => $path,
        name => $name,  # optional, defaults to basename($path)
    });

=head1 DESCRIPTION

Extends C<PFT::Content::Blob>.
Retains the same interface.

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use parent 'PFT::Content::Blob';

1
