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

sub new {
    my $cls = shift;
    my $page = shift;

    bless {
        page => $page,
    }, $cls;
}

package PFT::Text::Symbol;

sub new {
    bless [
        $_[1],               # keyword
        [split /\//, $_[2]], # args list
        $_[3],               # start
        $_[4],               # len
    ], $_[0]
}
sub keyword { shift->[0] }
sub args { @{shift->[1]} }
sub start { shift->[2] }
sub len { shift->[3] }

package PFT::Text;

sub _locate_symbols {
    # NOTE: this is for internal use, yet not lexically scoped, as
    # required by unittest.

    my $pair = qr/":(\w+):([^"]+)"/;
    my $img = qr/<img\s+[^>]*src=\s*$pair([^>]*)>/;

    my $text = join '', @_;
    my @out;
    while ($text =~ /\W$img/sg) {
        my $len = length($1) + length($2) + 1;
        my $start = pos($text) - $len - length($3) - 2; # -2: for " and >

        push @out, PFT::Text::Symbol->new($1, $2, $start, $len)
    }

    @out;
}

=head2 Properties

=over 1

=item symbols

=cut

sub symbols {
    my $self = shift;
    my $text = do {
        my $fd = $self->{page}->read;
        local $/ = undef;
        <$fd>;
    };

}

=back

=cut

1;
