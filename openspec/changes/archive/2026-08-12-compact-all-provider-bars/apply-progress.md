# Apply Progress: Compact All-Provider Usage Bars

## Artifact Store and Scope

| Field | Value |
|---|---|
| Change | `compact-all-provider-bars` |
| Mode | Strict TDD |
| Artifact store | Hybrid (OpenSpec + Engram) |
| Archival path | `openspec/changes/archive/2026-08-12-compact-all-provider-bars/` |
| Apply evidence source | Cumulative Engram artifact `sdd/compact-all-provider-bars/apply-progress` |

OpenSpec had no apply-progress artifact at verification time. This repository-local file is the cumulative archival mirror of the complete Engram apply-progress record; it does not claim a separate apply execution.

## Task Completion

- 14/14 original implementation tasks complete.
- The bounded remediation work unit `bounded-remediation-all-summary-non-expandable` is complete.
- Production behavior remained unchanged during the remediation; only focused runtime coverage was added to `tests/ProviderRowHarness.qml`.

## Cumulative TDD Evidence

| Area | Evidence | Result |
|---|---|---|
| Representative selector | `tests/UsageModelTest.qml` covers Session priority, Weekly/Monthly fallback, invalid values, and no-finite fallback | 11 passed |
| Summary component | `tests/ProviderRowHarness.qml` covers one bar, identity-only fallback, reset-field hiding, and preserved detail rows | Passed |
| All integration | `tests/MainCompactHarness.qml` covers per-provider representatives separately from global compact selection | Passed |
| Documentation | `docs/live-plasma-smoke.md` and `git diff --check` | Updated; check passed |
| Remediation | `ProviderRowHarness.qml` activates an `All` summary row and verifies no expansion | Passed |

The remediation added `activeSummaryRow`, subtree-count helpers, hidden-reset-label assertions, and an activation attempt with `forceActiveFocus()`. Offscreen QPA does not deliver active focus to items, so the evidence asserts the normative result, no expansion, rather than `activeFocus` state.

## Work Unit Evidence

- Focused command: `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/ProviderRowHarness.qml` exited 0.
- Full runner: `./scripts/run-qml-tests.sh` exited 0 with 35 QtTest cases and 18 executable QML harness flows, 53 passing cases/flows total.
- Rollback boundary: revert only `tests/ProviderRowHarness.qml` for the bounded remediation; production code is unchanged.

## Native Attempt Record

- CLI version: gentle-ai 2.3.0.
- The remediation native attempt passed with 43/200 changed lines.
- `sdd-attempt settle` returned `invalid_continuation`; the native `finish` action closed the attempt successfully.

## Known Limitations and Drift

- The apply evidence is historical and does not represent current HEAD verification.
- The design names `UsageModelHarness.qml` for selector assertions, while the runtime assertions are in `UsageModelTest.qml`.
- The design says the runner needs no change, while the historical working tree included one harness registration change; runtime behavior was green.
- Live Breeze Light/Dark, real keyboard delivery, and narrow-layout checks were not independently executed in a real Plasma session.
- No QML coverage tool, linter, or type checker was configured.
- Later commits, especially `d4a96b1`, are outside this evidence scope. No missing test command or hash is inferred here.

## Archival Outcome

The cumulative apply evidence is now represented locally beside the archived proposal, spec, design, tasks, and verify-report. This record preserves the Engram/OpenSpec split and makes no claim that a native archive command was run.
