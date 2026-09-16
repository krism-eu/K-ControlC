#!/usr/bin/env bash
set -euo pipefail

if grep -Eq '"--search"|QStringLiteral\("--search"\)' src/PackageSearch.cpp; then
  echo "ERROR: PackageSearch still contains unsupported dnf5 repoquery --search" >&2
  exit 1
fi

if grep -Eq '<allow_(any|inactive|active)>auth_admin_keep</allow_' data/org.raku.controlcenter.policy; then
  echo "ERROR: Polkit policy must not retain admin authorization" >&2
  exit 1
fi

# Guard the exact bootc JSON invocation and schema traversal used by the UI.
if grep -Eq 'QStringLiteral\("--json"\)|QStringLiteral\("--format-version' src/BootcBackend.cpp; then
  echo "ERROR: BootcBackend must use bootc status --format json without legacy JSON flags" >&2
  exit 1
fi

grep -q 'QStringLiteral("--format")' src/BootcBackend.cpp
grep -q 'QStringLiteral("json")' src/BootcBackend.cpp
grep -q 'imageStatus.value(QStringLiteral("image")).toObject()' src/BootcBackend.cpp
grep -q 'deployment.value(QStringLiteral("ostree")).toObject()' src/BootcBackend.cpp
grep -q 'jsonString(ostree, QStringLiteral("checksum"))' src/BootcBackend.cpp

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
  echo "bootc detected; validating the exact JSON command used by K-ControlC"
  bootc status --format json > /tmp/k-controlc-bootc-status.json
  grep -q '"status"' /tmp/k-controlc-bootc-status.json
else
  echo "bootc not available in this CI container; static command/schema guards passed"
fi
