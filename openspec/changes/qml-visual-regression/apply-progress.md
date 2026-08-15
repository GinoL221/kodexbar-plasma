# Apply Progress: QML Visual Regression

## Delivery

- Completed work units: `geometry-fixture` (PR 1 of 3), `capture-goldens` (PR 2 of 3), `docs-ci` (PR 3 of 3)
- Mode: Strict TDD
- Delivery strategy: `ask-on-risk`, resolved as `stacked-to-main`
- Current boundary: asynchronous capture, RGBA comparison, explicit golden replacement, four canonical goldens, and an isolated visual runner.
- Excluded: documentation, cross-links, CI workflow, live-Plasma claims, production QML, and CLI changes.

## Completed Tasks

- [x] 1.1 Cost-present/absent bounds, clipping, and accessibility assertions.
- [x] 1.2 Selected-provider composition makes the assertions pass without production-QML or CLI changes.
- [x] 1.3 Canonical scenario manifest validation and pre-capture rejection tests.
- [x] 1.4 Fixed `450x400` Breeze-aware, non-capturing `VisualCaptureHarness.qml`.
- [x] 2.1 Capture-failure RED tests cover request failure, absent callback, failed save, wrong size, and timeout without artifacts.
- [x] 2.2 Async `grabToImage` advances `precondition → capturing → saved → complete` and writes an artifact only on success.
- [x] 2.3 Comparator RED tests cover threshold/ratio, malformed and dimension-mismatched inputs, missing baselines, canonical updates, and seeded drift.
- [x] 2.4 Pillow/stdlib RGBA comparator reports actionable mismatch diagnostics with delta `8` and ratio `<= 0.001`.
- [x] 2.5 Four canonical Breeze × Cost goldens were generated after valid captures; artifacts are ignored.
- [x] 2.6 Independent visual runner validates dependencies and runs isolated capture/compare or explicit update.
- [x] 3.1 `docs/visual-regression.md` documents the fixture contract, calibration, `UPDATE_GOLDENS=1`, artifacts, dependencies, and limits.
- [x] 3.2 `docs/live-plasma-smoke.md` and `docs/ui-parity-checklist.md` cross-link `visual-regression.md`; no doc claims production changes, `PlasmoidItem`, AT traversal, `plasmawindowed`, or live-Plasma certification.
- [x] 3.3 `.github/workflows/visual-regression.yml` runs a job-level `continue-on-error: true` visual job in a dedicated `ci/visual-regression.Dockerfile` image; behavioral CI (`ci.yml`) is untouched and remains the only required gate.
- [x] 3.4 `./scripts/run-qml-tests.sh` and `./scripts/run-visual-tests.sh` both re-run exit 0; four-scenario results recorded below.

## TDD Cycle Evidence

