#!/bin/sh

set -eu

script_dir=${0%/*}
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
visual_dir="$repo_root/tests/visual"
artifacts_dir="$visual_dir/artifacts"
goldens_dir="$visual_dir/goldens"

fail() {
    printf '%s\n' "error: $*" >&2
    exit 1
}

qml6_path=$(command -v qml6 2>/dev/null || true)
[ -n "$qml6_path" ] || fail "qml6 is required; install the Qt 6 declarative runtime before running visual checks"
command -v python3 >/dev/null 2>&1 || fail "python3 is required for visual checks"
command -v fc-match >/dev/null 2>&1 || fail "fc-match is required to validate the Noto Sans fixture font"
python3 -c 'import PIL; print("Pillow", PIL.__version__)' || fail "Pillow is required; install it through the system Python environment"

font_family=$(fc-match -f '%{family}\n' 'Noto Sans' | { IFS= read -r line || true; printf '%s' "$line"; })
[ "$font_family" = "Noto Sans" ] || fail "exact Noto Sans is required; fc-match resolved: ${font_family:-none}"
[ -r /usr/share/color-schemes/BreezeLight.colors ] || fail "BreezeLight.colors is required at /usr/share/color-schemes/BreezeLight.colors"
[ -r /usr/share/color-schemes/BreezeDark.colors ] || fail "BreezeDark.colors is required at /usr/share/color-schemes/BreezeDark.colors"

printf 'Visual environment: qml6=%s font=%s\n' "$($qml6_path --version 2>&1)" "$font_family"
PYTHONPATH="$visual_dir" python3 -c 'from fixture_contract import validate_manifest; import sys; validate_manifest(sys.argv[1])' "$visual_dir/scenarios.json" \
    2>/dev/null || fail "canonical visual manifest validation failed"

mkdir -p "$artifacts_dir"

python3 - "$visual_dir/scenarios.json" <<'PY' | while IFS='|' read -r scenario theme; do
import json
import sys

for item in json.load(open(sys.argv[1], encoding="utf-8"))["scenarios"]:
    print(item["name"] + "|" + item["theme"])
PY
    [ "$theme" = light ] && scheme=/usr/share/color-schemes/BreezeLight.colors || scheme=/usr/share/color-schemes/BreezeDark.colors
    actual="$artifacts_dir/$scenario.png"
    diff="$artifacts_dir/$scenario.diff.png"
    golden="$goldens_dir/$scenario.png"
    printf 'Capturing scenario=%s theme=%s\n' "$scenario" "$theme"
    if [ "$theme" = dark ]; then
        KDE_COLOR_SCHEME="$scheme" QT_QPA_PLATFORMTHEME=kde QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
            QSG_RENDER_LOOP=basic QT_SCALE_FACTOR=1 QT_FONT_DPI=96 LC_ALL=C.UTF-8 TZ=UTC \
            "$qml6_path" --software -f "$visual_dir/VisualCaptureHarness.qml" -- \
            --scenario "$scenario" --output "$actual" || fail "capture failed for scenario=$scenario theme=$theme; comparison and golden update were skipped"
    else
        KDE_COLOR_SCHEME="$scheme" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
            QSG_RENDER_LOOP=basic QT_SCALE_FACTOR=1 QT_FONT_DPI=96 LC_ALL=C.UTF-8 TZ=UTC \
            "$qml6_path" --software -f "$visual_dir/VisualCaptureHarness.qml" -- \
            --scenario "$scenario" --output "$actual" || fail "capture failed for scenario=$scenario theme=$theme; comparison and golden update were skipped"
    fi
    if [ "${UPDATE_GOLDENS:-}" = 1 ]; then
        UPDATE_GOLDENS=1 PYTHONPATH="$visual_dir" python3 "$visual_dir/compare_visual.py" \
            --update --expected "$golden" --actual "$actual" --scenario "$scenario" || exit $?
    else
        PYTHONPATH="$visual_dir" python3 "$visual_dir/compare_visual.py" \
            --expected "$golden" --actual "$actual" --diff "$diff" --scenario "$scenario" --theme "$theme" || exit $?
    fi
done
