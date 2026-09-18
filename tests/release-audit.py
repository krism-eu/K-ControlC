#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.5.1"
RELEASE = "3"
RPM_EVR = f"{VERSION}-{RELEASE}.fc44"
RPM_FILE = f"krisCC-{RPM_EVR}.x86_64.rpm"
TAG = f"v{VERSION}-{RELEASE}"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


cmake = read("CMakeLists.txt")
spec = read("packaging/krisCC.spec")
workflow = read(".github/workflows/build.yml")
system_cpp = read("src/SystemBackend.cpp")
polkit_cpp = read("src/PolkitHelper.cpp")
utility_cpp = read("src/UtilityBackend.cpp")
main_qml = read("qml/Main.qml")
system_qml = read("qml/modules/SystemModule.qml")
recovery_qml = read("qml/modules/RecoveryModule.qml")
commands_qml = read("qml/modules/CommandsModule.qml")
readme = read("README.md")
integration_doc = read("INTEGRAZIONE.md")
e2e = read("tests/e2e-readonly.sh")

# Version/package/release identity must agree everywhere that controls the artifact.
m = re.search(r"project\(krisCC\s+VERSION\s+([0-9.]+)", cmake, re.S)
require(m and m.group(1) == VERSION, "CMake project version mismatch")
m = re.search(r"^Version:\s*(\S+)", spec, re.M)
require(m and m.group(1) == VERSION, "RPM Version mismatch")
m = re.search(r"^Release:\s*([0-9]+)%\{\?dist\}", spec, re.M)
require(m and m.group(1) == RELEASE, "RPM Release mismatch")
require(RPM_FILE in workflow, "workflow does not pin the expected runtime RPM filename")
require(RPM_EVR in workflow, "workflow does not validate the expected RPM EVR")
require(TAG in workflow, "workflow does not publish the expected immutable tag")
require(f'<release version="{VERSION}"' in read("data/org.kriscc.KrisCC.metainfo.xml"),
        "AppStream metadata is missing the current version")
require(f"krisCC-{VERSION}-*.rpm" in readme, "README RPM version mismatch")
require(f"grep -Fxq 'Release:        {RELEASE}%{{?dist}}' packaging/krisCC.spec" in e2e,
        "e2e RPM release assertion mismatch")

# Only the consolidated System page is shipped; legacy pages can remain in git history
# but must not be part of the QML module.
require("qml/modules/SystemModule.qml" in cmake, "SystemModule is not shipped")
require("qml/modules/BootcModule.qml" not in cmake, "legacy BootcModule is still shipped")
require("qml/modules/ToolsModule.qml" not in cmake, "legacy ToolsModule is still shipped")
require("src/OperationLog.cpp src/OperationLog.h" in cmake, "OperationLog is not linked")

# Every bookmark exposed by QML must have a backend implementation.
backend_bookmarks = set(re.findall(r'id == QStringLiteral\("([^"]+)"\)', utility_cpp))
qml_bookmarks = set()
for qml in (system_qml, recovery_qml, commands_qml):
    qml_bookmarks.update(re.findall(r'UtilityBackend\.runBookmark\("([^"]+)"\)', qml))
command_card_ids = set(re.findall(r'\{\s*id:\s*"([^"]+)"', commands_qml))
missing = sorted((qml_bookmarks | command_card_ids) - backend_bookmarks)
require(not missing, f"QML bookmark(s) without backend implementation: {missing}")

# Privileged entry points are deliberately tiny and explicit.
expected_programs = {
    "/usr/bin/rk",
    "/usr/bin/bootc",
    "/usr/bin/efibootmgr",
    "/usr/bin/grub2-reboot",
}
qml_privileged_programs = set()
for qml_path in ("qml/modules/SystemModule.qml", "qml/modules/RecoveryModule.qml"):
    qml = read(qml_path)
    qml_privileged_programs.update(re.findall(r'PolkitHelper\.execute\("([^"]+)"', qml))
require(qml_privileged_programs == expected_programs,
        f"unexpected privileged QML programs: {sorted(qml_privileged_programs)}")
for program in expected_programs:
    require(f'program == QStringLiteral("{program}")' in polkit_cpp,
            f"PolkitHelper does not explicitly allowlist {program}")
require('args.size() == 2 && args.at(0) == QStringLiteral("-n")' in polkit_cpp,
        "UEFI BootNext invocation is not exact")
require('args.size() == 1 && isSafeGrubEntry(args.at(0))' in polkit_cpp,
        "GRUB next-entry invocation is not exact")
require("entry.startsWith(QLatin1Char('-'))" in polkit_cpp,
        "GRUB entry validator does not reject option-shaped values")
