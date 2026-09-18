#!/usr/bin/env bash
set -euo pipefail

# Static/read-only anti-regression checks plus lightweight command probes.
# This is not a security boundary or a substitute for runtime/integration testing.

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

if grep -Eq '<allow_(any|inactive|active)>auth_admin_keep</allow_' data/org.kriscc.controlcenter.policy; then
  echo "ERROR: Polkit policy must not retain admin authorization" >&2
  exit 1
fi

grep -q 'org.kriscc.controlcenter.bootc.status' data/org.kriscc.controlcenter.policy
grep -A6 'org.kriscc.controlcenter.bootc.status' data/org.kriscc.controlcenter.policy \
  | grep -q '<allow_active>yes</allow_active>'

# KrisOS supports a single deployment: rollback must not be offered or
# privileged, and repository mutations must not bypass rk policy.
if grep -RniE 'bootc[^\n]*rollback|"rollback"|Rollback \+ apply|Prepara rollback' \
    qml/modules/SystemModule.qml qml/modules/RecoveryModule.qml \
    src/PolkitHelper.cpp data/org.kriscc.controlcenter.policy; then
  echo "ERROR: unsupported BootC rollback remains exposed" >&2
  exit 1
fi
if grep -RniE 'config-manager|addrepo|Aggiungi repository' \
    qml/modules/SoftwareModule.qml src/PolkitHelper.cpp data/org.kriscc.controlcenter.policy; then
  echo "ERROR: arbitrary DNF repository mutation remains exposed" >&2
  exit 1
fi

# RPM preview must be the same policy path as the actual rk transaction.
grep -q 'QStringLiteral("/usr/bin/rk")' src/UtilityBackend.cpp
grep -q 'QStringLiteral("plan")' src/UtilityBackend.cpp
if grep -nE 'dnf5.*install|install.*--assumeno|--assumeno' src/UtilityBackend.cpp; then
  echo "ERROR: RPM preview bypasses rk policy" >&2
  exit 1
fi

# Package discovery must match the repositories enabled by rk, while the
# installed inventory remains local and must not be filtered by repository.
grep -q 'QStringLiteral("--repo=fedora,updates")' src/PackageSearch.cpp
grep -q 'filter != QStringLiteral("--installed")' src/PackageSearch.cpp
grep -q 'id != QStringLiteral("fedora") && id != QStringLiteral("updates")' src/SoftwareBackend.cpp

# Flatpak management is deliberately per-user. Inventory, remotes and mutations
# must all use the same installation scope so the UI never shows system refs it
# cannot modify.
grep -q 'QStringLiteral("list"), QStringLiteral("--user"), QStringLiteral("--app")' src/UtilityBackend.cpp
grep -q 'QStringLiteral("remotes"), QStringLiteral("--user")' src/UtilityBackend.cpp
grep -q 'mode == QStringLiteral("update-all")' src/UtilityBackend.cpp
grep -q 'mode == QStringLiteral("update")' src/UtilityBackend.cpp
grep -q 'QStringLiteral("update"), QStringLiteral("--user"), QStringLiteral("--noninteractive"), QStringLiteral("--assumeyes")' src/UtilityBackend.cpp
grep -q 'text: qsTr("Aggiorna tutto")' qml/modules/FlatpakModule.qml
grep -q 'text: qsTr("Aggiorna")' qml/modules/FlatpakModule.qml

# The BootC check is an explicit registry check and must remain non-applying.
grep -Fq 'root.runBootc(["upgrade", "--check"])' qml/modules/SystemModule.qml
grep -q 'text: qsTr("Controlla immagine")' qml/modules/SystemModule.qml

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
# fallbacks for machines that have not yet booted the renamed image, and using
# one must be visible in the application log.
grep -q '/usr/share/krisos/owned-packages.txt' src/PackageSearch.cpp
grep -q '/var/lib/krisos/packages.list' src/PackageSearch.cpp
grep -q '/var/lib/krisos/packages.list' src/BootcBackend.cpp
grep -q '/usr/share/raku-kris/owned-packages.txt' src/PackageSearch.cpp
grep -q '/var/lib/raku-kris/packages.list' src/PackageSearch.cpp
grep -q '/var/lib/raku-kris/packages.list' src/BootcBackend.cpp
grep -q 'using legacy compatibility path' src/PackageSearch.cpp
grep -q 'using legacy compatibility path' src/BootcBackend.cpp

