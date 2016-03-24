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
    if ($kwd =~ /^(pic|page|blog|attach|tag)$/n) {
        &resolve_local
    } else {
        &resolve_remote
    }
}

sub resolve_local {
    my($map, $node, $symbol) = @_;

    my $kwd = $symbol->keyword;
    if ($kwd eq 'pic') {
        $map->node_of($map->tree->pic($symbol->args));
    } elsif ($kwd eq 'attach') {
        $map->node_of($map->tree->attachment($symbol->args));
    } elsif ($kwd eq 'page') {
        my $hdr = PFT::Header->new(title => join(' ', $symbol->args));
        $map->node_of($map->tree->entry($hdr), $hdr);
    } elsif ($kwd eq 'blog') {
        &resolve_local_blog;
    } elsif ($kwd eq 'tag') {
        my $hdr = PFT::Header->new(
            title => join(' ', $symbol->args),
            encoding => $node->header->encoding,
        );
        $map->node_of($map->tree->tag($hdr), $hdr);
    } else {
        confess "Unrecognized keyword $kwd";
    }
}

sub resolve_local_blog {
    my($map, $node, $symbol) = @_;

    my @args = $symbol->args;
    my $method = shift @args;
    if ($method eq 'back') {
        my $steps = @args ? shift(@args) : 1;
        $steps > 0 or confess "Going back $steps <= 0 from $node";
        while ($node && $steps-- > 0) {
            $node = $node->prev;
        }
        $node;
    } else {
        confess "Unrecognized blog lookup $method";
    }
}

sub resolve_remote {
    my($map, $node, $symbol) = @_;

    Carp::cluck $symbol;
    ...
}

1;
