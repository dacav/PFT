package PFT::Map::Resolver v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Map::Resolver - Configuration parser for PFT

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Exporter qw/import/;
our @EXPORT_OK = qw/resolve/;

use Carp;
use PFT::Header;

sub resolve {
    my($map, $node, $symbol) = @_;

    my $kwd = $symbol->keyword;
    if ($kwd =~ /^(pic|page|blog)$/n) {
        &local_resolve;
    } else {
        confess "Unrecognized keyword $kwd";
    }
}

sub local_resolve {
    my($map, $node, $symbol) = @_;

    my $kwd = $symbol->keyword;
    my $tree = $map->tree;
    my $content;
    if ($kwd eq 'pic') {
        $content = $tree->pic($symbol->args);
    } elsif ($kwd eq 'page') {
        $content = $tree->entry(
            PFT::Header->new(title => join(' ', $symbol->args))
        )
    } elsif ($kwd eq 'blog') {
        $content = &local_resolve_blog;
    } else {
        confess "Unrecognized keyword $kwd";
    }

    unless (defined $content and $content->exists) {
        confess 'Cannot find "', File::Spec->catfile($symbol->args),
            "\" (kind $kwd)"
    }
    $content;
}

sub local_resolve_blog {
    my($map, $node, $symbol) = @_;

    my @args = $symbol->args;
    my $method = shift @args;
    if ($method eq 'back') {
        my $steps = @args ? shift(@args) : 0;
        while ($steps > 0) {
            $node = $node->prev;
        }
        $node;
    } else {
        confess "Unrecognized blog lookup $method";
    }
}

1;
