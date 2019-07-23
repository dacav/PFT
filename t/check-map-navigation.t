#!/usr/bin/perl -w

use v5.16;
use utf8;

use strict;
use warnings;
use utf8;

use Test::More;# tests => 8;

use PFT::Content;
use PFT::Header;
use PFT::Map;

use File::Spec;
use File::Temp;

use Encode::Locale;
use Encode;

my $root = File::Temp->newdir();
my $tree = PFT::Content->new($root, {create => 1});

diag 'Testing the simple navigation primitives of the PFT::Map class.';

diag 'An empty map must have no history.';
do {
    my $map = PFT::Map->new($tree);

    undef $@;
    my $undef = eval{ $map->blog_recent; 1 };
    ok(defined($@) && !defined($undef), 'Undef blog_recent blows');
    undef $@;
    $undef = eval{ $map->blog_recent(-1); 1 };
    ok(defined($@) && !defined($undef), 'Negative blog_recent blows');
    undef $@;
    $undef = eval{ $map->months_recent; 1 };
    ok(defined($@) && !defined($undef), 'Undef months_recent blows');
    undef $@;
    $undef = eval{ $map->months_recent(-1); 1 };
    ok(defined($@) && !defined($undef), 'Negative months_recent blows');


    ok(!$map->blog_exists, 'No blog exists in empty site');;
    is(($map->blog_recent(1))[0], undef, 'No recent blog in empty site');
    is(($map->months_recent(1))[0], undef, 'No recent months in empty site');
};

sub check_coherent {
    my($exp_blog, $exp_months) = @_;
    diag "There must be $exp_blog entries over $exp_months months";

    my $map = PFT::Map->new($tree);

    my @entries = $map->blog_recent($exp_blog);
    is(scalar @entries, $exp_blog, "Exactly $exp_blog entry");
    foreach (1 .. $exp_blog) {
        cmp_ok($map->blog_recent($_), 'eq', $entries[$_ - 1], " ...Coherent entry $_");
    }

    my @months = $map->months_recent($exp_months + 1);
    is(scalar @months, $exp_months, "Exactly $exp_months month");
    foreach (1 .. $exp_months) {
        cmp_ok($map->months_recent($_), 'eq', $months[$_ - 1], " ...Coherent month $_");
    }
}

diag 'Adding 2014/1/1';
$tree->new_entry(PFT::Header->new(
    title => 'Blog post nr.1',
    date => PFT::Date->new(2014, 1, 1),
    tags => ['bar'],
));
ok(PFT::Map->new($tree)->blog_exists, 'One entry, blog exists');
check_coherent(1, 1);

diag 'Adding 2014/1/2';
$tree->new_entry(PFT::Header->new(
    title => 'Blog post nr.1',
    date => PFT::Date->new(2014, 1, 2),
    tags => ['bar'],
));
check_coherent(2, 1);

diag 'Adding 2014/2/1';
$tree->new_entry(PFT::Header->new(
    title => 'Blog post nr.1',
    date => PFT::Date->new(2014, 2, 1),
    tags => ['bar'],
));
check_coherent(2, 2);

diag 'Adding 2014/2/2';
$tree->new_entry(PFT::Header->new(
    title => 'Blog post nr.1',
    date => PFT::Date->new(2014, 2, 2),
    tags => ['bar'],
));
check_coherent(3, 2);

done_testing();
