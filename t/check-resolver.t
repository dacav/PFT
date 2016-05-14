#!/usr/bin/perl -w

use v5.16;

use strict;
use warnings;
use utf8;

use Test::More;# tests => 27;

use PFT::Tree;
use PFT::Content;
use PFT::Header;
use PFT::Map;
use PFT::Map::Resolver qw(resolve);

use File::Spec;
use File::Temp;

use Encode::Locale;
use Encode;

my $root = File::Temp->newdir;
my $tree = PFT::Tree->new($root, {create=>1})->content;

# Populating

do {
    my $page = $tree->new_entry(PFT::Header->new(title => 'A page¹'));
    my $f = $page->open('a');
    binmode $f, 'utf8';
    print $f <<'    EOF' =~ s/^    //rgms;
    This is a page, referring [the blog page](:blog:back)
    EOF
    close $f;
};
do {
    my $entry = $tree->new_entry(PFT::Header->new(
        title => 'Hello',
        date => PFT::Date->new(2014, 1, 3),
        tags => ['tag1'],
    ));
    my $f = $entry->open('a');

    print $f <<'    EOF' =~ s/^    //rgms;
    This is an entry where I refer to [some page][1]

    [1]: :page:a-page
    EOF
    close $f;
};
do {
    my $entry = $tree->new_entry(PFT::Header->new(
        title => 'Hello 2',
        date => PFT::Date->new(2014, 1, 4),
        tags => ['tag1'],
    ));
    my $f = $entry->open('a');

    print $f <<'    EOF' =~ s/^    //rgms;
    This is an entry where I refer to [previous one][1]

    [1]: :blog:back
    EOF
    close $f;
};

my $map = PFT::Map->new($tree);

ok_corresponds('p:a-page');
ok_corresponds('b:2014-01-03:hello', 'p:a-page');
ok_corresponds('b:2014-01-04:hello-2', 'b:2014-01-03:hello');

do {
    # Point is: a page cannot point to :blog:back, because there's no
    # relative number of steps back!
    my @unres = $map->id_to_node('p:a-page')->symbols_unres;
    is(scalar(@unres), 1,      'Broken link test');
    my($sym, $err) = @{$unres[0]};
    is($sym->keyword, 'blog',         '  key=blog');
    is_deeply([$sym->args], ['back'], '  args=[back]');
};

sub ok_corresponds {
    my $nodeid = shift;
    my @refs;

    my $node = $map->id_to_node($nodeid);

    # Returned html will contain "bogus href" as link to each node.
    $node->html(sub { push @refs, $_->id; "bogus href" });

    is_deeply(\@refs, \@_, 'Resolver for ' . $nodeid)
}

done_testing();
