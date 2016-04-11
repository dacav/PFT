package PFT::Map::Resolver v0.5.1;

=encoding utf8

=head1 NAME

PFT::Map::Resolver - Resolve symbols in PFT Entries

=head1 SYNOPSIS

    use PFT::Map::Resolver 'resolve';

    die unless $map->isa('PFT::Map');
    die unless $node->isa('PFT::Map::Node');
    die unless $sym->isa('PFT::Text::Symbol');

    my $result = resolve($map, $node, $sym);

=head1 DESCRIPTION

This module only exports one function, named C<resolve>.

The function resolves a symbol retrieved from the text of a
C<PFT::Map::Node>. The returned value will be one of the following:

=over

=item A node (i.e. a C<PFT::Map::Node> instance);

=item A string (e.g. C<http://manpages.org>);

=item The C<undef> value (meaning: failed resolution).

=back

=cut

use v5.16;
use strict;
use warnings;
use utf8;

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
        my $hdr = PFT::Header->new(
            title => join(' ', $symbol->args),
        );
        $map->node_of($map->tree->entry($hdr), $hdr);
    } elsif ($kwd eq 'blog') {
        &resolve_local_blog;
    } elsif ($kwd eq 'tag') {
        my $hdr = PFT::Header->new(
            title => join(' ', $symbol->args),
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

    my $out;
    my $kwd = $symbol->keyword;
    if ($kwd eq 'web') {
        my @args = $symbol->args;
        if ((my $service = shift @args) eq 'ddg') {
            $out = 'https://duckduckgo.com/?q=';
            if ((my $bang = shift @args)) { $out .= "%21$bang%20" }
            $out .= join '%20', @args
        }
        elsif ($service eq 'man') {
            $out = join '/', 'http://manpages.org', @args
        }
    }

    unless (defined $out) {
        confess 'Never implemented magic link "', $symbol->keyword, "\"\n";
    }
    $out
}

1;
