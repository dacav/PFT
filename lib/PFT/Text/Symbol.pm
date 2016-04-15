package PFT::Text::Symbol v0.5.3;

=pod

=encoding utf8

=head1 NAME

PFT::Text::Symbol - Symbol from text scan

=head1 SYNOPSIS

    my $array = PFT::Text::Symbol->scan_html($your_html_text);
    foreach (PFT::Text::Symbol->scan_html($your_html_text)) {
        die unless $_->isa('PFT::Text::Symbol')
    };

=head1 DESCRIPTION

Each instance of C<PFT::Text::Symbol> represents a symbol obtained by
parsing the text of an entry C<PFT::Content::Entry>: they are detected as
C<E<lt>aE<gt>> and C<E<lt>imgE<gt>> tags in HTML.  Symbols are collected
into a a C<PFT::Text> object.

An example will make this easy to understand. Let's consider the following
tag:

    <img src=":key1:a1/b1/c1">

It will generate a symbol C<$s1> such that:

=over 1

=item C<$s1-E<gt>keyword> is C<key1>;

=item C<$s1-E<gt>args> is the list C<(a1, b1, c1)>;

=item C<$s1-E<gt>start> points to the first C<:> character;

=item C<$s1-E<gt>len> points to the last C<1> character;

=back

Since a block of HTML can possibly yield multiple symbols, there's no
public construction. Use the C<scan_html> multi-constructor instead.

=head2 Construction

There's no single object constructor. Construction goes through
C<PFT::Text::Symbol-E<gt>scan_html>, which expects an HTML string as
parameter and returns a list of blessed symbols.

=cut

sub scan_html {
    my $cls = shift;

    my $pair = qr/":(\w+):([^"]*)"/;
    my $img = qr/<img\s*[^>]*src=\s*$pair([^>]*)>/;
    my $ahr = qr/<a\s*[^>]*href=\s*$pair([^>]*)>/;

    my $text = join '', @_;
    my @out;
    for my $reg ($img, $ahr) {
        while ($text =~ /\W$reg/smg) {
            my $len = length($1) + length($2) + 2; # +2 for ::
            my $start = pos($text) - $len - length($3) - 2; # -2 for ">

            push @out, bless([
                $1,                 # keyword
                [split /\//, $2],   # args list
                $start,
                $len,
            ], $cls);
        }
    }

    sort { $a->start <=> $b->start } @out;
}

use utf8;
use v5.16;
use strict;
use warnings;

=head2 Properties

=over

=item keyword

=cut

sub keyword { shift->[0] }

=item args

=cut

sub args { @{shift->[1]} }

=item start

=cut

sub start { shift->[2] }

=item len

=cut

sub len { shift->[3] }

=back

=cut

use overload
    '""' => sub {
        my $self = shift;
        sprintf 'PFT::Text::Symbol[key:"%s", args:["%s"], start:%d, len:%d]',
            $self->[0],
            join('", "', @{$self->[1]}),
            @{$self}[2, 3],
    },
;

1;
