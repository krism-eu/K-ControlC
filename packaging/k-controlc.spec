Name:           k-controlc
Version:        0.4.0
Release:        4%{?dist}
Summary:        Personal Control Center for Fedora bootc
License:        MIT
URL:            https://github.com/krism-eu/K-ControlC
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  gcc-c++
BuildRequires:  cmake
BuildRequires:  ninja-build
BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  kf6-kirigami-devel

Requires:       qt6-qtbase
Requires:       qt6-qtdeclarative
Requires:       kf6-kirigami
Requires:       polkit
Requires:       rpm
Requires:       dnf5
Requires:       dnf5-plugins
Requires:       bootc
Requires:       tar

%description
K-ControlC is a compact personal Kirigami control center for Fedora bootc
systems. It focuses on persistent software management, bootc deployments,
practical maintenance tools, diagnostics, recovery and local configuration/home
backups without duplicating Plasma System Settings.

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
%{_datadir}/polkit-1/actions/org.kcontrolc.controlcenter.policy
%{_datadir}/metainfo/org.kcontrolc.KControlC.metainfo.xml
%{_datadir}/icons/hicolor/scalable/apps/k-controlc.svg

%changelog
* Wed Sep 16 2026 krism-eu - 0.4.0-4
- Replace raw Flatpak command output with structured application cards
- Add direct Flatpak install/remove actions and clearer remote views
- Make RPM sizes, dependency preview and transaction totals explicit

* Wed Sep 16 2026 krism-eu - 0.4.0-3
- Add top navigation tabs, dedicated Flatpak and command-bookmark pages
- Add RPM transaction previews, package origin filters and repository-file addition
- Clarify external tool availability, active services and the unified backup workflow

* Wed Sep 16 2026 krism-eu - 0.4.0-2
- Fix DNF5 search metadata parsing
- Refine software and repository presentation

* Wed Sep 16 2026 krism-eu - 0.4.0-1
- Move the UI to Kirigami and remove Plasma configuration duplication
- Add package inventory, upgrades, recent packages and repository management
- Add personal maintenance tools and local config/home backup snapshots

* Tue Sep 15 2026 krism-eu - 0.3.0-1
- Initial standalone K-ControlC package
