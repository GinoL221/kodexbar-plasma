# Apply Progress: Persistent DataSource Lifecycle

**Mode**: Strict TDD
**Delivery**: Maintainer-approved `size:exception`; one work unit within the 800-line review budget.

## Completed Tasks

- [x] 1.1–1.5 RED contracts, lifecycle fixture, real executable harness, and PID termination proof.
- [x] 2.1–2.3 Persistent stage-specific DataSources with guarded lifecycle behavior.
- [x] 3.1 Full automated QML verification and exact-argv/PID-termination coverage.
- [x] 3.2 Fixture-backed live Plasma smoke instructions and restoration guidance.
- [x] 3.3 Live `plasmawindowed` Ready observation completed: the real desktop showed a populated provider list and compact `100%` summary after the request.
- [x] 4.1–4.5 Authorized lifecycle remediation tasks completed.
- [x] 4.6 Defer standalone missing and non-executable path assertions until synchronous preflight release completes.

## TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 1.1 | `tests/UsageControllerFixture.qml` | Unit | 7/7 existing fixture tests | Missing persistent-stage hooks failed before production code | 10/10 fixture tests passed | Numeric/string zero, nonzero string, valid-empty cases | Extracted stage delivery hook |
| 1.2 | `tests/UsageControllerFixture.qml` | Unit | 7/7 existing fixture tests | Missing persistent-stage hooks failed before production code | Guard cases passed | Wrong stage/source/generation/released callback cases | Shared `isCurrentStage` guard |
| 1.3 | `tests/UsageControllerLifecycleHarness.qml` | Integration | Full runner baseline passed | Contract updated before controller refactor | Harness passed | Timeout retry and preflight coalescing order | Kept one focused lifecycle harness |
| 1.4 | `tests/UsageControllerDataSourceLifecycleHarness.qml` | Integration | N/A (new) | Harness and executable fixture written before controller refactor | Fixture reaches Ready, one provider, zero requests | Shell argv assertion plus QML state assertions | Kept CLI boundary fixture-only |
| 1.5 | `tests/UsageControllerTerminationHarness.qml` | Integration | Full runner baseline passed | PID assertion written before controller refactor | Runner confirms `kill -0` failure after disconnect | Success and blocking fixture modes | Controller destruction shares lifecycle release |
| 2.1–2.3 | `tests/UsageControllerFixture.qml`, lifecycle harnesses | Unit + Integration | Full runner baseline passed | Existing RED contracts | All automated contracts passed | Terminal outcomes, stale callbacks, real process lifecycle | Centralized begin/release/guard paths |
| 4.6 | `tests/UsageControllerPathCheckHarness.qml` | Integration | Known failing path harness: exit 1 silently | Existing assertions observed `activeRequestCount === 1` from synchronous `phase` signal delivery | Focused harness exit 0 after deferral | Missing and `/dev/null` non-executable paths both assert zero active requests and actionable errors | One scheduling guard; no production change |
| timeout-popup-harness | `tests/TimeoutFeedbackPopupHarness.qml` | Integration | Focused harness exited 1 because `guidance.width` was asserted before `ColumnLayout` resolved | Existing geometry assertion failed before the harness-only change | Focused harness exits 0 after one deferred assertion turn | Exact timeout message, constrained geometry, focus, Refresh retry, and snapshot-retention assertions remain active | Deferred only the assertion block; no production QML changed |

## Work Unit Evidence

