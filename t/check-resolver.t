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

# --- Populating  ------------------------------------------------------

sub enter {
    my $f = $tree->new_entry(shift)->open('a');
    print $f @_;
    close $f;
};

enter(
    PFT::Header->new(title => 'A page¹'),
    <<'    EOF' =~ s/^    //rgms
    This is a page, referring [the blog page](:blog:back) will fail.
    I can however refer to [this page](:page:a-page).

    There's one picture:
    ![test](:pic:foo/bar.png)
    EOF
);

$tree->pic('foo', 'bar.png')->open('a');

enter(
    PFT::Header->new(
        title => 'Hello 1',
        date => PFT::Date->new(2014, 1, 3),
        tags => ['tag1'],
    ),
    <<'    EOF' =~ s/^    //rgms
    This is an entry where I refer to [some page][1]

    [1]: :page:a-page
    EOF
);
enter(
    PFT::Header->new(
        title => 'Hello 2',
        date => PFT::Date->new(2014, 1, 4),
        tags => ['tag1'],
    ),
    <<'    EOF' =~ s/^    //rgms
    This is another entry where I refer to [previous one][1]

    [1]: :blog:back
    EOF
);
enter(
    PFT::Header->new(
        title => 'Hello 3',
        date => PFT::Date->new(2014, 1, 5),
        tags => ['tag1'],
    ),
    <<'    EOF' =~ s/^    //rgms
    This is another entry where I refer to [previous one][1]
    And to the [first](:blog:back/2)

    [1]: :blog:back
    EOF
);

# --/ Populating  ------------------------------------------------------

my $map = PFT::Map->new($tree);

ok_corresponds('p:a-page',
    'p:a-page',
    'i:foo/bar.png',
);

ok_corresponds('b:2014-01-03:hello-1',
    'p:a-page',
);

ok_corresponds('b:2014-01-04:hello-2',
    'b:2014-01-03:hello-1',
);

ok_corresponds('b:2014-01-05:hello-3',
    'b:2014-01-04:hello-2',
    'b:2014-01-03:hello-1',
);

do {
    # Point is: a page cannot point to :blog:back, because there's no
    # relative number of steps back!
    my @unres = $map->id_to_node('p:a-page')->symbols_unres;
    diag('Listing links in p:a-page:');
    diag(' - ', join(' ', grep defined, @$_)) for @unres;
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
