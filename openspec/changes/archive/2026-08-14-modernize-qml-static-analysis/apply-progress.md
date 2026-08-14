# Apply Progress: Modernize QML Static Analysis

## Slice 1: Semantic Gate and Tests

Completed tasks 1.1–2.3. The gate recursively enumerates `contents/ui/**/*.qml`, validates the Qt nested JSON contract and UTF-16 source locations, and accepts only exact `i18n` or `i18np` unqualified spans. `.qmlls.ini` and `.qmllint.ini` supply valid non-CMake and strict-warning settings; checker help documents portable overrides.

## Slice 2: Bound QML Modernization

Completed tasks 3.1–3.4. The affected UI components use `ComponentBehavior: Bound`; outer component access is explicit, the provider tab delegate declares `required property int index`, and existing `modelData` declarations remain explicit. KDE `i18n`/`i18np` function names, strings, argument order, and callback shapes were not changed. `contents/ui/config/configGeneral.qml` was inspected and emits only accepted translation warnings; `contents/config/config.qml` was not read or edited.

## Slice 3: Guidance and Final Pre-Verification

Completed tasks 4.1–4.2. `README.md` now documents Qt 6/KDE non-CMake editor setup, portable lint overrides, the recursive `contents/ui/**/*.qml` scope, the `contents/config` exclusion, and the exact accepted KDE translation baseline. It identifies `./scripts/run-qml-tests.sh` as the behavioral/QML authority and `./scripts/lint-qml.sh` as the static-analysis authority. Final pre-verification passed without modifying QML, provider behavior, CLI integration, package identities, or excluded/archived files.

## Completed Tasks

- [x] 1.1–1.4 Policy and RED contract
- [x] 2.1–2.3 Semantic gate implementation and refactor
- [x] 3.1–3.4 Bound QML modernization
- [x] 4.1 README contributor guidance
- [x] 4.2 Final pre-verification evidence

## TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 1.1 | `tests/test_qml_unqualified_baseline.py` | Unit | N/A (new) | File-missing failure | 10 passing | exact `i18n`/`i18np`; reject `root`, `index`, flat schema | Clean |
| 1.2 | `tests/test_qml_unqualified_baseline.py` | Unit | N/A (new) | File-missing failure | 10 passing | nested/config inclusion; duplicate, missing, escape, UTF-8 rejection | Clean |
| 1.3 | `tests/test_qml_unqualified_baseline.py` | Unit | N/A (new) | File-missing failure | 10 passing | UTF-16, location, override, and nonzero-process cases | Added `qtpaths6` fallback after a new RED test |
| 1.4 | `tests/test_qml_unqualified_baseline.py` | Unit | N/A (new) | Missing configuration failure | 10 passing | all strict settings plus visible unqualified setting | None needed |
| 2.1 | `tests/test_qml_unqualified_baseline.py` | Unit | N/A (new) | File-missing failure | 10 passing | nested report and process paths | `qtpaths6` portable fallback; reject warningless failures |
| 2.2 | `tests/test_qml_unqualified_baseline.py` | Integration | `lint-qml.sh` exit 0 before edit | Wrapper did not fail on structural warning | 10 passing | wrapper delegation assertion | None needed |
| 2.3 | `tests/test_qml_unqualified_baseline.py` | Unit/integration | 10 passing | Prior contract | 10 passing | static gate rejects current non-translation warning | Help and lookup cleanup retained tests green |
| 3.1 | `tests/test_bound_qml_components.py`, existing QML harnesses | Unit/integration | `./scripts/run-qml-tests.sh` — 44 QtTest assertions passed, executable harnesses passed | New structural contract failed with 10 missing Bound/qualified/delegate assertions | 3 structural tests passed; focused ProviderSelector/ProviderRow/ErrorSummary/MainCompact harnesses exited 0 | Provider selector harness additionally proves the selected delegate text and checked state | No production refactor beyond explicit qualification |
| 3.2 | `tests/test_bound_qml_components.py`, `tests/ProviderSelectorHarness.qml` | Unit/integration | Full QML suite green before edit | Bound/required-context contract failing | Focused test 3/3 and ProviderSelector harness exit 0 | Selected delegate is visible, exposes provider data, and remains checked | Root aliases provide legal explicit outer-ID qualification |
| 3.3 | `tests/test_bound_qml_components.py`, row/error/main harnesses | Unit/integration | Full QML suite green before edit | Bound/qualified-scope contract failing | Focused test 3/3 and three affected harnesses exit 0 | Full runner preserves compact rendering, rows, failure disclosure, and exact CLI argv coverage | None needed |
| 3.4 | `./scripts/lint-qml.sh` | Integration | Full QML suite green before inspection | N/A — inspection-only task | Lint exit 0; 56 accepted exact translation warnings | `configGeneral.qml` has only `i18n`/`i18np` spans, no structural diagnostic | No edit needed |
| 4.1 | Inline README contract check | Documentation | `./scripts/run-qml-tests.sh` — exit 0; 44 QtTest assertions passed and executable harnesses completed | exit 1: missing editor/override/scope/baseline guidance | exit 0: all nine required documentation markers present | editor setup, three overrides, recursive scope, exclusion, baseline, and both commands | Consolidated guidance under one scannable section; no behavior change |
| 4.2 | Inline apply-progress contract check | Verification evidence | `./scripts/lint-qml.sh` — exit 0; 56 accepted warnings; `git diff --check` — exit 0 | exit 1: final evidence markers absent | exit 0 after this artifact records final command results | `lint-qml.sh`, `run-qml-tests.sh`, and whitespace gate all exit 0 | None needed — evidence-only task; no production code changed |

## Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test | `python3 -m unittest tests/test_qml_unqualified_baseline.py` — exit 0, 10 tests passed. |
| Runtime harness | `./scripts/run-qml-tests.sh` — exit 0; QtTest totals 44 passed, 0 failed; executable harnesses completed. Existing test-environment `i18n` and fixture parse warnings remain non-fatal. |
| Static authority | `./scripts/lint-qml.sh` — exit 1, `error: unaccepted qmllint diagnostic`; expected until the excluded Bound QML slice removes existing structural `root`/delegate warnings. |
| Rollback boundary | Revert `.qmlls.ini`, `.qmllint.ini`, `scripts/check-qml-unqualified-baseline.py`, `scripts/lint-qml.sh`, and `tests/test_qml_unqualified_baseline.py` only. |
| Slice 2 focused test | `python3 -m unittest tests/test_bound_qml_components.py` — RED: exit 1 with 10 assertion failures; GREEN: exit 0, 3 tests passed. |
| Slice 2 runtime harness | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 tests/ProviderSelectorHarness.qml` — exit 0. Focused ProviderRow, ErrorSummary, and MainCompact harnesses also exited 0 before the final full runner. |
| Slice 2 full behavioral runner | `./scripts/run-qml-tests.sh` — exit 0; QtTest totals 44 passed, 0 failed; all executable QML harnesses completed. One pre-existing `QProcess: Destroyed while process ("/usr/bin/test") is still running` warning was non-fatal. |
| Slice 2 static authority | `./scripts/lint-qml.sh` — exit 0; `Accepted 56 exact KDE translation warning(s).` No structural diagnostic remains. |
| Slice 2 diff validation | `git diff --check` — exit 0. |
| Slice 2 rollback boundary | Revert `contents/ui/main.qml`, `ProviderSelector.qml`, `ProviderRow.qml`, `UsageWindowRow.qml`, `ErrorSummary.qml`, `tests/ProviderSelectorHarness.qml`, and `tests/test_bound_qml_components.py`; preserve prior slice-1 tooling changes and unrelated responsive-worktree edits. |
| Slice 3 focused test | Inline README contract check — RED exit 1 with seven missing guidance markers; GREEN exit 0 with all nine required markers present. |
| Slice 3 runtime harness | `./scripts/run-qml-tests.sh` — exit 0; QtTest totals 44 passed, 0 failed; all executable QML harnesses completed. This preserves the existing exact CLI argv assertions. No Breeze Light or independent-Plasma-instance runtime evidence was attempted or claimed. |
| Slice 3 static authority | `./scripts/lint-qml.sh` — exit 0; `Accepted 56 exact KDE translation warning(s).` Only exact `i18n`/`i18np` spans were accepted; zero fixable structural warnings remain. |
| Slice 3 diff validation | `git diff --check` — exit 0. |
| Slice 3 translation/argv preservation | No QML or CLI source was edited in this slice. The existing full QML runner exited 0, including its covered exact CLI argv assertions; translation call shapes remain as established by slice 2. |
| Slice 3 rollback boundary | Revert only the QML static-analysis guidance section in `README.md` and the slice-3 entries/checkboxes in `openspec/changes/modernize-qml-static-analysis/{tasks.md,apply-progress.md}`; preserve earlier slices and unrelated README/package-transition content. |

## Remaining Tasks

None — all planned apply tasks are complete. Formal SDD verification remains next.

## Delivery

- Strategy: `ask-on-risk`, resolved as final slice 3 of a `stacked-to-main` chain.
- Review boundary: README guidance plus task/progress evidence only; no QML source, `.qmlls.ini`, `.qmllint.ini`, semantic checker, lint script, provider behavior, CLI integration, package identity, icon backlog, archived responsive files, `contents/config/config.qml`, or build files changed.
- The slice-owned documentation/evidence work is below the 400-line review budget; no commit, push, or PR was created.
