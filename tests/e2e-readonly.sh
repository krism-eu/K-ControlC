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

grep -q 'org.kcontrolc.controlcenter.bootc.status' data/org.kcontrolc.controlcenter.policy
grep -A6 'org.kcontrolc.controlcenter.bootc.status' data/org.kcontrolc.controlcenter.policy \
  | grep -q '<allow_active>yes</allow_active>'

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

# KrisOS is primary. The Raku paths remain only as read-only compatibility
# fallbacks for machines that have not yet booted the renamed image.
grep -q '/usr/share/krisos/owned-packages.txt' src/PackageSearch.cpp
grep -q '/var/lib/krisos/packages.list' src/PackageSearch.cpp
grep -q '/var/lib/krisos/packages.list' src/BootcBackend.cpp
grep -q '/usr/share/raku-kris/owned-packages.txt' src/PackageSearch.cpp
grep -q '/var/lib/raku-kris/packages.list' src/PackageSearch.cpp
grep -q '/var/lib/raku-kris/packages.list' src/BootcBackend.cpp

# KCC is now the package, executable and installed desktop identity. The old RPM
# name is retained only as Provides/Obsoletes so upgrades do not duplicate it.
grep -q '^Name:[[:space:]]*kcc$' packaging/k-controlc.spec
grep -q '^Provides:[[:space:]]*k-controlc' packaging/k-controlc.spec
grep -q '^Obsoletes:[[:space:]]*k-controlc' packaging/k-controlc.spec
grep -q 'qt_add_executable(kcc' CMakeLists.txt
grep -q 'install(TARGETS kcc' CMakeLists.txt
grep -q '^Name=KCC$' data/k-controlc.desktop
grep -q '^Exec=kcc$' data/k-controlc.desktop
grep -q '^Icon=kcc$' data/k-controlc.desktop
grep -q '<name>KCC</name>' data/org.kcontrolc.KControlC.metainfo.xml
grep -q '<provides><binary>kcc</binary></provides>' data/org.kcontrolc.KControlC.metainfo.xml
grep -q '<vendor>KCC</vendor>' data/org.kcontrolc.controlcenter.policy
grep -q 'https://github.com/krism-eu/KCC' packaging/k-controlc.spec
grep -q 'https://github.com/krism-eu/KCC' data/org.kcontrolc.KControlC.metainfo.xml
grep -q 'https://github.com/krism-eu/KCC' data/org.kcontrolc.controlcenter.policy

# The QML module and Polkit action namespace remain stable internally during the
# package transition; changing those is unnecessary for KrisOS to install kcc.
grep -q 'org.kde.kirigami' qml/Main.qml
grep -q 'import org.kcontrolc' qml/Main.qml
grep -q 'config-manager' src/PolkitHelper.cpp

if grep -R -nE 'org\.raku|import raku\.cc|raku Control Center|raku Fedora' \
    CMakeLists.txt src/main.cpp qml data/k-controlc.desktop packaging/k-controlc.spec \
    data/org.kcontrolc.controlcenter.policy data/org.kcontrolc.KControlC.metainfo.xml; then
  echo "ERROR: legacy Raku branding remains in application identity/metadata" >&2
  exit 1
fi

if grep -R -n 'github.com/krism-eu/K-ControlC' \
    CMakeLists.txt src qml data packaging README.md INTEGRAZIONE.md .github; then
  echo "ERROR: old repository URL remains" >&2
  exit 1
fi

echo "Checking mandatory local DNF5 behavior..."
dnf5 list --installed --json >/dev/null
dnf5 config-manager --help >/dev/null

echo "Checking repository-backed DNF5 queries when metadata is available..."
if dnf5 repo list --all --json >/dev/null 2>&1; then
  dnf5 repo list --all --json >/dev/null
  if dnf5 repoquery --available \
      --queryformat $'%{name}\t%{summary}\t%{evr}\t%{repoid}\t%{arch}\t%{downloadsize}\t%{installsize}\n' \
      'bash*' > /tmp/kcc-repoquery.txt 2>/tmp/kcc-repoquery.err; then
    grep -q '^bash' /tmp/kcc-repoquery.txt || echo "WARNING: bash not returned by optional repoquery probe"
    if grep -q '^bash' /tmp/kcc-repoquery.txt; then
      awk -F '\t' 'NR == 1 { exit (NF >= 7 ? 0 : 1) }' /tmp/kcc-repoquery.txt \
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
  bootc status --format json > /tmp/kcc-bootc-status.json
  grep -q '"status"' /tmp/kcc-bootc-status.json
else
  echo "bootc not available in this CI container; static command/schema guards passed"
fi
