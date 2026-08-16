# QML Visual Regression

Deterministic, offscreen pixel checks for the selected-provider popup UI. These checks catch clipping, spacing, icon, and Breeze-style regressions that geometry and accessibility assertions cannot detect on their own.

**Scope boundary:** this suite renders `ProviderRow` directly inside a fixed `450x400` test window. It does not use `main.qml`, `PlasmoidItem`, `plasmawindowed`, or any Plasma containment, and it performs no assistive-technology traversal. Passing visual checks certify offscreen component rendering only — they are **not** live-Plasma certification. Real desktop behavior, theme switching, and accessibility traversal remain the responsibility of [live-plasma-smoke.md](live-plasma-smoke.md) and [ui-parity-checklist.md](ui-parity-checklist.md).

## Fixture contract

`tests/visual/scenarios.json` is the canonical manifest. It declares a fixed `450x400` window, `Noto Sans`, and exactly four scenarios: Breeze Light/Dark, each with Cost present/absent. `tests/visual/fixture_contract.py` validates the manifest before any capture runs and rejects fixture drift, unknown or duplicate scenarios, and extra/missing baselines.

Baselines live under `tests/visual/goldens/` and are named exactly:

- `breeze-light-cost-present.png`
- `breeze-light-cost-absent.png`
- `breeze-dark-cost-present.png`
- `breeze-dark-cost-absent.png`

## Running the suite

```sh
./scripts/run-visual-tests.sh
```

The runner is independent of `./scripts/run-qml-tests.sh` and fails before capture if any dependency is missing:

- `qml6` (Qt 6 declarative runtime)
- `python3` and Pillow
- `fc-match`, resolving exactly `Noto Sans`
- `/usr/share/color-schemes/BreezeLight.colors` and `BreezeDark.colors`

Missing Pillow or another visual dependency never affects `./scripts/run-qml-tests.sh` — the behavioral suite stays fully independent.

Each scenario runs in its own `qml6` process with `QT_QPA_PLATFORM=offscreen`, `QT_QUICK_BACKEND=software`, `QSG_RENDER_LOOP=basic`, `QT_SCALE_FACTOR=1`, `QT_FONT_DPI=96`, `LC_ALL=C.UTF-8`, and `TZ=UTC`, under an **isolated** `HOME` / `XDG_*` tree so the live Plasma desktop theme cannot leak in.

**Theme determinism:** the suite does **not** use `KDE_COLOR_SCHEME` (that variable does nothing for KF6/Kirigami). It also does not rely on `QT_QPA_PLATFORMTHEME=kde` to force Light/Dark offscreen — on headless hosts that path produced a broken black-on-black palette. Instead:

1. `tests/visual/breeze_palette.py` parses `/usr/share/color-schemes/BreezeLight.colors` or `BreezeDark.colors`.
2. The runner builds a compact JSON palette and passes it inline as `--palette-json '{...}'`. Hex channels are stored **without** a leading `#` so `qml6` argv/URL handling cannot treat them as fragments.
3. The harness restores the `#` prefix, sets `Kirigami.Theme.inherit: false`, and injects Window/Selection colors from that payload.
4. A luminance probe still fails the scenario if the effective theme does not match light/dark.

If the scheme files are missing, the palette cannot be classified, or injection fails, the scenario fails **before** capture.

## Comparison and threshold

`tests/visual/compare_visual.py` decodes both images as RGBA and compares pixels, never raw bytes or file hashes. A pixel mismatches when any decoded RGBA channel delta exceeds **8**. A scenario passes when the mismatch ratio is **<= 0.001**. These values were calibrated against five clean repeat captures per scenario, all reporting `0/180000` mismatches; changing them requires review, never auto-tuning.

On failure the comparator reports: expected/actual paths, an available diff image, scenario and theme, mismatched/total pixel counts, the ratio, the threshold, and the maximum observed delta.

Normal runs never write into `tests/visual/goldens/`. They write only to `tests/visual/artifacts/`, which is `.gitignore`d.

## Updating goldens

Goldens only change through an explicit, reviewed update. **CI is the pixel authority:** regenerate baselines inside the same Docker image the workflow uses, so host font/Qt AA drift does not fight GHA.

```sh
# Preferred (matches CI image rendering)
docker build -f ci/visual-regression.Dockerfile -t kodexbar-visual-local:test .
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -e UPDATE_GOLDENS=1 \
  --volume "$PWD:/workspace" --workdir /workspace \
  kodexbar-visual-local:test ./scripts/run-visual-tests.sh

# Host-only update (may diverge from CI; avoid unless you intentionally change the authority)
UPDATE_GOLDENS=1 ./scripts/run-visual-tests.sh
```

Update mode still validates the manifest and requires a successful canonical capture first; it replaces only that scenario's golden, atomically, and reports the replacement. There is no implicit or automatic baseline mutation.

Local host runs of `./scripts/run-visual-tests.sh` can still **capture and classify Light/Dark** correctly (theme inject is deterministic). Pixel compare against repo goldens may fail on a non-CI host even when theme force is healthy — use the Docker command above to match CI.

## Limits

- Four scenarios only: Breeze Light/Dark x Cost present/absent. No other theme, size, or provider state is covered.
- No live Plasma, no `PlasmoidItem`, no assistive-technology traversal, no `plasmawindowed` automation.
- Threshold and goldens are Qt/Breeze/font/DPI-sensitive; unrelated environment changes can require a reviewed recalibration, not a routine update.
- CI visual results (if enabled) are informational only and never gate merging — see [Continuous integration](#continuous-integration) below.

## Continuous integration

`.github/workflows/visual-regression.yml` runs the `visual-regression` job with `continue-on-error: true`, building or pulling a dedicated Tumbleweed-based image (`ci/visual-regression.Dockerfile`) with the same dependencies as above, and running `./scripts/run-visual-tests.sh` inside it. It reports pass/fail visibly but never blocks a merge. Behavioral coverage (`./scripts/run-qml-tests.sh`) remains the only required, blocking check, and is unaffected by this job or its image.

## Related documentation

- [live-plasma-smoke.md](live-plasma-smoke.md) — manual real-Plasma keyboard, theme, and lifecycle checklist; the actual live-Plasma authority.
- [ui-parity-checklist.md](ui-parity-checklist.md) — manual structural/craft parity checklist and sign-off.
