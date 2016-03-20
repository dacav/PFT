package PFT::Compiler v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Compiler - Compile a site

=head1 SYNOPSIS

    my $tree = PFT::Tree->new(...);
    PFT::Compiler::build($tree);

=head1 DESCRIPTION

=cut

use Exporter 'import';
our @EXPORT_OK = qw/build/;

use Carp;
use Encode;
use Template::Alloy;

use File::Spec;
use File::Basename qw/dirname/;
use File::Path qw/make_path/;

use PFT::Map;
use PFT::Text;

sub node_to_rel {
    my $node = shift;
    my $hdr = $node->header;
    if ((my $k = substr($node->id, 0, 1)) eq 'b') {(
        'blog',
        sprintf('%04d-%02d', $hdr->date->y, $hdr->date->m),
        sprintf('%02d-%s.html', $hdr->date->d, $hdr->slug),
    )} elsif ($k eq 'm') {(
        'blog',
        sprintf('%04d-%02d.html', $hdr->date->y, $hdr->date->m),
    )} elsif ($k eq 'p') {(
        'pages',
        $hdr->slug . '.html',
    )} elsif ($k eq 't') {(
        'tags',
        $hdr->slug . '.html',
    )} elsif ($k eq 'i') {(
        'pics',
        $node->content->relpath
    )} elsif ($k eq 'a') {(
        'attachments',
        $node->content->relpath
    )} else { die $k };
}

sub build {
    my $tree = shift;
    my $conf = $tree->conf;

    my $out_enc = $conf->{output_enc};
    my $template = Template::Alloy->new(
        INCLUDE_PATH => $tree->dir_templates
    );
    my $dir_build = $tree->dir_build;
    my $map = PFT::Map->new($tree->content);
    my %entry_info = (
        site => {
            encoding => $out_enc,
            title => $conf->{site_title},
        },
    );

    for my $node ($map->nodes) {
        my $path_rel = File::Spec->catfile(
            map encode($out_enc, $_),
            node_to_rel $node
        );
        my $out_path = File::Spec->catfile($dir_build, $path_rel);

        print 'Processing ', encode($out_enc, $node), "\n";
        print "-> File: $out_path\n";

        my $content = $node->content;
        if ($content->isa('PFT::Content::Entry')) {
            my $hdr = $node->header;

            $entry_info{content} = {
                title => $content->isa('PFT::Content::Month')
                    ? sprintf("%04d / %02d", @{$hdr->date})
                    : $hdr->title,
            };

            my $out_data;
            $template->process(
                ($hdr->template || $conf->{template}) . '.html',
                \%entry_info,
                \$out_data,
            ) || croak 'Template expansion issue: ', $template->error;

            make_path dirname $out_path;
            open my $fh, ">:encoding($out_enc)", $out_path or croak "Opening $out_path: $!";
            print $fh $out_data;
            close $fh;
        }

        print "\n";
    }
}

1;
