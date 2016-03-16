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
    PFT::Conf->new_default_env()    # Using sensible defaults
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
use File::Spec::Functions qw/updir catfile catdir rootdir/;
use File::Path qw/make_path/;
use File::Basename qw/dirname/;
use YAML::Tiny qw/DumpFile LoadFile/;

my $CONF_NAME = 'pft.yaml';

sub new_default {
    bless {
        author => 'John Doe',
        template => 'default',
        site_title => "My PFT website",
        site_url => 'http://example.org/',
        home_page => 'Welcome',
        remote => {
            method => 'rsync+ssh',
            host => 'example.org',
            port => undef,
            user => 'user',
            path => '/home/user/public-html/whatever',
        },
        system => {
            browser => undef,
            editor => undef,
        },
        input_enc => 'utf-8',
        output_enc => 'utf-8',

        _root => undef,
    }, shift;
}

sub new_default_env {
    my $self = shift->new_default;

    $self->{author} = $ENV{USER};
    @{$self->{system}}{'browser', 'editor'} = @ENV{'BROWSER', 'EDITOR'};

    $self
}

my $check_assign = sub {
    my $cfg = shift;

    my @out;
    for my $spec (@_) {
        my $val = $cfg;
        my $optional = $spec =~ /\?$/;
        foreach (split /\./, $optional ? substr($spec, 0, -1) : $spec) {
            last unless defined($val = $val->{$_});
        }
        croak "Configuration $spec is missing"
            unless defined($val) || $optional;
        push @out, $val;
    }

    @out;
};

sub new_load {
    my $cls = shift;

    my $root = shift;
    my $conf_file = isroot($root)
        or croak "$root is not a PFT site: $CONF_NAME is missing";

    my $cfg = LoadFile($conf_file);
    my $self;

    (
        @{$self}{qw/
            author
            template
            site_title
            site_url
            home_page
            input_enc
            output_enc
        /},
        @{$self->{remote}}{qw/
            method
            host
            user
            port
            path
        /},
        @{$self->{system}}{qw/
            editor
            browser
        /},
    ) = $check_assign->($cfg, qw/
        Author
        Template
        SiteTitle
        SiteURL
        HomePage
        InputEnc
        OutputEnc
        Remote.Method
        Remote.Host?
        Remote.User?
        Remote.Port?
        Remote.Path?
        System.Editor?
        System.Browser?
    /);
    $self->{_root} = $root;

    bless $self, $cls;
}

sub isroot {
    my $f = catfile(shift, $CONF_NAME);
    -e $f ? $f : undef
}

sub locate {
    my $cur = shift || Cwd::getcwd;
    my $root;

    croak "Not a directory: $cur" unless -d $cur;
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
    my $self = shift;
    my $root = shift;

    make_path(dirname $root);

    DumpFile(catfile($root, $CONF_NAME), {
        Author => $self->{author},
        Template => $self->{template},
        SiteTitle => $self->{site_title},
        SiteURL => $self->{site_url},
        HomePage => $self->{home_page},
        Remote => { do {
                my $d = $self->{remote};

                Method => $d->{method},
                Host => $d->{host},
                User => $d->{user},
                Port => $d->{port},
                Path => $d->{path},
        }},
        System => { do {
                my $d = $self->{system};

                Editor => $d->{editor},
                Browser => $d->{browser},
        }},
        InputEnc => $self->{input_enc},
        OutputEnc => $self->{output_enc},
    });
    $self->{_root} = $root;
}

=back

=cut

use overload
    '""' => sub { 'PFT::Conf[ ' . (shift->{_root} || '?') . ' ]' },
;

1;
