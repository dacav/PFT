package PFT::Content::Base v0.5.0;

=encoding utf8

=head1 NAME

PFT::Content::Base - Base class for content

=head1 SYNOPSIS

    use parent 'PFT::Content::Base'

    sub new {
        my $cls = shift;
        ...
        $cls->SUPER::new({
            tree => $tree,
            name => $name,
        })
        ...
    }

=head1 DESCRIPTION

This class is a common base for for all C<PFT::Content::*> classes.

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use Carp;

sub new {
    my $cls = shift;
    my $params = shift;

    exists $params->{$_} or confess "Missing param: $_"
        for qw/tree name/;

    bless {
        tree => $params->{tree},
        name => $params->{name},
    }, $cls
}

=head2 Properties

=over

=item tree

Path object

=item name

Name of the object

=cut

sub tree { shift->{tree} }

sub name { shift->{name} }

use overload
    '""' => sub {
        my $self = shift;
        ref($self) . '({name => "' . $self->{name} . '"})'
    },
;

=back

=cut

1;
