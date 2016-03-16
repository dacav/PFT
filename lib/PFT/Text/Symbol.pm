package PFT::Text::Symbol v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

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

Each instance represents a symbol from a PFT::Text instance. Symbols are
declared within the text. They are detected as links in HTML
matching C<E<lt>aE<gt>> and C<E<lt>imgE<gt>> tags.

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

Unicode notice: input HTML is assumed to be in decoded form.

=cut

sub keyword { shift->[0] }

sub args { @{shift->[1]} }

sub start { shift->[2] }

sub len { shift->[3] }

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