# krisCC has one technical identity. Old experimental package/application names
# must not be shipped or advertised as compatibility aliases.
test -f packaging/krisCC.spec
test ! -e packaging/kcc.spec
test ! -e packaging/k-controlc.spec
test -f data/krisCC.desktop
test ! -e data/kcc.desktop
test ! -e data/k-controlc.desktop
test -f data/icons/hicolor/scalable/apps/krisCC.svg
test ! -e data/icons/hicolor/scalable/apps/kcc.svg
test ! -e data/icons/hicolor/scalable/apps/k-controlc.svg
test -f data/org.kriscc.controlcenter.policy
test ! -e data/org.kcontrolc.controlcenter.policy
test -f data/org.kriscc.KrisCC.metainfo.xml
test ! -e data/org.kcontrolc.KControlC.metainfo.xml

grep -q '^Name:[[:space:]]*krisCC$' packaging/krisCC.spec
grep -Fxq 'Version:        0.5.1' packaging/krisCC.spec
grep -Fxq 'Release:        5%{?dist}' packaging/krisCC.spec
if grep -Eq '^Provides:[[:space:]]*(kcc|k-controlc)([[:space:]=]|$)|^Obsoletes:[[:space:]]*(kcc|k-controlc)([[:space:]<=>]|$)' packaging/krisCC.spec; then
  echo "ERROR: krisCC must not provide or obsolete experimental legacy identities" >&2
  exit 1
fi

grep -q 'qt_add_executable(krisCC' CMakeLists.txt
grep -q 'URI org.kriscc' CMakeLists.txt
grep -q 'install(TARGETS krisCC' CMakeLists.txt
grep -q 'data/krisCC.desktop' CMakeLists.txt
grep -q 'data/icons/hicolor/scalable/apps/krisCC.svg' CMakeLists.txt
grep -q 'data/org.kriscc.controlcenter.policy' CMakeLists.txt
grep -q 'data/org.kriscc.KrisCC.metainfo.xml' CMakeLists.txt
grep -q '^Name=krisCC$' data/krisCC.desktop
grep -q '^Exec=krisCC$' data/krisCC.desktop
grep -q '^Icon=krisCC$' data/krisCC.desktop
grep -q '<id>org.kriscc.KrisCC</id>' data/org.kriscc.KrisCC.metainfo.xml
grep -q '<name>krisCC</name>' data/org.kriscc.KrisCC.metainfo.xml
grep -q '<provides><binary>krisCC</binary></provides>' data/org.kriscc.KrisCC.metainfo.xml
grep -q '<vendor>krisCC</vendor>' data/org.kriscc.controlcenter.policy

grep -q 'qmlRegisterType<PackageSearch>("org.kriscc"' src/main.cpp
grep -q 'loadFromModule(QStringLiteral("org.kriscc")' src/main.cpp
grep -q 'import org.kriscc' qml/Main.qml
grep -q 'import org.kriscc' qml/modules/SoftwareModule.qml
if grep -R -n 'org\.kcontrolc' CMakeLists.txt src/main.cpp qml data packaging; then
  echo "ERROR: old org.kcontrolc application identity remains" >&2
  exit 1
fi

# No old product branding may leak into the UI. Historical backup directories
# are allowed only as non-destructive exclusions in SystemBackend.
if grep -R -nE 'K-ControlC|(^|[^[:alnum:]])KCC([^[:alnum:]]|$)' qml; then
  echo "ERROR: visible legacy K-ControlC/KCC branding remains in QML" >&2
  exit 1
