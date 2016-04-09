Module guidelines
=================

This document contains guidelines for writing new modules under the PFT
package.

Perl directives
---------------

 1. Name the module

        package PFT::Something v1.2.3;

 2. Documentation

        =encoding utf8

        =head1 NAME

        Something - Do it in PFT

        =head1 SYNOPSIS

            my $something = PFT::Something->new

        =head1 DESCRIPTION

        This is how you do something in PFT.

        =cut

 3. Take advantage of the powerful Unicode support in Perl:

        use utf8;
        use v5.16;
        use strict;
        use warnings;

 4. Import modules, define constants

        use Encode;
        use Encode::Locale;
        use Carp;
        ...
        use Whatever::You::Need;

        use constant { ... };
        my $internal_cb = sub { ... };

 5. Constructor. The constructor is typically already documented in the
    _SYNOPSIS_ section.

        sub new { ... bless }

 6. Start a `=head2` with documentation section

        =head2 Properties

        =over

 7. Define all properties after their documentation.
 
        =item foo

        Does some foo

        =cut

        sub foo { ... }

 8. Hidden functions (to be used internally) can have an underscore (`_`)
    prefix or be lexically local. If they need documentation, use plain
    comments.

        my $bar = sub { ... }

        sub _baz { ... }

 9. End by closing PODs

        =back

        =cut

10. As usual, close successfully

        1
