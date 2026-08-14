#!/usr/bin/env python3
"""Fail closed unless qmllint warnings are exact KDE translation identifiers."""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def fail(message):
    raise ValueError(message)


def qtpaths_query(key):
    qtpaths = shutil.which("qtpaths6")
    if not qtpaths:
        return None
    result = subprocess.run([qtpaths, "--query", key], capture_output=True, text=True)
    value = result.stdout.strip()
    return value if result.returncode == 0 and value else None


def environment_value(env, name):
    value = env.get(name)
    if not value:
        return None
    paths = value.split(os.pathsep) if name == "QML_IMPORT_PATH" else [value]
    for value in paths:
        path = Path(value)
        if not path.is_dir() if name != "QMLLINT_BIN" else not path.is_file() or not os.access(path, os.X_OK):
            fail("invalid %s override: %s" % (name, value))
    return paths if len(paths) > 1 else paths[0]


def resolve_environment(env):
    binary = environment_value(env, "QMLLINT_BIN")
    if binary is None:
        binary = shutil.which("qmllint")
        if binary is None:
            binaries = [Path(qtpaths_query("QT_INSTALL_BINS") or "") / "qmllint"]
            binaries += (
                Path("/usr/lib/qt6/bin/qmllint"), Path("/usr/lib64/qt6/bin/qmllint"))
            binary = next((str(path) for path in binaries if path.is_file() and os.access(path, os.X_OK)), None)
    if binary is None:
        fail("qmllint was not found")
    root = environment_value(env, "QML_IMPORT_ROOT")
    if root is None:
        roots = [qtpaths_query("QT_INSTALL_QML"), "/usr/lib/qt6/qml", "/usr/lib64/qt6/qml"]
        root = next((value for value in roots if value and Path(value).is_dir()), None)
    import_path = environment_value(env, "QML_IMPORT_PATH")
    return str(binary), root, import_path


def targets(root):
    ui = root / "contents/ui"
    files = []
    try:
        files = sorted(path for path in ui.rglob("*.qml") if path.is_file())
    except OSError as error:
        fail("cannot enumerate QML files: %s" % error)
    if not files:
        fail("no QML files under contents/ui")
    for path in files:
        try:
            path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as error:
            fail("unreadable UTF-8 QML file %s: %s" % (path, error))
    return files


def source_span(source, offset, length):
    boundaries = [0]
    for char in source:
        boundaries.append(boundaries[-1] + (2 if ord(char) > 0xffff else 1))
    end = offset + length
    if offset < 0 or length < 0 or offset not in boundaries or end not in boundaries:
        fail("invalid UTF-16 source span")
    return source[boundaries.index(offset):boundaries.index(end)]


def validate_report(root, report):
    if not isinstance(report, dict) or isinstance(report.get("revision"), bool) or not isinstance(report.get("revision"), int):
        fail("qmllint report requires integer revision")
    if not isinstance(report.get("files"), list):
        fail("qmllint report requires files array")
    expected = {path.resolve() for path in targets(root)}
    seen, accepted = set(), 0
    for record in report["files"]:
        if not isinstance(record, dict) or not isinstance(record.get("filename"), str) or not isinstance(record.get("warnings"), list) or not isinstance(record.get("success"), bool):
            fail("malformed qmllint file record")
        path = Path(record["filename"])
        path = (path if path.is_absolute() else root / path).resolve()
        if path not in expected or path in seen:
            fail("qmllint file mapping is not one-to-one")
        seen.add(path)
        source = path.read_text(encoding="utf-8")
        if not record["success"] and not record["warnings"]:
            fail("unsuccessful qmllint file has no warning")
        for warning in record["warnings"]:
            keys = ("line", "column", "charOffset", "length")
            if not isinstance(warning, dict) or not isinstance(warning.get("id"), str) or any(isinstance(warning.get(key), bool) or not isinstance(warning.get(key), int) for key in keys):
                fail("malformed qmllint warning")
            offset, length = warning["charOffset"], warning["length"]
            index = source_span_index(source, offset)
            line = source.count("\n", 0, index) + 1
            column = utf16_length(source[source.rfind("\n", 0, index) + 1:index]) + 1
            if warning["line"] != line or warning["column"] != column or warning["id"] != "unqualified" or source_span(source, offset, length) not in {"i18n", "i18np"}:
                fail("unaccepted qmllint diagnostic")
            accepted += 1
    if seen != expected:
        fail("qmllint report is missing or contains extra files")
    return accepted


def utf16_length(value):
    return len(value.encode("utf-16-le")) // 2


def source_span_index(source, offset):
    total = 0
    for index, char in enumerate(source):
        if total == offset:
            return index
        total += 2 if ord(char) > 0xffff else 1
    if total == offset:
        return len(source)
    fail("invalid UTF-16 source span")


def main():
    parser = argparse.ArgumentParser(
        description=("Overrides: QMLLINT_BIN selects the executable; "
                     "QML_IMPORT_ROOT adds -I; QML_IMPORT_PATH enables -E."))
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).parents[1])
    args = parser.parse_args()
    root = args.repo_root.resolve()
    binary, import_root, import_path = resolve_environment(os.environ)
    command = [binary, "--json", "-", "--max-warnings", "-1"]
    if import_root:
        command += ["-I", import_root]
    if import_path:
        command += ["-E"]
    command += [str(path) for path in targets(root)]
    result = subprocess.run(command, cwd=root, capture_output=True, text=True)
    if result.returncode:
        fail("qmllint exited %s: %s" % (result.returncode, result.stderr.strip()))
    accepted = 0
    try:
        accepted = validate_report(root, json.loads(result.stdout))
    except json.JSONDecodeError as error:
        fail("invalid qmllint JSON: %s" % error)
    print("Accepted %d exact KDE translation warning(s)." % accepted)


if __name__ == "__main__":
    try:
        main()
    except ValueError as error:
        print("error: %s" % error, file=sys.stderr)
        sys.exit(1)
