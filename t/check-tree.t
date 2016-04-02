#!/usr/bin/perl -w

use v5.16;

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw/tempdir/;

use PFT::Tree;

my $dir = tempdir(CLEANUP => 1);

is(eval { PFT::Tree->new($dir) }, undef, 'Error unless created');
isnt($@, undef, 'Value set for $@ (follows)');
diag($@);

my $tree = eval { PFT::Tree->new($dir, {create => 1}) };
diag('Empty string should follow: ', $@ || '');
isnt($tree, undef, 'Ok with create');

done_testing()
