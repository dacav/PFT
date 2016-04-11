package PFT::Util v0.5.0;

=encoding utf8

=head1 NAME

PFT::Util - Utilities

=head1 DESCRIPTION

This module contains general utility functions.

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use File::Spec;
use Exporter;

use Encode;
use Encode::Locale;

our @EXPORT_OK = qw/
    list_files
/;

=over 1

=item files

List all files under the given directories.

    list_files 'foo' 'bar'

This is definitely off-scope, but some perl modules are really bad.
C<File::Find> is a utter crap! And I don't really want to add more
external deps for such a stupid thing.

Also, this handles encoding according to locale.

=cut

sub list_files {
    my @todo = @_;
    my @out;

    while (@todo) {
        my $dn = pop @todo;
        opendir my $d, encode(locale_fs => $dn) or die "Opening $dn: $!";
        my @content = map decode(locale_fs => $_) => readdir $d;
        foreach (File::Spec->no_upwards(@content)) {
            if (-d (my $dir = File::Spec->catdir($dn, $_))) {
                push @todo, $dir
            } else {
                push @out, File::Spec->catfile($dn, $_)
            }
        }
        closedir $d;
    }

    @out
}

=item locale_glob

A unicode-safe C<glob>.

Uses the encoding specified in locale.

This is different from C<CORE::glob> in that it accepts a list of glob
patterns

=cut

sub locale_glob {
    map decode(locale_fs => $_),
    map CORE::glob,
    map encode(locale_fs => $_),
    @_
}

=back

=cut

1
