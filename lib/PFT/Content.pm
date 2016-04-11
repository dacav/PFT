package PFT::Content v0.0.1;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Content - Filesytem tree mapping content

=head1 SYNOPSIS

    PFT::Content->new($basedir);
    PFT::Content->new($basedir, {create => 1});

=head1 DESCRIPTION

The structure is the following:

    content
    ├── attachments
    ├── blog
    ├── pages
    ├── pics
    └── tags

=cut

use File::Spec;
use File::Path qw/make_path/;
use File::Basename qw/dirname basename/;

use Carp;

use Encode::Locale;
use Encode;

use PFT::Content::Page;
use PFT::Content::Blog;
use PFT::Content::Picture;
use PFT::Content::Attachment;
use PFT::Content::Tag;
use PFT::Content::Month;

use PFT::Date;
use PFT::Header;
use PFT::Util;

use constant {
    path_sep => File::Spec->catfile('',''),  # portable '/'
};

sub new {
    my $cls = shift;
    my $base = shift;
    my $opts = shift;

    my $self = bless { base => $base }, $cls;
    $opts->{create} and $self->_create();
    $self;
}

sub _create {
    my $self = shift;
    make_path(map $self->$_ => qw/
        dir_blog
        dir_pages
        dir_tags
        dir_pics
        dir_attachments
    /), {
        #verbose => 1,
        mode => 0711,
    }
}

=pod

=head2 Properties

Quick accessors for directories

    $tree->dir_root
    $tree->dir_blog
    $tree->dir_pages
    $tree->dir_tags
    $tree->dir_pics
    $tree->dir_attachments

Non-existing directories are created by the constructor.

=cut

sub dir_root { shift->{base} }
sub dir_blog { File::Spec->catdir(shift->{base}, 'blog') }
sub dir_pages { File::Spec->catdir(shift->{base}, 'pages') }
sub dir_tags { File::Spec->catdir(shift->{base}, 'tags') }
sub dir_pics { File::Spec->catdir(shift->{base}, 'pics') }
sub dir_attachments { File::Spec->catdir(shift->{base}, 'attachments') }

=head2 Methods

=over

=item new_entry

Create and return a page. A header is required as argument. If the page
does not exist it gets created according to the header. If the header
contains a date, the page is considered to be a blog entry (and positioned
as such).

=cut

sub new_entry {
    my $self = shift;
    my $hdr = shift;

    my $p = $self->entry($hdr);
    $hdr->dump($p->open('w')) unless $p->exists;
    return $p
}

=item entry

Similar to C<new_entry>, but does not create the content file if it
doesn't exist already.

=cut

sub entry {
    my $self = shift;
    my $hdr = shift;
    confess "Not a header: $hdr" unless $hdr->isa('PFT::Header');

    my $params = {
        tree => $self,
        path => $self->hdr_to_path($hdr),
        name => $hdr->title,
    };

    my $d = $hdr->date;
    defined $d
        ? $d->complete
            ? PFT::Content::Blog->new($params)
            : PFT::Content::Month->new($params)
        : PFT::Content::Page->new($params)
}

=item hdr_to_path

Given a PFT::Header object, returns the path of a page or blog page within
the tree.

=cut

sub hdr_to_path {
    my $self = shift;
    my $hdr = shift;
    confess 'Not a header' unless $hdr->isa('PFT::Header');

    if (defined(my $d = $hdr->date)) {
        my($basedir, $fname);

        defined $d->y && defined $d->m
            or confess 'Year and month are required';

        my $ym = sprintf('%04d-%02d', $d->y, $d->m);
        if (defined $d->d) {
            $basedir = File::Spec->catdir($self->dir_blog, $ym);
            $fname = sprintf('%02d-%s', $d->d, $hdr->slug);
        } else {
            $basedir = $self->dir_blog;
            $fname = $ym . '.month';
        }

        File::Spec->catfile($basedir, $fname)
    } else {
        File::Spec->catfile($self->dir_pages, $hdr->slug)
    }
}

=item new_tag

Create and return a tag page. A header is required as argument. If the
tag page does not exist it gets created according to the header.

=cut

sub new_tag {
    my $self = shift;
    my $hdr = shift;

    my $p = $self->tag($hdr);
    $hdr->dump($p->open('w')) unless $p->exists;
    return $p;
}

=item tag

Similar to C<new_tag>, but does not create the content file if it doesn't
exist already.

=cut

sub tag {
    my $self = shift;
    my $hdr = shift;

    confess "Not a header: $hdr" unless $hdr->isa('PFT::Header');
    PFT::Content::Tag->new({
        tree => $self,
        path => File::Spec->catfile($self->dir_tags, $hdr->slug),
        name => $hdr->title,
    })
}

sub _text_ls {
    my $self = shift;

    my @out;
    for my $path (PFT::Util::locale_glob @_) {
        my $hdr = eval { PFT::Header->load($path) }
            or confess "Loading header of $path: " . $@ =~ s/ at .*$//rs;

        push @out, {
            tree => $self,
            path => $path,
            name => $hdr->title,
        };
    }
    @out
}

=item blog_ls

List all blog entries

=cut

