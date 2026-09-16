Name:           krisCC
Version:        0.4.0
Release:        8%{?dist}
Summary:        krisCC personal control center for KrisOS and Fedora bootc
License:        MIT
URL:            https://github.com/krism-eu/KCC
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

# Safe transition from the original package identity. Do not obsolete/provide
# Fedora's unrelated "kcc" package: krisCC must be able to coexist with it.
Provides:       k-controlc = %{version}-%{release}
Obsoletes:      k-controlc < %{version}-%{release}

%description
krisCC is a compact personal Kirigami control center for KrisOS and Fedora bootc
systems. It focuses on persistent software management, Flatpak applications,
Podman containers, bootc deployments, practical maintenance tools, diagnostics,
recovery and local configuration/home backups without duplicating Plasma System
Settings.

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
%{_bindir}/krisCC
%{_datadir}/applications/krisCC.desktop
%{_datadir}/polkit-1/actions/org.kriscc.controlcenter.policy
%{_datadir}/metainfo/org.kriscc.KrisCC.metainfo.xml
%{_datadir}/icons/hicolor/scalable/apps/krisCC.svg

%changelog
* Wed Sep 16 2026 krism-eu - 0.4.0-8
- Rename the package and executable to krisCC to avoid Fedora kcc collisions
- Rename QML, Polkit, desktop, icon and AppStream identities to krisCC/org.kriscc
- Keep only the original k-controlc transition Provides/Obsoletes

* Wed Sep 16 2026 krism-eu - 0.4.0-7
- Rename the RPM identity and executable to kcc
- Add Provides/Obsoletes for safe replacement of installed k-controlc packages
- Point package metadata at the renamed KCC repository

* Wed Sep 16 2026 krism-eu - 0.4.0-6
- Prefer current KrisOS package-state paths with a read-only legacy fallback
- Complete the KCC user-facing metadata rename without changing installed technical IDs
- Document safe base-image integration before the KrisOS owned-package snapshot

* Wed Sep 16 2026 krism-eu - 0.4.0-5
- Add a simple Podman container management page with size, status and common actions
- Begin the safe user-facing rename from K-ControlC to KCC while retaining package compatibility
- Keep RPM size and transaction details visible in software search

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
