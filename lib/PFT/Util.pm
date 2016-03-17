package PFT::Util v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Util - Utilities

=head1 DESCRIPTION

This module contains general utility functions.

=cut

use File::Spec;
use Exporter;

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

=cut

sub list_files {
    my @todo = @_;
    my @out;

    while (@todo) {
        my $dn = pop @todo;
        opendir my $d, $dn or die "Opening $dn: $!";
        foreach (File::Spec->no_upwards(readdir $d)) {
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

=back

=cut

1
