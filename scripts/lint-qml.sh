#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if qmllint_path=$(command -v qmllint 2>/dev/null); then
    :
elif [ -x /usr/lib/qt6/bin/qmllint ]; then
    qmllint_path=/usr/lib/qt6/bin/qmllint
elif [ -x /usr/lib64/qt6/bin/qmllint ]; then
    qmllint_path=/usr/lib64/qt6/bin/qmllint
else
    printf '%s\n' "error: qmllint was not found in PATH, /usr/lib/qt6/bin/qmllint, or /usr/lib64/qt6/bin/qmllint" >&2
    exit 1
fi

printf 'Using %s (%s)\n' "$qmllint_path" "$($qmllint_path --version)"

cd "$repo_root"
exec "$qmllint_path" \
    --import error \
    --missing-property error \
    --unresolved-alias error \
    --uncreatable-type error \
    --incompatible-type error \
    --required error \
    --read-only-property error \
    contents/ui/*.qml contents/ui/config/*.qml