| Task | Test file | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 1.1 | `tests/ProviderRowHarness.qml`, `tests/ProviderDetailsIntegrationTest.qml` | Integration | `./scripts/run-qml-tests.sh` exit 0 before edits | Bounds assertion failed in the initial loose `160`-wide row composition during the first full run | `450`-wide selected-provider composition passes both Cost states | Cost present and absent; Breeze Light and Dark | Added row-relative bound helper; focused and full suite pass |
| 1.2 | same | Integration | covered by 1.1 safety net | Assertions authored before final fixture composition | Existing production `ProviderRow` passes with test-only selected composition | Cost visible/hidden plus semantic names and bounds | No production refactor; runtime boundary unchanged |
| 1.3 | `tests/visual/test_fixture_contract.py` | Unit | N/A (new) | Initial import failed; added baseline-name test then failed before validation | 5/5 manifest tests pass | Canonical matrix, fixture drift, duplicate/unknown, missing scenario, extra/missing baselines | Canonical names are derived from one scenario tuple |
| 1.4 | `tests/visual/VisualCaptureHarness.qml` | Integration | N/A (new) | Harness contract tests were written before the harness; invalid scenario exits nonzero | Four Breeze × Cost precondition runs exit 0 | Cost present/absent under each Breeze scheme | Kept it non-capturing; capture state belongs to PR 2 |
| 2.1 | `tests/visual/test_capture_harness.py` | Integration | Four pre-capture fixture scenarios ran before capture changes | 4 failure-mode tests failed because the pre-PR2 harness ignored the new flags and exited 0 | 4/4 failure modes exit nonzero and leave no artifact | False request, ignored callback/timeout, failed save, and wrong-size request | Kept capture state and failure exits local to the visual harness |
| 2.2 | `tests/visual/test_capture_harness.py` | Integration | covered by 2.1 | Paired 2.1 failure tests existed before the async state-machine implementation | Successful direct capture writes a `450x400` PNG; 4 failure tests remain green | Light/Dark × Cost runner scenarios and five clean repeats | Captures only `fixtureViewport`; no production UI change |
| 2.3 | `tests/visual/test_compare_visual.py` | Unit | N/A (new) | Import failed before `compare_visual.py` existed | 9/9 tests pass | Equal, boundary delta, ratio limit, seeded pixel/color/geometry drift, malformed, missing, and update cases | Extracted reusable decode, compare, and atomic-update functions |
| 2.4 | `tests/visual/test_compare_visual.py` | Unit | covered by 2.3 | Tests specified constants and diagnostics before implementation | 9/9 tests pass | Five clean runner repeats report 0 mismatches for all four scenarios | Constants make reviewed threshold changes explicit |
| 2.5 | `tests/visual/test_compare_visual.py` | Integration | comparator suite green before generation | Missing-baseline test proves normal mode cannot create a golden | `UPDATE_GOLDENS=1` generated 4/4 canonical files; normal mode then passed | Light/Dark × Cost, present/absent, and five clean repeats | Goldens are isolated under `tests/visual/goldens/` |
| 2.6 | `tests/visual/test_visual_runner.py` | Integration | N/A (new) | Runner test failed because the script did not exist | Missing-`qml6` preflight exits nonzero before capture; runner passes all four scenarios | Five clean four-scenario runs use the same fixed environment | Runner remains independent of `scripts/run-qml-tests.sh` |

## Work Unit Evidence

| Evidence | Result |
|---|---|
| Focused test command and exact result | `python3 -m unittest tests/visual/test_fixture_contract.py` — exit 0, 5 tests passed; direct QML integration ran 12 tests under each Breeze scheme; `ProviderRowHarness.qml` exit 0. |
| Runtime harness command/scenario and exact result | `qml6 --software -f tests/visual/VisualCaptureHarness.qml -- --scenario <canonical scenario>` with deterministic offscreen variables — 4/4 canonical Breeze × Cost scenarios exit 0; unsupported scenario exits nonzero and reports `unknown scenario`. |
| Required applicable gates | `./scripts/run-qml-tests.sh` exit 0; `./scripts/lint-qml.sh` exit 0 with 68 accepted existing KDE translation warnings; `git diff --check` exit 0. |
| Rollback boundary | Revert `tests/ProviderRowHarness.qml`, `tests/ProviderDetailsIntegrationTest.qml`, and `tests/visual/`; production QML, CLI invocation, runners, goldens, and CI remain untouched. |

## PR 2 Work Unit Evidence

| Evidence | Result |
|---|---|
| Focused test command and exact result | `python3 -m unittest tests/visual/test_capture_harness.py tests/visual/test_compare_visual.py tests/visual/test_visual_runner.py` — exit 0, 14 tests passed. |
| Runtime harness command/scenario and exact result | `./scripts/run-visual-tests.sh` — exit 0; all four canonical scenarios passed at `0/180000` mismatches. Four additional clean full runs yielded five clean repetitions per scenario, all at `0/180000`. |
| Required applicable gates | `./scripts/run-qml-tests.sh` exit 0; `./scripts/lint-qml.sh` exit 0 with 68 accepted existing KDE translation warnings; `git diff --check` and `sh -n scripts/run-visual-tests.sh` exit 0. |
| Environment assumptions | Qt/QML 6.11.1, Pillow 12.3.0, exact Noto Sans, Breeze schemes under `/usr/share/color-schemes`, offscreen/software/basic rendering, scale 1, 96 DPI, `C.UTF-8`, UTC; Dark capture additionally needs `QT_QPA_PLATFORMTHEME=kde` for its palette probe. |
| Rollback boundary | Revert `tests/visual/`, `scripts/run-visual-tests.sh`, and the `.gitignore` visual-artifact entry; PR1 geometry/a11y tests and all production/runtime/CLI code remain intact. |

## Threshold and Golden Evidence

- Pixel mismatch: any decoded RGBA channel delta `> 8`.
- Acceptance: mismatch ratio `<= 0.001`; five clean runs per canonical scenario reported `0.000000`.
- Generated baselines: `breeze-light-cost-present.png`, `breeze-light-cost-absent.png`, `breeze-dark-cost-present.png`, and `breeze-dark-cost-absent.png`.
- Normal runs only write ignored artifacts. Replacement is atomic, canonical-only, and requires exact `UPDATE_GOLDENS=1`.

