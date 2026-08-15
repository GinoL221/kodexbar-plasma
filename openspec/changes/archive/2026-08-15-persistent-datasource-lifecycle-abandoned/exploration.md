## Exploration: persistent-datasource-lifecycle

### Current State
`UsageController.qml` validates the configured absolute path by dynamically creating `pathCheckComponent`, running quoted `test -x`, and receiving a successful executable-engine callback (`exit code` normalized with `Number(...)`). It then releases and destroys that object and dynamically creates a second `executableComponent` for the unchanged authoritative command: `<quoted path> usage --provider all --format json --json-only`. In live Plasma the first stage reports `qml: 0`, but the second object never emits `onNewData`, leaving `activeDataSource` non-null and the UI in Loading until its watchdog fires.

This two-dynamic-object lifecycle differs from the original staged `main.qml` implementation, which declared persistent executable `DataSource` children and reused them by clearing/disconnecting sources and calling `connectSource`. The archived MVP design instead deliberately selected one request-scoped object per request for identity-based stale-callback rejection. The current fixtures cover invalid real preflight paths and simulated request completion, but do not exercise a successful real preflight immediately followed by the real command source in one controller lifecycle; `testMode` bypasses both executable `DataSource` stages.

### Affected Areas
- `contents/ui/UsageController.qml` — replace dynamic creation/destruction with a stable executable-engine lifecycle while retaining command construction, timeout snapshots, generations, coalescing, and committed snapshots.
- `tests/UsageControllerFixture.qml` — add RED contract coverage for successful preflight-to-command sequencing and stale-stage rejection.
- `tests/UsageControllerPathCheckHarness.qml` or a focused new lifecycle harness — run an executable fixture through both real DataSource stages and assert Ready/no stuck Loading.
- `tests/UsageControllerTerminationHarness.qml` — retain disconnect-termination proof and extend it only if persistent reuse changes its assumptions.
- `scripts/run-qml-tests.sh` — admit any new executable lifecycle harness.
- `docs/live-plasma-smoke.md` — add a live `plasmawindowed` check for preflight success followed by a completed all-provider request.

### Approaches
1. **Two persistent, stage-specific DataSources** — declare stable preflight and command executable-engine children; `activeDataSource` references the active child, while an explicit active-stage/source/generation record gates callbacks. Release disconnects the source and clears logical activity, never destroys either child.
   - Pros: Removes the observed dynamic-to-dynamic transition; follows the original persistent-object pattern; keeps the preflight and exact CLI command separate; preserves one active process, watchdog behavior, generation/coalescing, and snapshots.
   - Cons: Persistent objects cannot use object identity to distinguish two historical executions of the identical command; guards must include active state, stage, source name, and generation, while the proven `disconnectSource()` termination behavior remains the process boundary.
   - Effort: Medium.

2. **Keep request-scoped DataSources and alter destruction timing** — delay destruction, pool objects, or create the command object before releasing the preflight object.
   - Pros: Retains per-object identity for stale callbacks with a smaller conceptual change.
   - Cons: Does not restore the original proven persistent pattern, leaves the live dynamic-object failure mechanism in play, and pooling complicates ownership and timeout cleanup.
   - Effort: Medium.

3. **Combine preflight and CLI execution into one shell source** — run `test -x` and the usage command from one executable-engine request.
   - Pros: Avoids the second DataSource lifecycle.
   - Cons: Violates the exact CLI-boundary requirement by changing the executable source command and conflates actionable preflight failures with CLI output; reject as out of scope.
   - Effort: Low, but unacceptable.

### Recommendation
Adopt two persistent, stage-specific `Plasma5Support.DataSource` children in `UsageController.qml`: one for quoted `test -x`, one for the exact quoted CodexBar command. Model logical activity explicitly (`generation`, active stage, expected source command, and active flag); disconnect and invalidate that logical request before timeout/error release, and start a queued follow-up only after release. This removes the live-only dynamic transition while preserving the preflight boundary and the archived MVP contracts. Treat `disconnectSource()` process termination as a required regression gate, not as a substitute for callback guards.

Start with RED tests that use an executable JSON fixture through successful real preflight and command stages, assert the command reaches Ready, assert no active request remains, and repeat through `plasmawindowed`. Preserve existing simulated stale/coalescing tests and add late/incorrect-stage callback cases. The likely change is below the 800-line budget (roughly 250–400 lines including focused tests and smoke guidance), but `ask-on-risk` should stop for confirmation if the isolated diff exceeds 800 lines.

### Risks
- The live symptom strongly implicates dynamic DataSource lifecycle, but it is not a root-cause proof until the persistent lifecycle passes the same live Plasma sequence.
- A persistent command source has weaker per-instance identity than the current request-scoped object; logical invalidation and real disconnect-termination coverage are mandatory to preserve stale-response safety.
- Offscreen QML may not reproduce Plasma host behavior, so automated harnesses must be paired with a documented live `plasmawindowed` smoke check.
- The working tree has no Git baseline and unrelated changes, so review size must be measured from an isolated change diff before apply.

### Ready for Proposal
Yes — propose a controller-only lifecycle correction using persistent stage-specific DataSources, with RED-first successful preflight-to-command integration coverage and a live Plasma acceptance check. Keep the CLI command, timeout text and snapshot behavior, generation/coalescing semantics, and product exclusions unchanged.
