#!/usr/bin/env bash
set -euo pipefail

if grep -Eq '"--search"|QStringLiteral\("--search"\)' src/PackageSearch.cpp; then
  echo "ERROR: PackageSearch still contains unsupported dnf5 repoquery --search" >&2
  exit 1
fi

echo "Checking dnf5 repoquery positional package-spec..."
dnf5 repoquery --available --queryformat '%{name}\t%{summary}\n' 'bash*' | grep -q '^bash'

if command -v bootc >/dev/null 2>&1; then
  echo "bootc detected; validating status JSON when available"
  bootc status --json --format-version=1 >/dev/null || bootc status --format=humanreadable >/dev/null
else
  echo "bootc not available in this CI container; skipping host deployment probe"
fi

if command -v kcmshell6 >/dev/null 2>&1; then
  if kcmshell6 --list 2>/dev/null | grep -qi kcm_flatpak; then
    echo "kcm_flatpak available"
  else
    echo "kcm_flatpak absent: runtime fallback to plasma-discover will be used"
  fi
fi
