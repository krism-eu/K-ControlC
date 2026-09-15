#!/usr/bin/env bash
set -euo pipefail

if grep -Eq '"--search"|QStringLiteral\("--search"\)' src/PackageSearch.cpp; then
  echo "ERROR: PackageSearch still contains unsupported dnf5 repoquery --search" >&2
  exit 1
fi

if grep -q 'auth_admin_keep' data/org.raku.controlcenter.policy; then
  echo "ERROR: Polkit policy must not retain admin authorization" >&2
  exit 1
fi

grep -q 'org.kde.kirigami' qml/Main.qml
grep -q 'config-manager' src/PolkitHelper.cpp

echo "Checking DNF5 read-only package queries..."
dnf5 repoquery --available --queryformat '%{name}\t%{summary}\n' 'bash*' | grep -q '^bash'
dnf5 list --installed --json >/dev/null
dnf5 list --upgrades --json >/dev/null
dnf5 list --recent --json >/dev/null
dnf5 repo list --all --json >/dev/null
dnf5 config-manager --help >/dev/null

if command -v bootc >/dev/null 2>&1; then
  echo "bootc detected; validating status JSON when available"
  bootc status --json --format-version=1 >/dev/null || bootc status --format=humanreadable >/dev/null
else
  echo "bootc not available in this CI container; skipping host deployment probe"
fi
