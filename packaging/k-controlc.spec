Name:           k-controlc
Version:        0.3.0
Release:        1%{?dist}
Summary:        raku Control Center for Fedora bootc
License:        MIT
URL:            https://github.com/krism-eu/K-ControlC
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  gcc-c++
BuildRequires:  cmake
BuildRequires:  ninja-build
BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtdeclarative-devel

Requires:       qt6-qtbase
Requires:       qt6-qtdeclarative
Requires:       polkit
Requires:       rpm
Requires:       dnf5
Requires:       bootc

%description
K-ControlC is a Qt 6/QML control center for raku systems based on Fedora bootc.
It integrates image deployment management, persistent packages, networking,
services, firewall, diagnostics, firmware, recovery and desktop tools.

%prep
%autosetup -n %{name}-%{version}

%build
%cmake -G Ninja
%cmake_build

%install
%cmake_install

%files
%license LICENSE
%doc README.md
%{_bindir}/k-controlc
%{_datadir}/applications/k-controlc.desktop
%{_datadir}/polkit-1/actions/org.raku.controlcenter.policy
%{_datadir}/metainfo/org.raku.KControlC.metainfo.xml
%{_datadir}/icons/hicolor/scalable/apps/k-controlc.svg

%changelog
* Tue Sep 15 2026 krism-eu - 0.3.0-1
- Initial standalone K-ControlC package
