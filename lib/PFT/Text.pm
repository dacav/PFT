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

    PFT::Text->new($filehandler);

=head1 DESCRIPTION

Semantic wrapper around content text. Knows how the text should be parsed,
abstracts away inner data retrieval.

The constructor expects a C<Content::Page> object as parameter.

=cut

use PFT::Text::Symbol;
use Text::Markdown qw/markdown/;

sub new {
    my $cls = shift;
    my $page = shift;

    bless {
        page => $page,
    }, $cls;
}

=head2 Properties

=over 1

=item html

=cut

sub html {
    my $self = shift;
    return $self->{html} if exists $self->{html};
    $self->{html} = markdown do {
        my $fd = $self->{page}->read;
        local $/ = undef;
        <$fd>;
    }
}

=item symbols

=cut

sub symbols {
    my $self = shift;
    PFT::Text::Symbol->scan_html($self->html);
}

=back

=cut

1;
