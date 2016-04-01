#!/usr/bin/perl -w

use v5.16;

use strict;
use warnings;
use utf8;

use Test::More; #tests => 1;

use PFT::Conf;

use File::Spec;
use File::Temp qw/tempdir/;

# Checks about the underneath opts-to-hash system

my %hashy = (
    site => {
        author => 'dachiav',
        encoding => 'utf8',
    },
    remote => {
        path => 'foo/bar',
    },
);
my @listy = (
    'site-author' => 'dachiav',
    'site-encoding' => 'utf8',
    'remote-path' => 'foo/bar',
);

is_deeply(
    PFT::Conf::_hashify(@listy),
    \%hashy,
    "Hashify works"
);

is(
    scalar eval{PFT::Conf::_hashify(
        'site-author' => 'self',
        'site-author-deep' => 1,
    )},
    undef,
    "Broken spec",
);
ok($@ =~ /\Wsite-author-deep\W/,
    "Error message is sound"
);

is(
    scalar eval{PFT::Conf::_hashify(
        'site-author-deep' => 1,
        'site-author' => 'self',
    )},
    undef,
    "Broken spec",
);
ok($@ =~ /\Wsite-author\W/,
    "Error message is sound"
);

do {
    my $conf = PFT::Conf->new_default;
    delete $conf->{site}{author};
    is(eval{$conf->_check_assign}, undef, "Missing check");
    ok($@ =~ /\Wsite-author\W/, "Error message is sound");
};

#my $dir = tempdir(CLEANUP => 1);
#is(PFT::Conf::locate($dir), undef);
#is(PFT::Conf::locate(), undef);
#
#my $conf = PFT::Conf->new_default;
#$conf->save_to($dir);
#isnt(PFT::Conf::locate($dir), undef);
#
#is_deeply(PFT::Conf->new_load($dir), $conf);
#
#mkdir File::Spec->catdir($dir, "foo") or die $!;
#mkdir my $subdir = File::Spec->catdir($dir, "foo", "bar") or die $!;
#is_deeply(PFT::Conf->new_load_locate($subdir), $conf);

done_testing()
