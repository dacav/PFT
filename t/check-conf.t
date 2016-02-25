#!/usr/bin/perl -w

use v5.10;

use strict;
use warnings;
use utf8;

use Test::More; #tests => 1;

use PFT::Conf;

use File::Spec;
use File::Temp qw/tempdir/;

my $conf = PFT::Conf->new_default;
my $dir = tempdir(CLEANUP => 1);
$conf->save_to("$dir");

use Data::Dumper;

is_deeply(PFT::Conf->new_load("$dir"), $conf);

done_testing()