for forbidden in ('QStringLiteral("-o")', 'QStringLiteral("-O")', "--bootorder"):
    require(forbidden not in polkit_cpp, f"permanent UEFI ordering primitive exposed: {forbidden}")
require("/usr/bin/bash" not in polkit_cpp and "/usr/bin/sh" not in polkit_cpp,
        "privileged helper must never execute a shell")

# Policy shape is checked structurally, not by grep.
policy_root = ET.parse(ROOT / "data/org.kriscc.controlcenter.policy").getroot()
actions = {node.attrib["id"]: node for node in policy_root.findall("action")}
expected_actions = {
    "org.kriscc.controlcenter.bootc.status": ("/usr/bin/bootc", "status", "yes"),
    "org.kriscc.controlcenter.rk.sync": ("/usr/bin/rk", "sync", "auth_admin"),
    "org.kriscc.controlcenter.rk.add": ("/usr/bin/rk", "add", "auth_admin"),
    "org.kriscc.controlcenter.rk.rm": ("/usr/bin/rk", "rm", "auth_admin"),
    "org.kriscc.controlcenter.bootc.upgrade": ("/usr/bin/bootc", "upgrade", "auth_admin"),
    "org.kriscc.controlcenter.boot.next-uefi": ("/usr/bin/efibootmgr", "-n", "auth_admin"),
    "org.kriscc.controlcenter.boot.next-grub": ("/usr/bin/grub2-reboot", None, "auth_admin"),
}
require(set(actions) == set(expected_actions), "Polkit action set changed unexpectedly")
for action_id, (path, argv1, allow_active) in expected_actions.items():
    action = actions[action_id]
    annotations = {a.attrib.get("key"): (a.text or "") for a in action.findall("annotate")}
    require(annotations.get("org.freedesktop.policykit.exec.path") == path,
            f"{action_id}: executable path mismatch")
    require(annotations.get("org.freedesktop.policykit.exec.argv1") == argv1,
            f"{action_id}: argv1 policy mismatch")
    defaults = action.find("defaults")
    require(defaults is not None, f"{action_id}: defaults missing")
    require(defaults.findtext("allow_any") == "no", f"{action_id}: allow_any must be no")
    require(defaults.findtext("allow_inactive") == "no", f"{action_id}: allow_inactive must be no")
    require(defaults.findtext("allow_active") == allow_active,
            f"{action_id}: allow_active mismatch")
require("auth_admin_keep" not in read("data/org.kriscc.controlcenter.policy"),
        "Polkit authorization retention is forbidden")

# Backup contract: canonical path validation, safe extraction and all async start failures
# must leave the UI out of the busy state.
for token in (
    "validateBackupPath",
    'canonical.startsWith(backupRoot + QLatin1Char(\'/\'))',
    'QStringLiteral("--no-same-owner")',
    'QStringLiteral("--no-same-permissions")',
    "QProcess::nullDevice()",
    'tr("Impossibile avviare la verifica: %1")',
    'tr("Impossibile avviare il ripristino: %1")',
):
    require(token in system_cpp, f"backup safety invariant missing: {token}")
require(system_cpp.count("&QProcess::errorOccurred") >= 3,
        "create/verify/restore must all handle FailedToStart")
require("setBackupBusy(false);" in system_cpp, "backup failure paths do not clear busy state")

# The Flatpak contract is per-user everywhere, including the external cleanup shortcut.
flatpak_cleanup = re.search(
    r'if \(actionId == QStringLiteral\("flatpak-unused"\)\) \{(.*?)\n    \}',
    system_cpp, re.S)
require(flatpak_cleanup is not None, "flatpak-unused action missing")
require('QStringLiteral("--user")' in flatpak_cleanup.group(1)
        and 'QStringLiteral("--unused")' in flatpak_cleanup.group(1),
        "Flatpak unused cleanup must stay in user scope")

# Navigation should replace a page once, not once from showIndex and again from TabBar.
require("function replaceForIndex(index)" in main_qml, "central page replacement function missing")
require(main_qml.count("pageStack.replace(") == 7,
        "page replacement logic is duplicated outside the central dispatcher")

# Keep the intended minimal scope and immutable KrisOS update contract.
combined_ui = system_qml + recovery_qml + read("qml/modules/DashboardModule.qml")
require(not re.search(r"fwupdmgr|firmware|welcome|first.?run", combined_ui, re.I),
        "firmware/welcome scope leaked into 0.5.1")
require("bootc" in spec and "dnf5" in spec and "tar" in spec,
        "mandatory runtime requirements missing from RPM spec")
require("sudo rk sync" not in recovery_qml, "UI incorrectly claims sudo is used")
require("bootc" in readme.lower() and "rk" in integration_doc,
        "integration documentation lost KrisOS contracts")

print(f"krisCC release audit passed: {VERSION}-{RELEASE}")
