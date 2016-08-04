%define module PFT
Name:           perl-%{module}
Version:        1.0.3
Release:        1%{?dist}
Summary:        Hacker friendly static blog generator, core library

License:        GPL+
URL:            https://github.com/dacav/%{module}
Source0:        https://github.com/dacav/%{module}/archive/v%{version}.tar.gz#/%{module}-%{version}.tar.gz
BuildArch:      noarch
# Correct for lots of packages, other common choices include eg. Module::Build
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Test::More)
BuildRequires:  perl(Text::Markdown)
BuildRequires:  perl(Encode), perl(Encode::Locale)
BuildRequires:  perl(YAML::Tiny)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%{?perl_default_filter}

%description
PFT stands for *Plain F. Text*, where the meaning of *F.* is up to
personal interpretation. Like *Fancy* or *Fantastic*.

It is yet another static website generator. This means your content is
compiled once and the result can be served by a simple HTTP server,
without need of server-side dynamic content generation.

This package provides the core library which abstracts away the filesystem
access.

%prep
%setup -q -n %{module}-%{version}


%build
# Remove OPTIMIZE=... from noarch packages (unneeded)
%{__perl} Makefile.PL INSTALLDIRS=vendor OPTIMIZE="$RPM_OPT_FLAGS"
make %{?_smp_mflags}


%install
rm -rf %{buildroot}
make pure_install DESTDIR=%{buildroot}
find %{buildroot} -type f -name .packlist -exec rm -f {} ';'


%check
LC_ALL="en_US.utf8" make test


%files
%doc %{_mandir}/man3/* 
%{perl_vendorlib}/*


%changelog
* Thu Aug 04 2016 dacav@openmailbox.org - 1.0.3-1
- Release 1.0.3

* Mon Jun 20 2016 dacav openmailbox.org 1.0.1-1.fc23
- First packaging
