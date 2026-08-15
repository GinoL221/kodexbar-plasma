# Design: Persistent DataSource Lifecycle

## Technical Approach

Replace the live request-scoped executable objects in `UsageController.qml` with two declared `Plasma5Support.DataSource` children: preflight and command. A generation remains active across both stages; only one stage is connected at a time. Before any reconnect, release clears active state and metadata, stops the watchdog, and disconnects the previous source; the termination harness proves that disconnect ends the executable request. Callbacks commit only while the matching stage, source, and generation remain active. This lifecycle invariant replaces impossible connection-local identity capture for a reused persistent DataSource and keeps the change from altering `main.qml`, UI rendering, CodexBar, timeout configuration/text, normalization, or refresh policy.

## Architecture Decisions

| Option | Tradeoff | Decision |
|---|---|---|
| Persistent stage-specific DataSources | Removes the failing dynamic transition; reused identity requires logical guards | **Choose.** Declare preflight and command children; never create/destroy live request DataSources. |
| Keep dynamic objects but delay destruction/pool them | Retains per-request identity but preserves the observed lifecycle mechanism and adds ownership states | Reject. |
| Combine `test -x` and usage in one source | Simpler lifecycle but changes the command boundary and merges distinct failures | Reject. |
| Deferred transition | Adds one event-loop turn but avoids reconnecting inside callback/release | **Choose.** Use `Qt.callLater`; re-check generation/activity before starting. |

## Data Flow

```text
refresh -> generation active -> preflight DataSource
                              -> guarded success -> disconnect/invalidate stage
                              -> command DataSource -> guarded terminal result
                              -> disconnect/invalidate generation -> one queued refresh
```

Loading spans the generation. Preflight uses exactly `test -x <shell-quoted absolute path>`; command uses exactly `<shell-quoted absolute path> usage --provider all --format json --json-only`. Each stage freezes the configured timeout and owns one watchdog. Existing preflight timeout guidance and exact all-provider timeout guidance remain unchanged.

Release clears lifecycle metadata and stops the watchdog before `disconnectSource(activeSource)`, so late callbacks see inactive or mismatched state. Preflight success releases its stage; terminal success/error/timeout releases the generation. Controller destruction uses the same path. A deferred transition prevents reconnecting during the callback; no source is reconnected until the prior stage has been released.

## File Changes

| File | Action | Description |
|---|---|---|
| `contents/ui/UsageController.qml` | Modify | Add persistent children, lifecycle metadata, guards, deferred transitions, and shared release/shutdown logic; retain test hooks. |
| `tests/UsageControllerFixture.qml` | Modify | RED tests for exact commands; wrong stage/source/generation and post-release callbacks; snapshot retention. |
| `tests/UsageControllerLifecycleHarness.qml` | Modify | Prove one active generation, one post-release coalesced refresh, and timeout retry ordering. |
| `tests/UsageControllerDataSourceLifecycleHarness.qml` | Create | Run real successful preflight and command stages and assert Ready, one provider, and zero active requests. |
| `tests/UsageControllerTerminationHarness.qml` | Modify | Drive the controller command stage, release it, and expose PID termination evidence. |
| `tests/fixtures/codexbar-lifecycle-fixture.sh` | Create | Accept exact argv; emit valid JSON or record PID and block, selected by environment. |
| `scripts/run-qml-tests.sh` | Modify | Admit lifecycle harnesses, verify exact argv, and require `kill -0` failure after disconnect. |
| `docs/live-plasma-smoke.md` | Modify | Add fixture-backed `plasmawindowed` Ready/no-stuck-Loading acceptance and restoration steps. |

## Interfaces / Contracts

Callback validity requires `requestActive`, expected DataSource identity, `activeStage`, `activeSource`, the connection-owned captured generation, `activeGeneration`, and current `generation`. `activeRequestCount` includes the deferred stage gap. Multiple triggers set one demand; a scheduled follow-up is redundant if another generation started.

Fully parsed and normalized usable stdout replaces `committedProviders`/`committedErrors` even when a nonzero exit reports optional provider failures. A nonzero exit with empty stdout, plus path, malformed, timeout, or stale outcomes, retains the prior snapshot. Valid empty normalized output from a zero-exit command still commits No data.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit | Guard classes, exact source strings, coalescing, snapshot retention | Extend QtTest fixture first (RED). |
| Integration | Real preflight-to-command completion and disconnect termination | `qml6` executable fixture harnesses; shell asserts argv/count/PID. |
| E2E | Plasma-host lifecycle completion | When feasible, configure fixture path and run `plasmawindowed`; otherwise record documented manual real-provider Ready evidence, its provenance, and the automation limitation. |

## Threat Matrix

| Boundary | Applicability | Safe/failure behavior | Planned RED tests |
|---|---|---|---|
| Documentation-like paths | N/A — no executable classification is introduced | No behavior change | None |
| Git repository selection | N/A — no VCS operation | No behavior change | None |
| Commit state | N/A — no VCS operation | No behavior change | None |
| Push state | N/A — no VCS operation | No behavior change | None |
| PR commands | N/A — no PR automation | No behavior change | None |
| Executable command/process lifecycle | Applicable | Exact quoted sources only; mismatches fail closed, timeout/destruction disconnects, stale output cannot commit | Exact argv, real success, wrong guard classes, timeout/PID termination |

## Migration / Rollout

No migration required. Deliver as one bounded controller-and-tests work unit. Roll back `UsageController.qml`, focused tests/fixture, runner admission, and smoke documentation together; do not revert UI, configuration, snapshots, or CodexBar. Stop for review if the isolated authored diff exceeds the 800-line budget.

## Open Questions

None.
