# Tasks: Actionable CodexBar Timeout Feedback

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | 220–320 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR / one work unit |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Exact timeout feedback with bounded docs | Single PR | `./scripts/run-qml-tests.sh` | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/UsageControllerFailureHarness.qml` | Revert controller, named tests, README, and optional smoke checklist only. |

## Phase 1: RED Contract Tests

- [x] 1.1 In `tests/UsageControllerFixture.qml`, add failing runner tests for exact `CodexBar did not return all-provider usage within 15 seconds. Check enabled providers in CodexBar, temporarily disable a provider that hangs, then retry.` versus exact `CodexBar CLI returned no output.`, fixed all-provider command, no auth/probe, release, and no generation change until Refresh.
- [x] 1.2 In `tests/UsageControllerFixture.qml`, add failing retry tests: seed a snapshot, timeout, Refresh once, then assert `loading`, generation `+1`, one active request, retained snapshot, and stale completion ignored.
- [x] 1.3 In `tests/UsageControllerFailureHarness.qml`, add failing cases for retained snapshots and recoverable Refresh after malformed JSON and nonzero exit; assert valid `[]` becomes `noData`, clears error, and atomically replaces the snapshot.
- [x] 1.4 In `tests/RefreshIntervalHarness.qml`, retain/add RED checks that `0`, `-1`, nonnumeric, and fractional intervals reject with existing valid-range correction behavior.
- [x] 1.5 Run `./scripts/run-qml-tests.sh`; record its expected RED failure before production changes.

## Phase 2: GREEN Controller Change

- [x] 2.1 In `contents/ui/UsageController.qml`, replace only the command-stage timeout copy with the specified exact message; preserve preflight text, `timeoutMs: 15000`, `commandLine()`, generation guards, request release, snapshots, and native surfaces.
- [x] 2.2 Run `./scripts/run-qml-tests.sh` until every fixture test passes without changing provider fetching, auth, alternate probing, per-provider isolation, or CLI behavior.

## Phase 3: Harness and Runtime Verification

- [x] 3.1 Run `for f in UsageControllerFailureHarness UsageControllerLifecycleHarness RefreshIntervalHarness MainCompactHarness; do QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/$f.qml; done`; record pass results and snapshot/overlap evidence.
- [x] 3.2 Verify `git diff --check`, then confirm the changed command remains exactly `usage --provider all --format json --json-only` and no unplanned source/UI surfaces changed.

## Phase 4: Documentation and Native Smoke

- [x] 4.1 Update `README.md` with the 15-second watchdog, upstream enabled-provider temporary-disable-and-retry workaround, and widget Refresh; exclude attribution, auth, CLI changes, and probing.
- [x] 4.2 Optionally update `docs/live-plasma-smoke.md` with narrow-popup, keyboard Refresh, and Breeze readability checks; run its `kpackagetool6`/`plasmawindowed` procedure when available, otherwise record it as manual-only.