sub blog_ls {
    my $self = shift;
    map(
        PFT::Content::Blog->new($_),
        $self->_text_ls(File::Spec->catfile($self->dir_blog, '*', '*'))
    ),
    map(
        PFT::Content::Month->new($_),
        $self->_text_ls(File::Spec->catfile($self->dir_blog, '*.month'))
    )
}

=item pages_ls

List all pages

=cut

sub pages_ls {
    my $self = shift;
    map PFT::Content::Page->new($_),
        $self->_text_ls(File::Spec->catfile($self->dir_pages, '*'))
}

=item tags_ls

List all tag pages

=cut

sub tags_ls {
    my $self = shift;
    map PFT::Content::Tag->new($_),
        $self->_text_ls(File::Spec->catfile($self->dir_tags, '*'))
}

=item entry_ls

List all entries (pages, blog, tags)

=cut

sub entry_ls {
    my $self = shift;
    $self->pages_ls,
    $self->blog_ls,
    $self->tags_ls,
}

sub _blob {
    my $self = shift;
    my $pfxlen = length(my $pfx = shift) + length(path_sep);
    confess 'No path?' unless @_;

    my $path = File::Spec->catfile($pfx, @_);
    {
        tree => $self,
        path => $path,
        relpath => [File::Spec->splitdir(substr($path, $pfxlen))],
    }
}

sub _blob_ls {
    my $self = shift;

    my $pfxlen = length(my $pfx = shift) + length(path_sep);
    map {
        tree => $self,
        path => $_,
        relpath => [File::Spec->splitdir(substr($_, $pfxlen))],
    },
    PFT::Util::list_files($pfx)
}

=item pic

Accepts a list of strings which will be joined into the path of a
picture file.  Returns a C<PFT::Content::Blob> instance, which could
correspond to a non-existing file. The caller might create it (e.g. by
copying a picture on the corresponding path).

=cut

sub pic {
    my $self = shift;
    PFT::Content::Picture->new($self->_blob($self->dir_pics, @_))
}

=item pics_ls

List all pictures

=cut

sub pics_ls {
    my $self = shift;
    map PFT::Content::Picture->new($_), $self->_blob_ls($self->dir_pics)
}

=item attachment

Accepts a list of strings which will be joined into the path of an
attachment file.  Returns a C<PFT::Content::Blob> instance, which could
correspond to a non-existing file. The caller might create it (e.g. by
copying a file on the corresponding path).

Note that the input path should be made by strings in encoded form, in
order to match the filesystem path.

=cut

sub attachment {
    my $self = shift;
    PFT::Content::Attachment->new($self->_blob($self->dir_attachments, @_))
}

=item attachments_ls

List all attachments

=cut

sub attachments_ls {
    my $self = shift;
    map PFT::Content::Attachment->new($_),
        $self->_blob_ls($self->dir_attachments)
}

=item blog_back

Go back in blog history. Expects one optional argument as the number of
steps backward in history. If such argument is not provided, it defaults
to 0, returning the most recent entry. Returns a PFT::Content::Blog
object.

=cut

sub blog_back {
    my $self = shift;
    my $back = shift || 0;

    confess 'Negative back?' if $back < 0;

    my @globs = PFT::Util::locale_glob(
        File::Spec->catfile($self->dir_blog, '*', '*')
    );

    return undef if $back > scalar(@globs) - 1;

    my $path = (sort { $b cmp $a } @globs)[$back];

    my $h = eval { PFT::Header->load($path) };
    $h or croak "Loading $path: " . $@ =~ s/ at .*$//rs;

    PFT::Content::Blog->new({
        tree => $self,
        path => $path,
        name => $h->title,
    })
}

=item path_to_date

Given a path (of a page) determine the corresponding date. Returns a
C<PFT::Date> object or undef if the page does not have date.

=cut

sub path_to_date {
    my($self, $content) = @_;

    unless ($content->isa('PFT::Content::File')) {
        confess 'Cannot determine path: ',
            ref $content || $content, ' is not not PFT::Content::File'
    }

    my $path = $content->path;

    return undef unless ($content->isa('PFT::Content::Blog'));

    my $rel = File::Spec->abs2rel($path, $self->dir_blog);
    die $rel if index($rel, File::Spec->updir) >= 0;
    my($ym, $dt) = File::Spec->splitdir($rel);
    die if $content->isa('PFT::Content::Month') && defined $dt;

    PFT::Date->new(
        substr($ym, 0, 4),
        substr($ym, 5, 2),
        defined($dt) ? substr($dt, 0, 2) : do {
            $ym =~ /^\d{4}-\d{2}.month$/ or confess "Unexpected $ym";
            undef
        }
    )
}

=item path_to_slug

Given a path (of a page) determine the corresponding slug string.

=cut

sub path_to_slug {
    my $self = shift;
    my $path = shift;

    my $fname = basename $path;

    my $rel = File::Spec->abs2rel($path, $self->dir_blog);
    $fname =~ s/^\d{2}-// if index($rel, File::Spec->updir) < 0;

    $fname
}

=item was_renamed

Notify a renaming of a inner file. First parameter is the original name,
second parameter is the new name.

=cut

sub was_renamed {
    my $self = shift;
    my $d = dirname shift;

    # $ignored = shift

    opendir(my $dh, $d) or return;
    rmdir $d unless File::Spec->no_upwards(readdir $dh);
    close $dh;
}

=back

=cut

1;
