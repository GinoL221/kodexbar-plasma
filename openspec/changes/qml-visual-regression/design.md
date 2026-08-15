# Design: QML Visual Regression

## Technical Approach

Add a test-only `450x400` `QQC2.ApplicationWindow` hosting the existing `ProviderRow`; normal composition supplies `ProviderHeader`, usage rows, and optional `CostSection` without `main.qml` or `PlasmoidItem`. Fixed data drives Cost-present/absent states. Behavioral harnesses remain authoritative; visual checks certify only offscreen component rendering.

## Architecture Decisions

| Option | Tradeoff | Decision and rationale |
|---|---|---|
| Direct row vs applet shell | Omits containment but avoids unavailable Plasma context | Direct fixture; production QML stays unchanged and scope stays honest. |
| Fresh process vs theme switching | More startup cost, no stale theme cache | Use `KDE_COLOR_SCHEME` per scenario; fail if its palette probe disagrees. |
| PNG hash vs decoded pixels | More comparator code, tolerates harmless encoding differences | Pillow decodes RGBA; stdlib iteration computes deltas and reports actionable metrics. |
| Implicit updates vs explicit replacement | Slower review, prevents accidental mutation | Only exact `UPDATE_GOLDENS=1` enables atomic replacement of validated canonical files. |

## Data Flow

```text
scenarios.json -> runner -> fresh QML process -> geometry/a11y checks
                                              -> grabToImage callback -> actual PNG
golden PNG + actual PNG -> RGBA comparator -> pass or summary + diff PNG
```

## File Changes

| File | Action | Description |
|---|---|---|
| `tests/ProviderRowHarness.qml` | Modify | Add two-state bounds, clipping, and accessible-name checks. |
| `tests/ProviderDetailsIntegrationTest.qml` | Modify | Assert selected-row geometry/accessibility. |
| `tests/visual/VisualCaptureHarness.qml` | Create | Fixed row, theme probe, preconditions, async capture. |
| `tests/visual/scenarios.json` | Create | Canonical dimensions and four-scenario manifest. |
| `tests/visual/compare_visual.py`, `tests/visual/test_compare_visual.py` | Create | Pillow/stdlib comparator and safety tests. |
| `tests/visual/goldens/*.png` | Create | Four reviewed baselines. |
| `scripts/run-visual-tests.sh` | Create | Independent dependency, capture, compare/update orchestration. |
| `.gitignore` | Modify | Ignore `tests/visual/artifacts/`. |
| `docs/visual-regression.md` | Create | Workflow, calibration, scope, dependencies, and artifacts. |
| `docs/live-plasma-smoke.md`, `docs/ui-parity-checklist.md` | Modify | Cross-link visual coverage and retain live/manual authority. |
| `.github/workflows/visual-regression.yml` | Create, optional | Separate `continue-on-error` job after repeatability. |

## Interfaces / Contracts

Baselines are exactly `breeze-light-cost-present.png`, `breeze-light-cost-absent.png`, `breeze-dark-cost-present.png`, and `breeze-dark-cost-absent.png` under `tests/visual/goldens/`. Manifest validation rejects unknown/duplicate scenarios, extra/missing baselines, non-PNG/RGBA images, or non-`450x400` dimensions before capture/update.

The runner requires `qml6`, `python3`, Pillow, `fc-match`, exact `Noto Sans`, and both Breeze schemes; missing dependencies fail before capture with guidance, without installation or sudo. Processes set `QT_QPA_PLATFORM=offscreen`, `QT_QUICK_BACKEND=software`, `QSG_RENDER_LOOP=basic`, `QT_SCALE_FACTOR=1`, `QT_FONT_DPI=96`, `LC_ALL=C.UTF-8`, and `TZ=UTC`; the window fixes Noto Sans pixel size. Separate Light/Dark processes use `/usr/share/color-schemes/BreezeLight.colors` or `BreezeDark.colors`.

Capture states are `precondition -> capturing -> saved -> complete`. False `grabToImage`, absent callback result, failed `saveToFile`, wrong size, or a 5-second timeout exits nonzero and forbids comparison/update. Normal mode writes only artifacts. Update mode validates scenario/capture, then atomically replaces and reports only its canonical golden.

RGBA pixels mismatch when any channel delta exceeds `8`; pass requires ratio `<= 0.001`. Calibration uses five clean repeats per scenario plus seeded pixel, color, and geometry perturbations; clean runs pass and perturbations fail. Threshold changes require review, never auto-tuning. Failures print expected/actual/diff paths, scenario/theme, mismatched/total pixels, ratio, threshold, and maximum delta.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit | Threshold, malformed/missing baselines, canonical updates, no normal mutation | `unittest` with temporary Pillow images. |
| Integration | Cost states, geometry/a11y, capture failures, four themes | QML harness plus shell negative fixtures. |
| Live | Real applet/theme/accessibility confidence | Manual `docs/live-plasma-smoke.md` and `docs/ui-parity-checklist.md`; never inferred from goldens. |

## Threat Matrix

| Boundary | Applicability | Safe/failure behavior | Planned RED tests |
|---|---|---|---|
| Documentation-like paths | N/A: fixed QML/Python entrypoints; no executable classification | Unknown manifest paths are rejected | None |
| Git repository selection | N/A: no Git invocation | Repository root derives from script location | None |
| Commit state | N/A: no commit operation | No index access | None |
| Push state | N/A: no push operation | No remote access | None |
| PR commands | N/A: workflow runs a fixed script only | No command composition | None |

| Visual risk | Required response / RED evidence |
|---|---|
| Nondeterminism | Fixed environment; five-repeat calibration must expose drift. |
| Missing/stale goldens | Canonical manifest/dimension validation; missing baseline fails without creation. |
| Dependency drift | Preflight versions/font/theme and print them in artifacts; unsupported state fails early. |
| False live-Plasma confidence | Docs explicitly link `docs/live-plasma-smoke.md` and `docs/ui-parity-checklist.md` and prohibit certification claims. |

## Migration / Rollout

No runtime migration. Authored work likely exceeds 400 lines, so chained PRs are recommended: (1) preconditions/fixture, (2) capture/comparator/runner/goldens, (3) docs/optional CI. Keep each below 400 authored lines. `ask-on-risk` requires approval of this stacked-to-main split; generated PNGs are excluded.

## Open Questions

None.