| Evidence | Result |
|---|---|
| Focused test command and exact result | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software /usr/lib/qt6/bin/qmltestrunner -input tests/UsageControllerFixture.qml -import .` — exit 0, 12 passed, 0 failed. |
| Runtime harness command/scenario and exact result | `./scripts/run-qml-tests.sh` — exit 0 after remediation; QtTest suites: UsageModel 8/8, UsageControllerFixture 12/12, SettingsInteraction 7/7; all 16 QML harnesses passed, including real preflight-to-command fixture argv assertion, path-failure snapshot retention, and PID termination (`kill -0` failed after disconnect). |
| Diff check | `git diff --check` — exit 0. |
| Live Plasma smoke | User-provided live screenshot showed `plasmawindowed` with populated Codex, Claude, OpenCode Go, Gemini, and Copilot provider rows plus compact `100%` summary; Ready state was observed. |
| Rollback boundary | Revert `contents/ui/UsageController.qml`, the focused controller/lifecycle tests and fixture, `scripts/run-qml-tests.sh`, and `docs/live-plasma-smoke.md` together. No provider, UI, timeout-policy, or CodexBar behavior needs rollback. |

## Files Changed

- `contents/ui/UsageController.qml` — persistent preflight/command DataSources, lifecycle metadata, guarded callbacks, deferred transition, and release-before-disconnect cleanup.
- `tests/UsageControllerFixture.qml` — exact source, exit-code, snapshot, No-data, and stale-callback contracts.
- `tests/UsageControllerLifecycleHarness.qml` — coalesced post-release and timeout retry ordering.
- `tests/UsageControllerDataSourceLifecycleHarness.qml` — real fixture-backed Ready completion.
- `tests/UsageControllerTerminationHarness.qml` — controller-driven disconnect termination path.
- `tests/fixtures/codexbar-lifecycle-fixture.sh` — exact argv recorder, response fixture, and blocking PID mode.
- `scripts/run-qml-tests.sh` — lifecycle harness admission, exact argv check, and PID-death assertion.
- `docs/live-plasma-smoke.md` — fixture-path setup, Ready evidence, and restoration checklist.

## Deviations and Risks

None from the design. The offscreen settings suite still emits pre-existing `i18n`/`i18np` reference warnings while passing. The live smoke used the configured real CodexBar path and confirmed the same persistent DataSource lifecycle in the Plasma host.

## Authorized Remediation Progress

**Runtime token**: `sha256:22304bfd746fb47930a27cdd32f271af5051c742dc05c81f187de7867f5a1fc4`  
**Mode**: Strict TDD remediation; no acquire or reset was performed.
Native `sdd-attempt finish` rejected the failed settlement as unmanaged remediation; native attempt remains running with `next_action: finish` and no binding revision.

| Task | RED | GREEN | REFACTOR | Status |
|---|---|---|---|---|
| 4.1 | Reused-source invalidation contract | 12/12 focused fixture cases pass | Release-before-disconnect plus stage/source/generation guards and termination proof | Complete under revised lifecycle invariant |
| 4.2 | Existing mixed-provider nonzero assertion was preserved | Structured stdout commits; empty nonzero stdout errors | Spec/design synchronized | Complete |
| 4.3 | Runner exposed a masked 120-second assertion | Assertion helpers retain failure state through `finish()` | Corrected queued-generation timeout expectation | Complete |
| 4.4 | Extended lifecycle harness from Ready snapshot to missing-path preflight | Standalone lifecycle harness passes | Snapshot retained and active request released | Complete |
| 4.5 | Documentation acceptance gap identified | Active artifacts state manual-evidence provenance | N/A | Complete |

## Work Unit Evidence

| Evidence | Result |
|---|---|
| Focused test | `qmltestrunner -input tests/UsageControllerFixture.qml -import .` — exit 0, 12 passed, 0 failed. |
| Runtime harness | `qml6 --software -f tests/UsageControllerDataSourceLifecycleHarness.qml` — exit 0; fixture reaches Ready, exact provider is committed, missing-path refresh retains the snapshot, and the request is released. |
| Full runner | `./scripts/run-qml-tests.sh` — exit 0 after fixture-path correction; 27 QtTest outcomes passed and all 16 QML harnesses passed. |
| Diff check | `git diff --check` — exit 0. |
| Rollback boundary | Revert the controller callback changes, focused fixture/harness changes, assertion helpers, and active change artifacts together. |

```yaml
schema: gentle-ai.remediation-result/v1
lineage_id: sha256:fdc9ce68220c10f2e0298fbb4fa803fd9814380b93a6100e60b798eabac0ede7
generation: 3
fix_batch: 1
failed_evidence_revision: sha256:1824a3ae91ddeb013338a6fcd7ffbe1ea8696b3c3d3b7ce2e1bcc2b59629581d
status: complete
```
```json
{"schema":"gentle-ai.remediation-evidence/v1","lineage_id":"sha256:fdc9ce68220c10f2e0298fbb4fa803fd9814380b93a6100e60b798eabac0ede7","generation":3,"fix_batch":1,"failed_evidence_revision":"sha256:1824a3ae91ddeb013338a6fcd7ffbe1ea8696b3c3d3b7ce2e1bcc2b59629581d","focused_test":{"exit_code":0,"passed":12,"failed":0},"runtime_harness":{"exit_code":0,"fixture_argv":"relative-fixture-resolution"},"full_runner":{"exit_code":0,"qt_test_passed":27,"qml_harnesses":16},"diff_check":{"exit_code":0}}
```

## Native Remediation: `path-check-harness`

**Runtime token**: `sha256:f7dd1308eba3581a11a7b38e08413cdc567d101fee63ddbeb9f6ab268c4ef8a0`  
**Mode**: Strict TDD remediation; no attempt was acquired or reset.

| Task | RED | GREEN | TRIANGULATE | REFACTOR | Status |
|---|---|---|---|---|---|
| 4.6 | `qml6` exited 1 with no emitted assertion text while both real preflight paths were exercised. | `UsageControllerPathCheckHarness.qml` exits 0 after deferring checks one event-loop turn. | Missing and non-executable paths each assert zero active requests and actionable errors. | Added one scheduling guard; production `UsageController.qml` and `Plasma5Support.DataSource` coverage are unchanged. | Complete |

### Work Unit Evidence

| Evidence | Result |
|---|---|
| Focused runtime harness | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/UsageControllerPathCheckHarness.qml` — exit 0. The missing and `/dev/null` non-executable paths both reach Error; their assertions run after release and pass. |
| Initial RED observation | The same path harness exited 1 silently under `qml6` before the change. `phase` changes to Error before `failGeneration()` calls `releaseGeneration()`, so the synchronous signal handler observed `activeRequestCount === 1`. |
| Full runner | `./scripts/run-qml-tests.sh` — exit 1. The three QtTest suites passed (27 passed, 0 failed); the path harness passed, then unmodified `TimeoutFeedbackPopupHarness.qml` exited 1 silently. |
| Diff check | `git diff --check` — exit 0. |
| Rollback boundary | Revert only `tests/UsageControllerPathCheckHarness.qml` and this remediation evidence/task entry; no production behavior, CLI command, or DataSource coverage is removed. |

