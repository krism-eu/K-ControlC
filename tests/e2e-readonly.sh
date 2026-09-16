#!/usr/bin/env bash
set -euo pipefail

if grep -Eq '"--search"|QStringLiteral\("--search"\)' src/PackageSearch.cpp; then
  echo "ERROR: PackageSearch still contains unsupported dnf5 repoquery --search" >&2
  exit 1
fi

# DNF5 repoquery does not translate a literal backslash+t for us. The C++
# queryformat must contain escaped C++ tabs (\t), not a double-escaped \\t
# sequence that reaches DNF5 as visible text.
if grep -Fq '%{name}\\\\t%{summary}' src/PackageSearch.cpp; then
  echo "ERROR: PackageSearch queryformat contains literal backslash-t separators" >&2
  exit 1
fi

if grep -Eq '<allow_(any|inactive|active)>auth_admin_keep</allow_' data/org.kcontrolc.controlcenter.policy; then
  echo "ERROR: Polkit policy must not retain admin authorization" >&2
  exit 1
fi

# Read-only bootc status must be available to the active local session without
# an authentication prompt; write operations remain protected separately.
grep -q 'org.kcontrolc.controlcenter.bootc.status' data/org.kcontrolc.controlcenter.policy
grep -A6 'org.kcontrolc.controlcenter.bootc.status' data/org.kcontrolc.controlcenter.policy \
  | grep -q '<allow_active>yes</allow_active>'

# Guard the exact bootc JSON invocation and schema traversal used by the UI.
if grep -Eq 'QStringLiteral\("--json"\)|QStringLiteral\("--format-version' src/BootcBackend.cpp; then
  echo "ERROR: BootcBackend must use bootc status --format json without legacy JSON flags" >&2
  exit 1
fi

grep -q 'QStringLiteral("--format")' src/BootcBackend.cpp
grep -q 'QStringLiteral("json")' src/BootcBackend.cpp
grep -q 'QStringLiteral("/usr/bin/pkexec")' src/BootcBackend.cpp
grep -q 'imageStatus.value(QStringLiteral("image")).toObject()' src/BootcBackend.cpp
grep -q 'deployment.value(QStringLiteral("ostree")).toObject()' src/BootcBackend.cpp
grep -q 'jsonString(ostree, QStringLiteral("checksum"))' src/BootcBackend.cpp

# KrisOS is now the primary package-state layout. Keep the old Raku paths only
# as a compatibility fallback until existing installations have migrated.
grep -q '/usr/share/krisos/owned-packages.txt' src/PackageSearch.cpp
grep -q '/var/lib/krisos/packages.list' src/PackageSearch.cpp
grep -q '/var/lib/krisos/packages.list' src/BootcBackend.cpp
grep -q '/usr/share/raku-kris/owned-packages.txt' src/PackageSearch.cpp
grep -q '/var/lib/raku-kris/packages.list' src/PackageSearch.cpp
grep -q '/var/lib/raku-kris/packages.list' src/BootcBackend.cpp

# The visible product identity is KCC; technical IDs stay compatible for now.
grep -q 'title: qsTr("KCC")' qml/Main.qml
grep -q '^Name=KCC$' data/k-controlc.desktop
grep -q '<name>KCC</name>' data/org.kcontrolc.KControlC.metainfo.xml
grep -q '<vendor>KCC</vendor>' data/org.kcontrolc.controlcenter.policy

grep -q 'org.kde.kirigami' qml/Main.qml
grep -q 'import org.kcontrolc' qml/Main.qml
grep -q 'config-manager' src/PolkitHelper.cpp

if grep -R -nE 'org\.raku|import raku\.cc|raku Control Center|raku Fedora' \
    CMakeLists.txt src/main.cpp qml data/k-controlc.desktop packaging/k-controlc.spec \
    data/org.kcontrolc.controlcenter.policy data/org.kcontrolc.KControlC.metainfo.xml; then
  echo "ERROR: legacy branding remains in application identity/metadata" >&2
  exit 1
fi

echo "Checking mandatory local DNF5 behavior..."
dnf5 list --installed --json >/dev/null
dnf5 config-manager --help >/dev/null

# These queries can depend on repository metadata/mirror availability. They are
# useful diagnostics but must not turn a temporary network outage into a build failure.
echo "Checking repository-backed DNF5 queries when metadata is available..."
if dnf5 repo list --all --json >/dev/null 2>&1; then
  dnf5 repo list --all --json >/dev/null
  if dnf5 repoquery --available \
      --queryformat $'%{name}\t%{summary}\t%{evr}\t%{repoid}\t%{arch}\t%{downloadsize}\t%{installsize}\n' \
      'bash*' > /tmp/k-controlc-repoquery.txt 2>/tmp/k-controlc-repoquery.err; then
    grep -q '^bash' /tmp/k-controlc-repoquery.txt || echo "WARNING: bash not returned by optional repoquery probe"
    if grep -q '^bash' /tmp/k-controlc-repoquery.txt; then
      awk -F '\t' 'NR == 1 { exit (NF >= 7 ? 0 : 1) }' /tmp/k-controlc-repoquery.txt \
        || { echo "ERROR: repoquery metadata fields are not tab-separated" >&2; exit 1; }
    fi
  else
    echo "WARNING: optional repoquery probe skipped (repository metadata/network unavailable)"
  fi
  dnf5 list --upgrades --json >/dev/null 2>&1 || echo "WARNING: optional upgrades probe unavailable"
  dnf5 list --recent --json >/dev/null 2>&1 || echo "WARNING: optional recent-packages probe unavailable"
else
  echo "WARNING: repository metadata unavailable; optional DNF5 probes skipped"
fi

if command -v bootc >/dev/null 2>&1; then
  echo "bootc detected; validating the exact JSON command used by KCC"
  bootc status --format json > /tmp/k-controlc-bootc-status.json
  grep -q '"status"' /tmp/k-controlc-bootc-status.json
else
  echo "bootc not available in this CI container; static command/schema guards passed"
fi