## PR 3 Work Unit Evidence

| Evidence | Result |
|---|---|
| Focused/behavioral gate | `./scripts/run-qml-tests.sh` — exit 0, all harnesses pass (unchanged from PR1/PR2). |
| Visual runtime harness | `./scripts/run-visual-tests.sh` — exit 0; all four canonical scenarios `mismatched=0/180000 ratio=0.000000 threshold=8 maximum_delta=0`. |
| Required applicable gates | `./scripts/lint-qml.sh` exit 0; `git diff --check` exit 0; `python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/visual-regression.yml"))'` exit 0; `sh -n scripts/run-visual-tests.sh` exit 0. |
| Files added | `docs/visual-regression.md`, `ci/visual-regression.Dockerfile`, `.github/workflows/visual-regression.yml`. |
| Files modified | `docs/live-plasma-smoke.md` (+2 lines), `docs/ui-parity-checklist.md` (+2 lines). |
| Line count vs 400-line budget | ~148 authored lines; well within budget. |
| Rollback boundary | Revert `docs/visual-regression.md`, the two doc cross-link insertions, `ci/visual-regression.Dockerfile`, and `.github/workflows/visual-regression.yml`; `ci.yml` (behavioral/lint CI) is untouched. |

### CI job verification limit (disclosed, not silently assumed)

`ci/visual-regression.Dockerfile` mirrors `ci/qml-lint.Dockerfile`'s already-working openSUSE Tumbleweed base (same `kf6-kirigami-imports`/`libplasma6-components`/`qt6-declarative-tools` set, so `org.kde.kirigami` resolves the same way it does for the existing `qmllint6` CI job) and adds `python3-Pillow`, `noto-sans-fonts`, and `fontconfig`, all confirmed to exist on Tumbleweed. The Breeze color-scheme package (`breeze6`, providing `/usr/share/color-schemes/Breeze{Light,Dark}.colors`) is a **best-effort, unverified guess** — no available tool could run `zypper wp`/`zypper search` against a live Tumbleweed repo from this session. This was surfaced to the user before implementation (two `AskUserQuestion` rounds); they explicitly chose "best effort" over the always-reliable comparator-only CI alternative. The job runs with job-level `continue-on-error: true`, so a wrong package name fails visibly in the workflow log without blocking any merge — per spec (`CI and Documentation Boundaries` requirement), this is within contract. Confirming/correcting the exact package name requires a real GitHub Actions run, which is out of reach from this session.

Separately, Ubuntu's `ubuntu-latest` apt repos were checked and ruled out for this job: `noble` only ships `qml-module-org-kde-kirigami2` (KF5/Qt5), not a Qt6/KF6 Kirigami QML module, so a plain-apt Ubuntu pipeline would fail to import `org.kde.kirigami` in `VisualCaptureHarness.qml`.

## Native Attempt Settlement

- Acquire token reused: `sha256:43f918bdeef3f0b3b7c9f8ab84180bc11da0a457b1b244cb8017accea2656682`
- Settle request ID: `settle-qml-visual-regression-pr1-20260815`
- Outcome: `passed`; native state: `complete`
- Acquire token reused: `sha256:a7c76a86b64103a13222f14042a418359b27530bb4dad302b6c4bdf52b6a53e8`
- Settle request ID: `settle-qml-visual-regression-pr2-20260815`
- Outcome: `passed`; native state: `complete`; evidence revision: `sha256:b85c078b3b1f3526c07fa8baed937ba75babf36c828b2704bf1424903747d965`
- Acquire token reused: `sha256:ff0e0839a74fa70ad89efd163649287e140295cf1c5deba81b5af86a8cb99bff`
- Settle request ID: `settle-qml-visual-regression-pr3-20260815`
- Outcome: `passed`; native state: `complete`; evidence revision: `sha256:715b306f3ac19702a74fb208f3067cec62c550919e8705fe8b1204980e5e8b34`

## Remaining Slices

None. All three work units (PR1 `geometry-fixture`, PR2 `capture-goldens`, PR3 `docs-ci`) are implemented. The change is ready for a completeness/status check before `sdd-verify`/archive is considered — per instruction, that next step requires explicit user go-ahead.
