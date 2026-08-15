# Tasks: Persistent DataSource Lifecycle

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | 600–760 |
| 800-line budget risk | Medium |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending (not required) |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
800-line budget risk: Medium

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Persistent lifecycle plus proofs | Single PR | `./scripts/run-qml-tests.sh` | fixture-backed `plasmawindowed` checklist | controller, focused tests, fixture, runner, smoke doc |

## Phase 1: RED Contracts and Harnesses

- [x] 1.1 Extend `tests/UsageControllerFixture.qml` with failing exact preflight/command source, numeric/string zero and nonzero exit-code, snapshot, and valid-empty No-data cases.
- [x] 1.2 Add failing released/wrong-stage/wrong-source/superseded-generation callback and deferred-gap `activeRequestCount` assertions to `tests/UsageControllerFixture.qml`.
- [x] 1.3 Extend `tests/UsageControllerLifecycleHarness.qml` with failing coalesced-after-release and timeout-retry ordering assertions.
- [x] 1.4 Create `tests/fixtures/codexbar-lifecycle-fixture.sh` and RED `tests/UsageControllerDataSourceLifecycleHarness.qml` for exact argv, real Ready completion, one provider, and zero active requests.
- [x] 1.5 Update `tests/UsageControllerTerminationHarness.qml` and `scripts/run-qml-tests.sh` so the RED harness records its PID and fails unless disconnect makes `kill -0` fail.

## Phase 2: Persistent Lifecycle GREEN

- [x] 2.1 Refactor `contents/ui/UsageController.qml` to declared preflight and command `Plasma5Support.DataSource` children; retain the exact quoted `test -x` and all-provider command strings.
- [x] 2.2 Add active stage/source/generation/DataSource guards, stage-local watchdog release-before-disconnect, destruction cleanup, and `Qt.callLater` transition guarded again before command start.
- [x] 2.3 Preserve Loading across both stages, frozen timeout, one queued refresh after terminal release, failure snapshots, and distinct empty/malformed/path/timeout/nonzero outcomes.

## Phase 3: Verification and Live Acceptance

- [x] 3.1 Run `./scripts/run-qml-tests.sh`; resolve all fixture, lifecycle, exact-argv, and PID-termination failures without altering CLI/provider/UI scope.
- [x] 3.2 Update `docs/live-plasma-smoke.md` only to document fixture-path setup, `plasmawindowed` Ready/no-stuck-Loading evidence, and restoration of the prior path.
- [x] 3.3 Execute the documented live `plasmawindowed` smoke; record Ready evidence and `git diff --check` before review. Live Plasma showed the compact `100%` summary and a populated scrollable provider view after the all-provider request completed; `git diff --check` passed.

## Phase 4: Authorized Remediation

- [x] 4.1 Prove reused-source invalidation through release-before-disconnect, stage/source/generation guards, and executable termination coverage. Connection-local identity is not required by the revised lifecycle invariant.
- [x] 4.2 Align nonzero-exit behavior with structured stdout commitment and preserve empty-stdout errors.
- [x] 4.3 Make standalone harness exits preserve assertion failures; correct the uncovered timeout expectation.
- [x] 4.4 Add a passing executable path-failure-after-snapshot runtime proof through the standalone lifecycle harness.
- [x] 4.5 Reconcile test evidence and accept documented manual live observation with explicit provenance.
- [x] 4.6 Defer standalone missing and non-executable path assertions until the synchronous preflight release completes, preserving real `Plasma5Support.DataSource` coverage.
