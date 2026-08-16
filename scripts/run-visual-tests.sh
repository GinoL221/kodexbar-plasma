#!/bin/sh

set -eu
# Fail the runner when a capture/compare step in the scenario loop exits non-zero.
set -o pipefail 2>/dev/null || true

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

# Prove palette classification before any capture so ambient desktop theme cannot
# silently satisfy a dark/light probe without the injected Breeze colors.
PYTHONPATH="$visual_dir" python3 - <<'PY' || fail "deterministic Breeze palette classification failed"
from breeze_palette import is_dark_palette, palette_for_theme

light = palette_for_theme("light")
dark = palette_for_theme("dark")
assert not is_dark_palette(light), light
assert is_dark_palette(dark), dark
print("palette-check light=%s/%s dark=%s/%s" % (
    light["backgroundColor"], light["textColor"],
    dark["backgroundColor"], dark["textColor"]))
PY

# Prefer repo artifacts dir when writable; otherwise a private temp tree
# (CI/docker leftovers owned by root must not block local runs).
runtime_dir=$artifacts_dir
if ! mkdir -p "$runtime_dir" 2>/dev/null || ! touch "$runtime_dir/.write-test" 2>/dev/null; then
    runtime_dir=$(mktemp -d "${TMPDIR:-/tmp}/kodexbar-visual.XXXXXX")
    printf 'warning: %s is not writable; using %s\n' "$artifacts_dir" "$runtime_dir" >&2
else
    rm -f "$runtime_dir/.write-test"
fi
trap 'if [ "$runtime_dir" != "$artifacts_dir" ]; then rm -rf "$runtime_dir"; fi' EXIT INT HUP TERM

python3 - "$visual_dir/scenarios.json" <<'PY' | while IFS='|' read -r scenario theme; do
import json
import sys

for item in json.load(open(sys.argv[1], encoding="utf-8"))["scenarios"]:
    print(item["name"] + "|" + item["theme"])
PY
    actual="$runtime_dir/$scenario.png"
    diff="$runtime_dir/$scenario.diff.png"
    golden="$goldens_dir/$scenario.png"
    printf 'Capturing scenario=%s theme=%s\n' "$scenario" "$theme"
    if ! palette_json=$(
        PYTHONPATH="$visual_dir" python3 - "$theme" <<'PY'
import json
import sys
from breeze_palette import is_dark_palette, palette_for_theme

theme = sys.argv[1]
palette = palette_for_theme(theme)
if theme == "dark" and not is_dark_palette(palette):
    raise SystemExit("dark palette classification failed before capture")
if theme == "light" and is_dark_palette(palette):
    raise SystemExit("light palette classification failed before capture")
print(json.dumps(palette, separators=(",", ":")))
PY
    ); then
        fail "failed building injected palette for scenario=$scenario"
    fi
    # Isolated XDG keeps ambient Plasma session config from participating.
    # Theme appearance comes only from --palette-json Breeze inject (not KDE_COLOR_SCHEME).
    scenario_home="$runtime_dir/$scenario.home"
    rm -rf "$scenario_home"
    mkdir -p "$scenario_home/.config" "$scenario_home/.cache" "$scenario_home/.local/share"
    HOME="$scenario_home" \
        XDG_CONFIG_HOME="$scenario_home/.config" \
        XDG_CACHE_HOME="$scenario_home/.cache" \
        XDG_DATA_HOME="$scenario_home/.local/share" \
        QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
        QSG_RENDER_LOOP=basic QT_SCALE_FACTOR=1 QT_FONT_DPI=96 LC_ALL=C.UTF-8 TZ=UTC \
        "$qml6_path" --software -f "$visual_dir/VisualCaptureHarness.qml" -- \
        --scenario "$scenario" --output "$actual" --palette-json "$palette_json" \
        || fail "capture failed for scenario=$scenario theme=$theme; comparison and golden update were skipped"
    if [ "${UPDATE_GOLDENS:-}" = 1 ]; then
        UPDATE_GOLDENS=1 PYTHONPATH="$visual_dir" python3 "$visual_dir/compare_visual.py" \
            --update --expected "$golden" --actual "$actual" --scenario "$scenario" || exit $?
    else
        PYTHONPATH="$visual_dir" python3 "$visual_dir/compare_visual.py" \
            --expected "$golden" --actual "$actual" --diff "$diff" --scenario "$scenario" --theme "$theme" || exit $?
    fi
done
