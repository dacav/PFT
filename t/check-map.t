#!/usr/bin/perl -w

use v5.10;

use strict;
use warnings;
use utf8;

use Test::More tests => 19;

use PFT::Content;
use PFT::Header;
use PFT::Map;

use File::Temp;

my $root = File::Temp->newdir();
my $tree = PFT::Content->new("$root");

# Populating

$tree->pic('baz', 'foo.png')->touch;
$tree->attachment('foo', 'bar.txt')->touch;
do {
    my $page = $tree->new_entry(PFT::Header->new(title => 'A page'));
    my $f = $page->open('a+');
    print $f <<'    EOF' =~ s/^    //rgms;
    Hello.

    This is a picture of me:

    ![my ugly face](:pic:baz/foo.png)
    ![my ugly cat](:pic:baz/bar.png)

    Follows my horrible poetry: [click here][1]

    [1]: :attach:foo/bar.txt
    EOF
    close $f;
};
$tree->new_entry(PFT::Header->new(
    title => 'Another page',
    tags => ['foo', 'bar'],
));
$tree->new_entry(PFT::Header->new(
    title => 'Blog post nr.3',
    date => PFT::Date->new(2014, 1, 3),
    tags => ['bar'],
));
for (1 .. 2) {
    $tree->new_entry(PFT::Header->new(
        title => 'Blog post nr.'.$_,
        date => PFT::Date->new(2014, $_, $_ * $_),
    ));
    $tree->new_entry(PFT::Header->new(title => 'Blog post nr.'.($_ + 10),
        date => PFT::Date->new(2014, $_, $_ * $_ + 1),
        tags => ['foo'],
    ));
}
$tree->new_entry(PFT::Header->new(title => 'Month nr.2',
    date => PFT::Date->new(2014, 2),
));
$tree->new_entry(PFT::Header->new(title => 'Month nr.3',
    date => PFT::Date->new(2014, 3),
    tags => ['bar'],
));
$tree->new_tag(PFT::Header->new(title => 'Bar'));

my $map = PFT::Map->new($tree);
diag('Follows list of nodes:');
diag($_->id, ' unres: ', join ', ', $_->unresolved) foreach $map->nodes;

my @dumped = $map->dump;

#use Data::Dumper;
#diag(Dumper \@dumped);

while (my($i, $node) = each @dumped) {
    exists $node->{'>'} and ok(($dumped[$node->{'>'}]->{'<'} == $i),
        'Next refers Prev for ' . $i
    );
    exists $node->{'<'} and ok(($dumped[$node->{'<'}]->{'>'} == $i),
        'Prev refers Next for ' . $i
    );
    if (defined(my $down = $node->{'v'})) {
        is(scalar(@$down), scalar(map{ $dumped[$_]->{'^'} == $i } @$down),
            'Down refers up for ' . $i
        );
    }
    if (defined(my $up = $node->{'^'})) {
        is(scalar(grep{ $_ == $i } @{$dumped[$up]->{'v'}}), 1,
            'Down refers up for ' . $i
        );
    }
    if (defined(my $down = $node->{'.'})) {
        is(scalar(@{$down}), scalar(grep {
                # The list of tags of the page indexed by $_ contains our
                # id exactly once.
                1 == grep { $_ == $i } @{$dumped[$_]->{t}}
            } @{$down}),
            'Taggee refers to tag ' . $i
        );
    }
}

done_testing();
