package PFT::Tree v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Tree - Filesystem tree mapping a PFT site

=head1 SYNOPSIS

    PFT::Tree->new($basedir);

=head1 DESCRIPTION

=cut

use File::Spec;
use File::Path qw/make_path/;
use Carp;
use Cwd;

use PFT::Content;
use PFT::Conf;

sub new {
    my $cls = shift;

    my $root = PFT::Conf::locate(shift) or Cwd::abs_path(Cwd::getcwd);
    my $self = bless { root => $root }, $cls;
    $self->_init();

    $self
}

sub _init {
    my $self = shift;
    make_path map({ $self->$_ } qw/
        dir_content
        dir_templates
        dir_inject
    /), {
        #verbose => 1,
        mode => 0711,
    }
}

=head2 Properties

=over 1

=item dir_content

=cut

sub dir_content { File::Spec->catdir(shift->{root}, 'content') }
sub dir_templates { File::Spec->catdir(shift->{root}, 'templates') }
sub dir_inject { File::Spec->catdir(shift->{root}, 'inject') }

=item content

Returns a PFT::Content object.

=cut

sub content { PFT::Content->new(shift->dir_content) }

=item conf

Returns a PFT::Conf object

=cut

sub conf {
    my $root = shift->{root};
    if (PFT::Conf::isroot($root)) {
        PFT::Conf->new_load($root)
    } else {
        my $conf = PFT::Conf->new_default_env;
        $conf->save_to($root);
        $conf;
    }
}

=back

=cut

1;
