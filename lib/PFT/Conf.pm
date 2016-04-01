package PFT::Conf v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Conf - Configuration parser for PFT

=head1 SYNOPSIS

    PFT::Conf->new_default()        # Using default
    PFT::Conf->new_load($root)      # Load from conf file in directory
    PFT::Conf->new_load_locate()    # Load from conf file, find directory
    PFT::Conf->new_load_locate($cwd)

    PFT::Conf::locate()             # Locate root
    PFT::Conf::locate($cwd)

    PFT::Conf::isroot($path)        # Check if location exists under path.

=head1 DESCRIPTION

=cut

use Carp;
use Cwd;
use Encode;
use Encode::Locale;

use File::Spec::Functions qw/updir catfile catdir rootdir/;
use File::Path qw/make_path/;
use File::Basename qw/dirname/;

use YAML::Tiny;

our $CONF_NAME = 'pft.yaml';
my($IDX_MANDATORY, $IDX_GETOPT_SUFFIX, $IDX_DEFAULT) = 0 .. 2;

my $user = $ENV{USER} || 'anon';
my %CONF_RECIPE = (
    'site-author'     => [1, '=s', $ENV{USER} || 'Anonymous'],
    'site-template'   => [1, '=s', 'default'],
    'site-title'      => [1, '=s', 'My PFT website'],
    'site-url'        => [0, '=s', 'http://example.org'],
    'site-home'       => [1, '=s', 'Welcome'],
    'site-encoding'   => [1, '=s', $Encode::Locale::ENCODING_LOCALE],
    'remote-method'   => [1, '=s', 'rsync+ssh'],
    'remote-host'     => [0, '=s', 'example.org'],
    'remote-user'     => [0, '=s', $user],
    'remote-port'     => [0, '=i', 22],
    'remote-path'     => [0, '=s', $user],
    'system-editor'   => [0, '=s', $ENV{EDITOR} || 'vim'],
    'system-browser'  => [0, '=s', $ENV{BROWSER} || 'firefox'],
    'system-encoding' => [0, '=s', $Encode::Locale::ENCODING_LOCALE],
);

# Transforms a flat mapping as $CONF_RECIPE into 'deep' hash table
sub _hashify {
    my %out;

    @_ % 2 and die "Odd number of args";
    for (my $i = 0; $i < @_; $i += 2) {
        my @keys = split /-/, $_[$i];
        die "Key is empty? \"$_[$i]\"" unless @keys;
        my $dst = \%out;
        while (@keys > 1) {
            my $k = shift @keys;
            $dst = exists $dst->{$k}
                ? $dst->{$k}
                : do { $dst->{$k} = {} };
            ref $dst ne 'HASH' and croak "Not pointing to hash: $_[$i]";
        }
        my $k = shift @keys;
        exists $dst->{$k} and croak "Overwriting $_[$i]";
        $dst->{$k} = $_[$i + 1];
    }

    \%out;
}

sub _read_recipe {
    my $select = shift;
    my @out;
    if (my $filter = shift) {
        while (my($k, $vs) = each %CONF_RECIPE) {
            my $v = $vs->[$select] or next;
            push @out, $k => $vs->[$select];
        }
    } else {
        while (my($k, $vs) = each %CONF_RECIPE) {
            push @out, $k => $vs->[$select];
        }
    }
    @out;
}

sub new_default {
    my $self = _hashify(_read_recipe($IDX_DEFAULT));
    $self->{_root} = undef;
    bless $self, shift;
}

sub _check_assign {
    my $self = shift;
    local $" = '-';
    my $i;

    for my $mandk (grep { ++$i % 2 } _read_recipe($IDX_MANDATORY, 1)) {
        my @keys = split /-/, $mandk;
        my @path;

        my $c = $self;
        while (@keys > 1) {
            push @path, (my $k = shift @keys);
            confess "Missing section \"@path\"" unless $c->{$k};
            $c = $c->{$k};
            confess "Seeking \"@keys\" in \"@path\""
                unless ref $c eq 'HASH';
        }
        push @path, shift @keys;
        confess "Missing @path" unless exists $c->{$path[-1]};
    }
}

sub new_load {
    my($cls, $root) = @_;

    my $self = do {
        my $enc_fname = isroot($root)
            or croak "$root is not a PFT site: $CONF_NAME is missing";
        open(my $f, '<:encoding(locale)', $enc_fname)
            or croak "Cannot open $CONF_NAME in $root $!";
        $/ = undef;
        my $yaml = <$f>;
        close $f;

        YAML::Tiny::Load($yaml);
    };
    _check_assign($self);

    $self->{_root} = $root;
    bless $self, $cls;
}

sub isroot {
    my $f = encode(locale_fs => catfile(shift, $CONF_NAME));
    -e $f ? $f : undef
}

sub locate {
    my $cur = shift || Cwd::getcwd;
    my $root;

    croak "Not a directory: $cur" unless -d encode(locale_fs => $cur);
    until ($cur eq rootdir or defined($root)) {
        if (isroot($cur)) {
            $root = $cur
        } else {
            $cur = Cwd::abs_path catdir($cur, updir)
        }
    }
    $root;
}

sub new_load_locate {
    my $cls = shift;
    my $root = locate(my $start = shift);
    croak "Not a PFT site (or any parent up to $start)"
        unless defined $root;

    $cls->new_load($root);
}

=head2 Methods

=over 1

=item save_to

Save the configuration to a file. This will also update the inner root
reference, so the intsance will point to the saved file.

=cut

sub save_to {
    my($self, $root) = @_;

    my $orig_root = delete $self->{_root};

    # YAML::Tiny does not like blessed items. I could unbless with
    # Data::Structure::Util, or easily do a shallow copy
    my $yaml = YAML::Tiny::Dump {%$self};

    eval {
        my $enc_root = encode(locale_fs => $root);
        -e $enc_root or make_path $enc_root
            or die "Cannot mkdir $root: $!";
        open(my $out,
            '>:encoding(locale)',
            encode(locale_fs => catfile($root, $CONF_NAME)),
        ) or die "Cannot open $CONF_NAME in $root: $!";
        print $out $yaml;
        close $out;

        $self->{_root} = $root;
    };
    $@ and do {
        $self->{_root} = $orig_root;
        croak $@ =~ s/ at.*$//sr;
    }
}

=back

=cut

use overload
    '""' => sub { 'PFT::Conf[ ' . (shift->{_root} || '?') . ' ]' },
;

1;
