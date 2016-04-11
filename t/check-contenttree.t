#!/usr/bin/perl -w

use v5.16;

use strict;
use warnings;
use utf8;

use PFT::Content;
use PFT::Header;
use PFT::Date;

use File::Temp qw/tempdir/;
use File::Spec;

use Encode;
use Encode::Locale;

use Test::More;

my $dir = tempdir(CLEANUP => 1);
my $inner_unicode = File::Spec->catfile($dir, 'öéåñ');
mkdir encode(locale => $inner_unicode);
my $tree = PFT::Content->new($inner_unicode);

do {
    my $date = PFT::Date->new(0, 12, 25);
    my $p = $tree->new_entry(PFT::Header->new(
        title => 'foo-♥-baz',
        date => $date,
    ));
    is_deeply($tree->path_to_date($p), $date, 'Path-to-date')
};
do {
    my $p = $tree->new_entry(PFT::Header->new(
        title => 'foo-bar-☺az',
    ));
    is($tree->path_to_date($p), undef, 'Path-to-date, no date')
};

do {
    my $p = $tree->new_entry(PFT::Header->new(
        title => 'foo-öar-baz',
    ));
    is($tree->path_to_slug($p->path), 'foo-öar-baz', 'Path-to-slug 1')
};
do {
    my $p = $tree->new_entry(PFT::Header->new(
        title => 'foo²bar☺baz',
        date => PFT::Date->new(0, 12, 25),
    ));
    is($tree->path_to_slug($p->path), 'foo-bar-baz', 'Path-to-slug 2')
};

# Testing make_consistent function
do {
    my $hdr = PFT::Header->new(
        title => 'one',
        date => PFT::Date->new(10, 11, 12),
    );

    my $e = $tree->new_entry($hdr);
    $e->set_header(PFT::Header->new(
        title => 'two',
        date => PFT::Date->new(10, 12, 14),
    ));

    ok($e->path =~ /0010-11.*12-one/, 'Original path');
    my $orig_path = $e->path;
    $e->make_consistent;
    ok($e->path !~ /0010-11.*12-one/, 'Not original path');
    ok(!-e $orig_path && -e $e->path, 'Actually moved');
    ok($e->path =~ /0010-12.*14-two/, 'New path');
};

done_testing()
