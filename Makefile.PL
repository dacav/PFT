use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PFT',
    AUTHOR           => q{Giovanni Simoni (dacav at openmailbox)},
    VERSION_FROM     => 'lib/PFT.pm',
    ABSTRACT         => 'Hacker friendly static blog generator',
    LICENSE          => 'GNU GPL v3',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'                  => 0,
        'Cwd'                   => 0,
        'Encode'                => 0,
        'Exporter'              => 0,
        'File::Basename'        => 0,
        'File::Copy::Recursive' => 0,
        'File::Path'            => 0,
        'File::Spec::Functions' => 0,
        'IO::File'              => 0,
        'Pod::Find'             => 0,
        'Pod::Usage'            => 0,
        'Scalar::Util'          => 0,
        'Template::Alloy'       => 0,
        'Text::MultiMarkdown'   => 0,
        'YAML::Tiny'            => 0,
        'Text::MultiMarkdown'   => 0,
        'Template::Alloy'       => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PFT-*' },
);
