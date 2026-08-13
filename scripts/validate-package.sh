#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
metadata_path=$repo_root/metadata.json

if [ ! -f "$metadata_path" ]; then
    printf '%s\n' "error: required file metadata.json is missing" >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    printf '%s\n' "error: python3 is required to validate metadata.json" >&2
    exit 1
fi

if ! python3 - "$metadata_path" <<'PY'
import json
import sys

metadata_path = sys.argv[1]
try:
    with open(metadata_path, encoding="utf-8") as metadata_file:
        metadata = json.load(metadata_file)
except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
    print(f"error: metadata.json is not valid UTF-8 JSON: {error}", file=sys.stderr)
    sys.exit(1)

if not isinstance(metadata, dict):
    print("error: metadata.json must contain a JSON object", file=sys.stderr)
    sys.exit(1)

required_fields = {
    "KPackageStructure": "Plasma/Applet",
    "KPlugin.Id": "org.kde.plasma.kodexbar.plasma",
    "KPlugin.Name": None,
    "KPlugin.Description": None,
    "KPlugin.Icon": None,
    "KPlugin.License": None,
    "KPlugin.Version": None,
    "X-Plasma-API-Minimum-Version": None,
}

for field, expected in required_fields.items():
    value = metadata
    for part in field.split("."):
        if not isinstance(value, dict) or part not in value:
            print(f"error: metadata.json is missing required field {field}", file=sys.stderr)
            sys.exit(1)
        value = value[part]
    if not isinstance(value, str) or not value.strip():
        print(f"error: metadata field {field} must be a non-empty string", file=sys.stderr)
        sys.exit(1)
    if expected is not None and value != expected:
        print(f"error: metadata field {field} must be {expected!r}", file=sys.stderr)
        sys.exit(1)
PY
then
    exit 1
fi

for required_path in \
    "$metadata_path" \
    "$repo_root/contents/ui/main.qml" \
    "$repo_root/contents/config/main.xml" \
    "$repo_root/contents/config/config.qml" \
    "$repo_root/contents/icons/codex.svg"; do
    if [ ! -f "$required_path" ]; then
        printf 'error: required package path is missing: %s\n' "${required_path#"$repo_root/"}" >&2
        exit 1
    fi
done

if command -v kpackagetool6 >/dev/null 2>&1; then
    package_root=$(mktemp -d "${TMPDIR:-/tmp}/kodexbar-plasma-package.XXXXXX")
    trap 'rm -rf "$package_root"' EXIT HUP INT TERM
    printf 'Validating package with kpackagetool6 in %s\n' "$package_root"
    if ! kpackagetool6 -t Plasma/Applet --packageroot "$package_root" -i "$repo_root"; then
        printf '%s\n' "error: kpackagetool6 rejected the Plasma package" >&2
        exit 1
    fi
else
    printf '%s\n' "kpackagetool6 not found; skipping isolated package installation"
fi

printf '%s\n' "Package validation passed"