fi
grep -q 'krisCC Quick System Info' src/SystemBackend.cpp
grep -q 'QStringLiteral("/krisCC Backups")' src/SystemBackend.cpp
grep -q 'QStringLiteral("--exclude=./KCC Backups")' src/SystemBackend.cpp
grep -q 'QStringLiteral("--exclude=./K-ControlC Backups")' src/SystemBackend.cpp

if grep -R -nE 'org\.raku|import raku\.cc|raku Control Center|raku Fedora' \
    CMakeLists.txt src/main.cpp qml data/krisCC.desktop packaging/krisCC.spec \
    data/org.kriscc.controlcenter.policy data/org.kriscc.KrisCC.metainfo.xml; then
  echo "ERROR: legacy Raku branding remains in application identity/metadata" >&2
  exit 1
fi

if grep -R -nE 'github\.com/krism-eu/(K-ControlC|KCC)([^[:alnum:]]|$)' \
    CMakeLists.txt src qml data packaging README.md INTEGRAZIONE.md .github; then
  echo "ERROR: old repository URL remains" >&2
  exit 1
fi

# Read-only external queries must have watchdogs so busy/searching cannot remain forever.
grep -q 'krisccTimedOut' src/PackageSearch.cpp
grep -q 'krisccTimedOut' src/SoftwareBackend.cpp
grep -q 'krisccTimedOut' src/BootcBackend.cpp
grep -q 'Tempo massimo superato' src/UtilityBackend.cpp

# Backend/UI state must not depend on translated presentation strings.
grep -q 'Q_PROPERTY(QString operationId' src/UtilityBackend.h
grep -q 'Q_PROPERTY(QString resultState' src/UtilityBackend.h
grep -q 'UtilityBackend.operationId === "rpm.plan"' qml/modules/SoftwareModule.qml
grep -q 'UtilityBackend.operationId !== "podman.list"' qml/modules/PodmanModule.qml
grep -q 'UtilityBackend.operationId === "bookmark.health"' qml/modules/SystemModule.qml
if grep -R -nE 'UtilityBackend\.title[[:space:]]*(===|!==)[[:space:]]*qsTr|UtilityBackend\.output[[:space:]]*===[[:space:]]*qsTr|backupStatus\.indexOf\(qsTr' qml; then
  echo "ERROR: translated UI strings are still used as backend state" >&2
  exit 1
fi

# Backups are atomic and the UI supports explicit verification and restore.
grep -q 'QStringLiteral(".partial")' src/SystemBackend.cpp
grep -q 'exitCode == 0 || exitCode == 1' src/SystemBackend.cpp
grep -q 'Q_INVOKABLE bool cancelSnapshot' src/SystemBackend.h
grep -q 'Q_INVOKABLE bool verifySnapshot' src/SystemBackend.h
grep -q 'Q_INVOKABLE bool restoreSnapshot' src/SystemBackend.h
grep -q 'validateBackupPath' src/SystemBackend.cpp
grep -q 'QProcess::nullDevice()' src/SystemBackend.cpp
grep -q 'Impossibile avviare la verifica' src/SystemBackend.cpp
grep -q 'Impossibile avviare il ripristino' src/SystemBackend.cpp
grep -A5 'flatpak-unused' src/SystemBackend.cpp | grep -q 'QStringLiteral("--user")'
grep -q 'Q_PROPERTY(QString backupState' src/SystemBackend.h
grep -q 'OperationLog::append' src/SystemBackend.cpp
grep -q 'src/OperationLog.cpp src/OperationLog.h' CMakeLists.txt

# Next-boot selection is one-shot only: BootNext or grub2-reboot, never a permanent BootOrder rewrite.
grep -q 'QStringLiteral("/usr/bin/efibootmgr")' src/PolkitHelper.cpp
grep -q 'QStringLiteral("-n")' src/PolkitHelper.cpp
grep -q 'QStringLiteral("/usr/bin/grub2-reboot")' src/PolkitHelper.cpp
grep -q "entry.startsWith(QLatin1Char('-'))" src/PolkitHelper.cpp
grep -q 'org.kriscc.controlcenter.boot.next-uefi' data/org.kriscc.controlcenter.policy
grep -q 'org.kriscc.controlcenter.boot.next-grub' data/org.kriscc.controlcenter.policy
grep -q 'BootNext vale per un solo riavvio' qml/modules/SystemModule.qml
if grep -q 'efibootmgr.*-[Oo]' src/PolkitHelper.cpp qml/modules/SystemModule.qml; then
  echo "ERROR: permanent UEFI BootOrder mutation must not be exposed" >&2
  exit 1
