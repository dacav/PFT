%global module PFT
Name:           perl-%{module}
Version:        1.0.3
Release:        4%{?dist}
Summary:        Hacker friendly static blog generator, core library

License:        GPLv3+
URL:            https://github.com/dacav/%{module}
Source0:        https://github.com/dacav/%{module}/archive/v%{version}.tar.gz#/%{module}-%{version}.tar.gz
BuildArch:      noarch

# As by /etc/rpmdevtools/spectemplate-perl.spec
BuildRequires:  perl
BuildRequires:  perl-generators
BuildRequires:  perl(ExtUtils::MakeMaker)

# Additional dependencies at build time
# tangerine -c Makefile.PL lib \|
#       perl -nE '/^\s/ and next; s/^/BuildRequires:  perl(/; s/$/)/; print'
BuildRequires:  perl(Carp)
BuildRequires:  perl(constant)
BuildRequires:  perl(Cwd)
BuildRequires:  perl(Encode)
BuildRequires:  perl(Encode::Locale)
BuildRequires:  perl(Exporter)
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(feature)
BuildRequires:  perl(File::Basename)
BuildRequires:  perl(File::Path)
BuildRequires:  perl(File::Spec)
BuildRequires:  perl(File::Spec::Functions)
BuildRequires:  perl(File::Temp)
BuildRequires:  perl(IO::File)
BuildRequires:  perl(overload)
BuildRequires:  perl(parent)
BuildRequires:  perl(Scalar::Util)
BuildRequires:  perl(strict)
BuildRequires:  perl(Test::More)
BuildRequires:  perl(Text::Markdown)
BuildRequires:  perl(utf8)
BuildRequires:  perl(warnings)
BuildRequires:  perl(YAML::Tiny)

# As by /etc/rpmdevtools/spectemplate-perl.spec
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%{?perl_default_filter}

%description
PFT stands for *Plain F. Text*, where the meaning of *F.* is up to
personal interpretation. Like *Fancy* or *Fantastic*.

It is yet another static website generator. This means your content is
compiled once and the result can be served by a simple HTTP server,
without need of server-side dynamic content generation.

This package provides the core library which abstracts away the file-system
access.

%prep
%setup -q -n %{module}-%{version}


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}


%install
make pure_install DESTDIR=%{buildroot}
find %{buildroot} -type f -name .packlist -exec rm -f {} ';'
find %{buildroot} -depth -type d -exec rmdir {} 2>/dev/null ';'
%{_fixperms} %{buildroot}/*

%check
LC_ALL="en_US.utf8" make test


%files
%doc %{_mandir}/man3/* 
%{!?_licensedir:%global license %%doc}
%{perl_vendorlib}/*
%doc README.md
%license LICENSE

%changelog
* Fri Aug 26 2016 <dacav@openmailbox.org> - 1.0.3-4
- Using tangerine for BuildRequires
- Fixed changelog

* Mon Aug 22 2016 <dacav@openmailbox.org> - 1.0.3-3
- Using global instead of define
- GPLv3+
- Added perl and perl-generators as by template
- Removed unneded optimization flag
- Misc install fixes
- License fixes
- Added README as doc

* Sun Aug 14 2016 <dacav@openmailbox.org> - 1.0.3-2
- Fixed US English

* Thu Aug 04 2016 <dacav@openmailbox.org> - 1.0.3-1
- Release 1.0.3

* Mon Jun 20 2016 <dacav@openmailbox.org> 1.0.1-1.fc23
- First packaging
