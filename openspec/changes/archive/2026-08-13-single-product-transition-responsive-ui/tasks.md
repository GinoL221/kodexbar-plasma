# Tasks: Single-Product Transition and Responsive UI

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | 180–280 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR / work unit |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Document safe coexistence and make current-popup rows responsive | PR 1 | `./scripts/run-qml-tests.sh` | `plasmawindowed org.kde.plasma.kodexbar.plasma`: narrow/wider rows in Breeze Light/Dark | Revert `README.md`, `docs/live-plasma-smoke.md`, `tests/ProviderRowHarness.qml`, and `contents/ui/UsageWindowRow.qml` |

## Phase 1: Transition Guidance and Baseline

- [x] 1.1 Update `README.md` with legacy `org.kde.plasma.kodexbar` versus current `org.kde.plasma.kodexbar.plasma` coexistence, current-only install/update, and manual add-new **KodexBar Plasma** widget guidance.
- [x] 1.2 Document optional per-instance manual copying of `General` CLI path, refresh interval, request timeout, and representative window; prohibit package removal, panel mutation, and cross-ID migration in `README.md`.
- [x] 1.3 Update `docs/live-plasma-smoke.md` for coexistence, independent instances, and narrow/wider popup checks; run and record baseline `./scripts/run-qml-tests.sh` without lifecycle remediation.

## Phase 2: RED Responsive Contract

- [x] 2.1 Add failing constrained-width fixtures to `tests/ProviderRowHarness.qml` for direct, summary, and provider-composed finite rows: full visible percentage, all visible children bounded, and positive remaining progress-bar width.
- [x] 2.2 Add failing wider-allocation assertions in `tests/ProviderRowHarness.qml` proving the percentage remains un-clipped and the bar grows by available width; run `./scripts/run-qml-tests.sh` and record the expected responsive failure.

## Phase 3: GREEN Native Layout

- [x] 3.1 Modify only `contents/ui/UsageWindowRow.qml`: use native `RowLayout`, an elidable zero-minimum label slot, reserved non-elided percentage implicit width, `Layout.fillWidth` progress bar, and Kirigami spacing.
- [x] 3.2 Re-run `./scripts/run-qml-tests.sh` until RED assertions pass while existing exact `usage --provider all --format json --json-only` argv coverage remains green; refactor only within `UsageWindowRow.qml` if needed.

## Phase 4: Focused Verification

- [x] 4.1 Run `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, and `git diff --check`; confirm metadata, config, controllers, compact/legacy UI, provider/auth/fetch, CLI, and lifecycle artifacts are unchanged.
- [x] 4.2 Run `plasmawindowed org.kde.plasma.kodexbar.plasma`; maintainer-approved live evidence confirms the current-product dark-session narrow/wide responsive smoke: the full `42% used` percentage is visible, the row content and progress bar are bounded, and the bar grows at wider allocation.

## Non-Blocking Follow-Ups (Not Part of Completed Task 4.2)

- Breeze Light live smoke was not observed in this evidence round and is not claimed as PASS.
- Independent legacy/current installed-instance verification was not observed in this evidence round and is not claimed as PASS.