No native lifecycle transition was invoked. The supplied token is recorded verbatim; lineage, generation, fix batch, and failed-evidence revision were not available in the workspace, so no new `gentle-ai.remediation-result/v1` completion envelope is claimed.

## Native Remediation: `timeout-popup-harness`

**Runtime token**: `sha256:20737662ea6c2426aca459c0de5e34756cc2c2f7a390fb31a3d93d7ffe50532d`  
**Mode**: Strict TDD remediation; no attempt was acquired or reset.

The assertion-hardening change evaluated `guidance.width` in the same event-loop turn that constructed the `ColumnLayout`. The layout had not resolved its constrained width, so the wrap assertion failed even though the popup configuration was correct. Deferring only the assertion block by one `Qt.callLater` turn lets the native layout settle while preserving every assertion and all controller behavior.

### Work Unit Evidence

| Evidence | Result |
|---|---|
| Initial RED observation | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/TimeoutFeedbackPopupHarness.qml` — exit 1; one failure: `timeout guidance must wrap inside the narrow popup`. |
| Focused runtime harness | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/TimeoutFeedbackPopupHarness.qml` — exit 0; all 8 popup assertions passed: constrained geometry, visible exact timeout message, wrapping, accessible Refresh label, focus, retry Loading state, and retained snapshot. |
| Full runner | `./scripts/run-qml-tests.sh` — exit 1 after the popup harness passed. QtTest suites: 27 passed, 0 failed. The runner then reached `CompactUsageButtonHarness.qml`, which failed two unrelated focus/accessibility assertions and emitted pre-existing missing `i18n` references; `TimeoutFeedbackPopupHarness.qml` itself passed. |
| Diff check | `git diff --check` — exit 0. |
| Rollback boundary | Revert only `tests/TimeoutFeedbackPopupHarness.qml` and this evidence entry; production QML, timeout message, DataSource lifecycle, and other harnesses remain untouched. |

```yaml
schema: gentle-ai.remediation-result/v1
lineage_id: sha256:fdc9ce68220c10f2e0298fbb4fa803fd9814380b93a6100e60b798eabac0ede7
generation: 3
fix_batch: 1
failed_evidence_revision: sha256:1824a3ae91ddeb013338a6fcd7ffbe1ea8696b3c3d3b7ce2e1bcc2b59629581d
status: partial
runtime_token: sha256:20737662ea6c2426aca459c0de5e34756cc2c2f7a390fb31a3d93d7ffe50532d
```
```json
{"schema":"gentle-ai.remediation-evidence/v1","lineage_id":"sha256:fdc9ce68220c10f2e0298fbb4fa803fd9814380b93a6100e60b798eabac0ede7","generation":3,"fix_batch":1,"failed_evidence_revision":"sha256:1824a3ae91ddeb013338a6fcd7ffbe1ea8696b3c3d3b7ce2e1bcc2b59629581d","runtime_token":"sha256:20737662ea6c2426aca459c0de5e34756cc2c2f7a390fb31a3d93d7ffe50532d","focused_runtime_harness":{"exit_code":0,"assertions_passed":8,"assertions_failed":0},"full_runner":{"exit_code":1,"qt_test_passed":27,"qt_test_failed":0,"popup_harness":"passed","blocker":"CompactUsageButtonHarness focus/accessibility assertions"},"diff_check":{"exit_code":0}}
```

No completion is claimed: the prescribed full runner remains blocked outside this authorized harness-only boundary.
