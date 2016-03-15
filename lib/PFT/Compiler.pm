package PFT::Compiler;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Compiler - Compile a site

=head1 SYNOPSIS

    my $tree = PFT::Tree->new(...);
    PFT::Compiler::build($tree);

=head1 DESCRIPTION

=cut

use Exporter 'import';
our @EXPORT_OK = qw/build/;

use Carp;
use File::Spec;

use PFT::Map;
use PFT::Text;

use feature 'say';

sub node_to_path {
    my $node = shift;
    my $hdr = $node->header;
    if ((my $k = $node->kind) eq 'b') {(
        'blog',
        sprintf('%04d-%02d', $hdr->date->y, $hdr->date->m),
        sprintf('%02d-%s.html', $hdr->date->d, $hdr->slug),
    )} elsif ($k eq 'm') {(
        'blog',
        sprintf('%04d-%02d.html', $hdr->date->y, $hdr->date->m),
    )} elsif ($k eq 'p') {(
        'pages',
        $hdr->slug . '.html',
    )} elsif ($k eq 't') {
        'tags',
        $hdr->slug . '.html',
    } else { die $k };
}

sub build {
    my $tree = shift;

    my $dir_build = $tree->dir_build;
    my $map = PFT::Map->new($tree->content);
    for my $node ($map->nodes) {
        my $path = File::Spec->catfile($dir_build, node_to_path $node);

    }
}

1;