fi

# Minimal scope: no firmware updater or first-run/welcome workflow is shipped by the new system page.
if grep -niE 'fwupdmgr|firmware|welcome|first.?run' qml/modules/SystemModule.qml qml/modules/DashboardModule.qml qml/modules/RecoveryModule.qml; then
  echo "ERROR: firmware/welcome scope leaked into krisCC 0.5 UI" >&2
  exit 1
fi

# --background must be a single activatable session instance, not an unreachable duplicate.
grep -q 'org.kriscc.ControlCenter' src/main.cpp
grep -q 'registerService(serviceName)' src/main.cpp
grep -q 'existing.call(QDBus::NoBlock, QStringLiteral("show"))' src/main.cpp
grep -q 'src/InstanceController.cpp src/InstanceController.h' CMakeLists.txt
grep -q 'Q_CLASSINFO("D-Bus Interface", "org.kriscc.ControlCenter")' src/InstanceController.h
grep -q 'qml/modules/SystemModule.qml' CMakeLists.txt
grep -q 'function replaceForIndex(index)' qml/Main.qml
test "$(grep -c 'pageStack.replace(' qml/Main.qml)" -eq 7

# The released RPM is validated in a fresh Fedora job before release publication.
grep -q '^  rpm-smoke:' .github/workflows/build.yml
grep -Fq 'needs: [build-fedora, rpm-smoke, release-audit]' .github/workflows/build.yml
grep -Fq "dnf -y install \"\$rpm_file\"" .github/workflows/build.yml
grep -q '/usr/bin/krisCC' .github/workflows/build.yml

echo "Checking mandatory local DNF5 behavior..."
dnf5 list --installed --json >/dev/null

echo "Checking repository-backed DNF5 queries when metadata is available..."
if dnf5 repo list --all --json >/dev/null 2>&1; then
  dnf5 repo list --all --json >/dev/null
  if dnf5 --repo=fedora,updates repoquery --available \
      --queryformat $'%{name}\t%{summary}\t%{evr}\t%{repoid}\t%{arch}\t%{downloadsize}\t%{installsize}\n' \
      'bash*' > /tmp/kriscc-repoquery.txt 2>/tmp/kriscc-repoquery.err; then
    grep -q '^bash' /tmp/kriscc-repoquery.txt || echo "WARNING: bash not returned by optional repoquery probe"
    if grep -q '^bash' /tmp/kriscc-repoquery.txt; then
      awk -F '\t' 'NR == 1 { exit (NF >= 7 ? 0 : 1) }' /tmp/kriscc-repoquery.txt \
        || { echo "ERROR: repoquery metadata fields are not tab-separated" >&2; exit 1; }
    fi
  else
    echo "WARNING: optional repoquery probe skipped (repository metadata/network unavailable)"
  fi
  dnf5 --repo=fedora,updates list --upgrades --json >/dev/null 2>&1 || echo "WARNING: optional upgrades probe unavailable"
  dnf5 --repo=fedora,updates list --recent --json >/dev/null 2>&1 || echo "WARNING: optional recent-packages probe unavailable"
else
  echo "WARNING: repository metadata unavailable; optional DNF5 probes skipped"
fi

if command -v bootc >/dev/null 2>&1; then
  echo "bootc detected; validating the exact JSON command used by krisCC"
  bootc status --format json > /tmp/kriscc-bootc-status.json
  grep -q '"status"' /tmp/kriscc-bootc-status.json
else
  echo "bootc not available in this CI container; static command/schema guards passed"
fi
