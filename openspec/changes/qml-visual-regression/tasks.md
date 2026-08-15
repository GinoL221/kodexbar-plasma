# Tasks: QML Visual Regression

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimate | 650–800 (goldens excluded) |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 → PR 2 → PR 3 |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Preconditions and fixture | PR 1 → main | `./scripts/run-qml-tests.sh` | Offscreen Cost states | Harness and manifest only |
| 2 | Capture, compare, update, goldens | PR 2 → main after PR 1 | `python3 -m unittest tests/visual/test_compare_visual.py` | Four-scenario visual runner | `tests/visual/`, runner, ignore entry |
| 3 | Document and expose check | PR 3 → main after PR 2 | `./scripts/run-visual-tests.sh` | Four-scenario runner; CI reports | Docs and optional workflow only |

## Phase 1: Preconditions and Fixture (PR 1)

- [x] 1.1 RED: Add Cost-present/absent bounds, clipping, and accessible-name/role assertions to `tests/ProviderRowHarness.qml` and `tests/ProviderDetailsIntegrationTest.qml`; prove `./scripts/run-qml-tests.sh`.
- [x] 1.2 GREEN: Make those geometry/accessibility assertions pass using selected-provider composition; do not alter production QML or the CLI boundary.
- [x] 1.3 RED: Create `tests/visual/scenarios.json` validation tests for exactly four `450x400` Light/Dark × Cost states and reject fixture drift, unknown/duplicate scenarios, and extra/missing baselines before capture.
- [x] 1.4 GREEN: Add `tests/visual/VisualCaptureHarness.qml` with fixed data, Noto Sans, palette probe, environment, and precondition gate; theme mismatch names scenario/theme and skips capture.

## Phase 2: Capture and Golden Safety (PR 2)

- [x] 2.1 RED: Add QML negative cases for false `grabToImage`, absent callback, failed save, wrong size, and five-second timeout; they prevent comparison and `UPDATE_GOLDENS=1` updates.
- [x] 2.2 GREEN: Implement `VisualCaptureHarness.qml` states `precondition → capturing → saved → complete` and asynchronous `grabToImage` artifact output.
- [x] 2.3 RED: Create `tests/visual/test_compare_visual.py` cases for RGBA threshold/ratio, malformed or dimension-mismatched baseline, missing baseline without mutation, canonical-only atomic update, and seeded pixel/color/geometry drift.
- [x] 2.4 GREEN: Implement `tests/visual/compare_visual.py` with Pillow decode and stdlib deltas; calibrate five repeats to delta `8` and ratio `<=0.001`, reporting paths, counts, ratio, threshold, max delta, scenario/theme, and diff.
- [x] 2.5 Add four reviewed `tests/visual/goldens/breeze-*-cost-*.png` only after successful canonical captures; normal runs write `tests/visual/artifacts/`, ignored by `.gitignore`.
- [x] 2.6 Create `scripts/run-visual-tests.sh` preflight for qml6, Python/Pillow, exact Noto Sans, and Breeze; fail early with versions/guidance, no sudo, and keep `scripts/run-qml-tests.sh` independent.

## Phase 3: Boundaries and Exposure (PR 3)

- [x] 3.1 Write `docs/visual-regression.md` covering fixture contract, calibration, explicit `UPDATE_GOLDENS=1`, artifacts, dependencies, and no automatic updates.
- [x] 3.2 Link `docs/live-plasma-smoke.md` and `docs/ui-parity-checklist.md`; RED review check: docs must not claim production changes, `PlasmoidItem`, AT traversal, `plasmawindowed`, or live-Plasma certification.
- [x] 3.3 Add optional `.github/workflows/visual-regression.yml` with visible `continue-on-error` results only after repeatability; verify a visual failure cannot gate merge.
- [x] 3.4 Run `./scripts/run-qml-tests.sh` and `./scripts/run-visual-tests.sh`; record four-scenario results and retain Light/Dark live-smoke authority.
