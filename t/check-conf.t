#!/usr/bin/perl -w

use v5.10;

use strict;
use warnings;
use utf8;

use Test::More; #tests => 1;

use PFT::Conf;

use File::Spec;
use File::Temp qw/tempdir/;

my $dir = tempdir(CLEANUP => 1);
is(PFT::Conf::locate($dir), undef);
is(PFT::Conf::locate(), undef);

my $conf = PFT::Conf->new_default;
$conf->save_to($dir);
isnt(PFT::Conf::locate($dir), undef);

is_deeply(PFT::Conf->new_load($dir), $conf);

mkdir File::Spec->catdir($dir, "foo") or die $!;
mkdir my $subdir = File::Spec->catdir($dir, "foo", "bar") or die $!;
is_deeply(PFT::Conf->new_load_locate($subdir), $conf);

done_testing()
