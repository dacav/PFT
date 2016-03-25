package PFT::Text v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Text - Wrapper around content text

=head1 SYNOPSIS

    PFT::Text->new($page);

=head1 DESCRIPTION

Semantic wrapper around content text. Knows how the text should be parsed,
abstracts away inner data retrieval.

The constructor expects a C<Content::Page> object as parameter.

=cut

use PFT::Text::Symbol;
use Text::Markdown qw/markdown/;
use Carp;

sub new {
    my $cls = shift;
    my $page = shift;

    confess 'Expecting PFT::Content::Entry'
        unless $page->isa('PFT::Content::Entry');

    bless {
        page => $page,
    }, $cls;
}

=head2 Properties

=over 1

=item html

Returns the content in HTML form.

The conetnet will retain symbol placeholders. See the C<html_resolved> method.

=cut

sub html {
    my $self = shift;
    my $md = do {
        my $page = $self->{page};
        confess "$page is virtual" unless $page->exists;
        my $fd = $page->read;
        local $/ = undef;
        <$fd>;
    };
    defined $md ? markdown($md) : ''
}

=item symbols

=cut

sub symbols {
    my $self = shift;
    PFT::Text::Symbol->scan_html($self->html);
}

=item html_resolved

Given an ordered list of HTML representation of symbols, returns the
complete HTML with symbol placeholders replaced.

The strings must be ordered consistently with a previoulsy retrieved list
of symbols (wretrieved with the C<symbols> method.

Something like:

    $text->html_resolved(map resolve($_), $text->symbols)

=cut

sub html_resolved {
    my $self = shift;

    my $html = $self->html;
    my $offset = 0;
    for my $sym ($self->symbols) {
        if (my $repl = shift) {
            substr($html, $offset + $sym->start, $sym->len) = $repl;
            $offset += length($repl) - $sym->len
        }
    }
    $html;
}

=back

=cut

1;
