#!/usr/bin/perl -w

use v5.10;

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
        encoding => 'utf-8',
    ));
    is_deeply($tree->path_to_date($p->path), $date, 'Path-to-date')
};
do {
    my $p = $tree->new_entry(PFT::Header->new(
        title => 'foo-bar-☺az',
        encoding => 'utf-8',
    ));
    is($tree->path_to_date($p->path), undef, 'Path-to-date, no date')
};

do {
    my $p = $tree->new_entry(PFT::Header->new(
        title => 'foo-öar-baz',
        encoding => 'utf-8',
    ));
    is($tree->path_to_slug($p->path), 'foo-öar-baz', 'Path-to-slug 1')
};
do {
    my $p = $tree->new_entry(PFT::Header->new(
        title => 'foo²bar☺baz',
        date => PFT::Date->new(0, 12, 25),
        encoding => 'utf-8',
    ));
    is($tree->path_to_slug($p->path), 'foo-bar-baz', 'Path-to-slug 2')
};

# Testing make_consistent function
do {
    my $hdr = PFT::Header->new(
        title => 'one',
        date => PFT::Date->new(10, 11, 12),
        encoding => 'utf-8',
    );

    my $e = $tree->new_entry($hdr);
    $e->set_header(PFT::Header->new(
        title => 'two',
        date => PFT::Date->new(10, 12, 14),
        encoding => 'utf-8',
    ));

    ok($e->path =~ /0010-11.*12-one/, 'Original path');
    my $orig_path = $e->path;
    $e->make_consistent;
    ok($e->path !~ /0010-11.*12-one/, 'Not original path');
    ok(!-e $orig_path && -e $e->path, 'Actually moved');
    ok($e->path =~ /0010-12.*14-two/, 'New path');
};

done_testing()
