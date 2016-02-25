package PFT::Conf;

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

=head1 DESCRIPTION

=cut

use Carp;

use File::Spec;
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
    my $cfg = LoadFile(File::Spec->catfile($root, $CONF_NAME));
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

sub save_to {
    my $self = shift;
    my $root = shift;

    make_path(dirname $root);

    DumpFile(File::Spec->catfile($root, $CONF_NAME), {
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

1;
