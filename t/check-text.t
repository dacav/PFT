#!/usr/bin/perl -w

use v5.10;

use strict;
use warnings;
use utf8;

use Test::More; #tests => 1;

use File::Spec;
use File::Temp qw/tempdir/;

use PFT::Text;
use PFT::Content;
use PFT::Header;

#my $dir = tempdir(CLEANUP => 1);
#
#my $entry = PFT::Content->new(
#    $dir, { create => 1 }
#)->new_entry(
#    PFT::Header->new(title => 'test')
#);
#
#do {
#    open my $fd, '>>:encoding(UTF-8)', $entry->path or die $!;
#    print $fd <<"    END";
#    END
#    close $fd;
#};

use Text::MultiMarkdown 'markdown';
my $html = markdown(join '', <::DATA>);
close ::DATA;

#print "Found $1:$2 at start $start, len $len\n",
#      "   ", substr($text, $start - 10, $len + 10) =~ s/\n/\$/rgs, "\n",
#      "   ", ' ' x 10, '^', "\n";

foreach (PFT::Text::_locate_symbols($html)) {
    diag "Found ", $_->keyword, '(', join(', ', $_->args), ")\n";
    diag '   at start ', $_->start, ' len ', $_->len, "\n";
    diag "   ", substr($html, $_->start - 10, $_->len + 20) =~ s/\n/\$/rgs, "\n";
    diag "   ", '-' x 10, '^', '.' x ($_->len - 2), '^', "\n";
}

__END__
# Hello there.

This is some random markdown, which is the format used for PFT::Text. It
can contain some weird stuff, like [pft links][lnk], which are just
like [regular links](example.com) except they are [pft links](:truestory:).

Oh, there are also
<img src=":pics:best/kitten.png" alt="pictures"/>
![of any kind](:pics:best/horse.png)
![no, seriously!](:pics:best/goat.png "Oh, a goat!")

    But you can always [explain it on PFT](:like:this)

[lnk]: :foo:bar/baz

<a 
href=":x">
Multiline links should be supported
</a>

Images as well:
<img
src=":y:a/b/c"/>

And broken stuff, and nested also:
<a href=":w:b"><img src=":z:a">No slash in img!</a>
