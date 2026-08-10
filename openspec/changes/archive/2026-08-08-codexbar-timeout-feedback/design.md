# Design: Actionable CodexBar Timeout Feedback

## Technical Approach

Change only timeout feedback and tests. Preserve the 15-second watchdog, generations, snapshots, native surfaces, and authoritative all-provider command. README supplies the workaround.

## Architecture Decisions

| Option | Tradeoff | Decision and rationale |
|---|---|---|
| Generic exact message | No provider attribution | Choose because timeout callbacks carry no provider identity. |
| Isolation or probes | Changes acquisition | Reject; preserve `codexbar usage --provider all --format json --json-only`. |
| Existing lifecycle/UI | Text must wrap | Preserve snapshots and native label/Refresh to avoid accessibility churn. |

## Components, Data Flow, and File Changes

    watchdog → guarded Error → explicit Refresh → new Loading generation
                         └──── committed snapshot retained ────┘

| File | Action | Description |
|---|---|---|
| `contents/ui/UsageController.qml` | Modify | Replace only command-stage timeout text; preserve preflight timeout and lifecycle. |
| `tests/UsageControllerFixture.qml` | Modify | Add runner-enforced timeout, outcome, retry, and exclusion RED tests. |
| `tests/UsageControllerFailureHarness.qml`, `tests/RefreshIntervalHarness.qml` | Modify | Mirror failures; assert interval rejection/correction. |
| `README.md` | Modify | Document the 15-second boundary, bounded diagnostic, enabled-provider disable/retry workaround, and widget Refresh. |
| `docs/live-plasma-smoke.md` | Modify | Add narrow-popup, keyboard Refresh, and theme-readable timeout checks. |

`contents/ui/main.qml`, command construction, provider fetching, auth, fallback probing, and per-provider isolation remain unchanged.

## State and Message Contract

| Event | Observable contract |
|---|---|
| Current command reaches 15 seconds | `phase = "error"`; exact `CodexBar did not return all-provider usage within 15 seconds. Check enabled providers in CodexBar, temporarily disable a provider that hangs, then retry.`; release request; retain snapshot. |
| CLI completes with empty stdout | `phase = "error"`; exact `CodexBar CLI returned no output.`; timeout text is absent; snapshot is unchanged. |
| Valid parsed output has no usable data | `phase = "noData"`; show No data, clear transient error, and atomically commit the normalized empty snapshot. |
| Malformed JSON or nonzero exit | Recoverable `phase = "error"` with existing parser/exit feedback; Refresh remains available and committed snapshot is unchanged. |
| User activates Refresh after timeout | One new generation starts in `loading`, clears transient error text, and retains the snapshot. Existing overlap coalescing permits at most one follow-up. |
| Stale timeout/completion | Ignored by existing request identity and generation guards. |

## Testing Strategy and Strict TDD

| Phase | Spec mapping | Proof |
|---|---|---|
| RED | Timeout and empty stdout | Fixture asserts both exact messages; `./scripts/run-qml-tests.sh` fails on old timeout copy. |
| RED | Retry after timeout | Seed data; assert retention, Refresh generation `+1`, `loading`, and one request through the runner. |
| RED | Valid parsed empty response | Fixture completes with `[]`; assert `noData`, cleared error, and atomic empty commit. |
| RED | Malformed JSON/nonzero exit | Fixture seeds a snapshot, submits each failure, then asserts recoverable Error, Refresh availability, and no replacement. |
| RED | Invalid refresh interval | Interval harness drives `0`, `-1`, nonnumeric, and fractional values; assert rejection plus valid-default/range correction guidance. |
| RED | Provider/auth/probing exclusions | Fixture asserts exact generic message and fixed command; timeout leaves generation unchanged and zero active requests until explicit Refresh, proving no attribution, auth, alternate request, or fallback probe. |
| GREEN/REFACTOR | Full mapping | Change only copy; run the script, then failure, compact, lifecycle, and interval qml6 harnesses; manually verify narrow keyboard/theme behavior. |

## Threat Matrix

| Boundary | Applicability | Safe/failure behavior and planned RED test |
|---|---|---|
| Documentation-like paths | N/A — no file classification/execution change. | None. |
| Git repository selection | N/A — no VCS integration. | None. |
| Commit state | N/A — no VCS integration. | None. |
| Push state | N/A — no VCS integration. | None. |
| PR commands | N/A — no PR automation. | None. |
| Process watchdog/callback | Applicable | Timeout releases its source, emits generic Error, and retains snapshots; stale generations do nothing. RED tests cover timeout, stale completion, retry, and empty stdout. |

## Documentation, Rollout, and Review Unit

README bounds the unchanged command, then directs users to provider controls, temporary disablement, rerun, and Refresh; no auth, attribution, probes, or CLI changes.

No migration or flag. Deliver one reversible unit below 800 lines; no chain. Roll back these files without persisted-data or CLI changes.

## Risks

- Provider controls are version-dependent.
- Exact copy needs narrow-layout checks.
- Child termination semantics remain unchanged.
- Unrelated changes require isolated staging.

## Open Questions

None.
