# Design: Configurable Request Timeout

## Technical Approach

Add one validated global timeout setting while preserving the existing all-provider process flow. KConfig persists seconds; a pure JS resolver accepts only finite integers from 30–600 and returns 60 otherwise. `main.qml` supplies resolved milliseconds to `UsageController`, independently of `RefreshInterval`. The controller snapshots each stage's active timeout for the watchdog and exact provider-neutral message; command, generation, coalescing, stale guards, snapshots, retry, and failure distinctions remain unchanged.

## Architecture Decisions

| Option | Tradeoff | Decision and rationale |
|---|---|---|
| Shared strict resolver vs inline coercion | Adds one file | Create `RequestTimeout.js`, matching `RefreshInterval.js`; one boundary prevents malformed, string, fractional, and out-of-range persistence reaching timers. |
| Preset selector plus custom SpinBox vs free SpinBox only | Two coordinated native controls | Use a labeled QQC2 preset ComboBox (60/120/180/Custom) and a 30–600 SpinBox in `Kirigami.FormLayout`; presets are discoverable while bounded custom integers remain possible. |
| Snapshot active timeout vs live binding during a request | Adds one controller property | Snapshot milliseconds when each preflight/command stage starts so settings changes cannot reset a running watchdog or mismatch its message. |
| Extend controller vs alter CLI acquisition | No provider isolation | Preserve the single authoritative command because timeout callbacks contain no provider identity and excluded acquisition work needs a separate change. |

## Data Flow

    KConfig requestTimeout (seconds) → RequestTimeout resolver → main.qml (milliseconds)
                                                        └────→ UsageController stage snapshot
                                                                  ├→ watchdog
                                                                  └→ exact timeout text
    KConfig refreshInterval ───────→ RefreshInterval resolver ─────→ refresh Timer (unchanged)

## File Changes

| File | Action | Description |
|---|---|---|
| `contents/config/main.xml` | Modify | Add integer `requestTimeout`, default 60, min 30, max 600. |
| `contents/code/RequestTimeout.js` | Create | Strict parse/default and seconds-to-milliseconds functions. |
| `contents/ui/config/configGeneral.qml` | Modify | Add native preset/custom controls, labels, accessible names, wrapping guidance, and one `cfg_requestTimeout` value. |
| `contents/ui/main.qml` | Modify | Resolve configuration and inject timeout milliseconds without changing refresh bindings. |
| `contents/ui/UsageController.qml` | Modify | Snapshot stage timeout and interpolate active command-stage seconds; preserve preflight text and lifecycle. |
| `tests/RequestTimeoutHarness.qml`, `tests/RequestTimeoutSettingsHarness.qml` | Create | Cover resolver/schema conversion and native preset/custom interaction/accessibility. |
| `tests/UsageControllerFixture.qml`, `tests/UsageControllerFailureHarness.qml`, `tests/UsageControllerLifecycleHarness.qml`, `tests/TimeoutFeedbackPopupHarness.qml` | Modify | Cover 120-second feedback, release/retry/snapshot/stale/coalescing regressions, and constrained 180-second copy. |
| `scripts/run-qml-tests.sh` | Modify | Admit the new and affected executable harnesses to the strict runner. |
| `README.md`, `docs/live-plasma-smoke.md` | Modify | Document bounds, fallback, refresh independence, retry, settings keyboard access, wrapping, and Breeze themes. |

No visual gallery extraction is included.

## Interfaces / Contracts

```javascript
RequestTimeout.parse(value)                 // integer 30..600 or null
RequestTimeout.secondsOrDefault(value)      // valid value or 60
RequestTimeout.millisecondsOrDefault(value) // resolved seconds * 1000
```

`UsageController.timeoutMs` remains the injected boundary. Stage start copies it to `activeTimeoutMs`; command timeout text uses `activeTimeoutMs / 1000`. The command remains exactly `usage --provider all --format json --json-only`.

## Testing Strategy

| Layer | RED-first proof | Approach |
|---|---|---|
| Unit | Presets, 30/600, missing, strings, NaN, fractions, 29/601, and millisecond conversion | New resolver harness, run by `./scripts/run-qml-tests.sh`. |
| Integration | KConfig/UI persistence; 120-second watchdog/message; distinct empty/malformed/nonzero/noData; retry, snapshot, overlap, and stale guards | Settings harness plus existing controller fixtures/harnesses; tests fail before production edits. |
| Visual/E2E | Wrapped 180-second copy in 240×210 geometry; labeled/focusable controls; Breeze light/dark | Popup offscreen harness plus manual live-Plasma smoke. No automated live-desktop claim. |

## Threat Matrix

| Boundary | Applicability | Safe/failure behavior and planned RED tests |
|---|---|---|
| Documentation-like paths | N/A — no classification/execution change. | None. |
| Git repository selection | N/A — no VCS integration. | None. |
| Commit state | N/A — no VCS integration. | None. |
| Push state | N/A — no VCS integration. | None. |
| PR commands | N/A — no PR automation. | None. |
| Process watchdog/callback | Applicable | Valid resolved milliseconds bound each stage; timeout releases only the current source, retains snapshots, and stale callbacks do nothing. RED tests cover fallback, 120-second timeout, exact text, release, retry, and stale completion. |

## Migration / Rollout

No migration or feature flag. Missing existing configuration resolves to 60. Deliver as one reversible unit estimated below the 800-line review budget; rollback removes the key, resolver, UI/wiring, tests, and docs without touching refresh data or CLI behavior.

## Open Questions

None.
