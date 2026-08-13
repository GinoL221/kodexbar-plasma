# Design: Persistent DataSource Lifecycle Remediation

## Technical Approach

Treat this as acceptance-only remediation. Document the approved command outcome contract in this new artifact, formalize manual live-evidence provenance, and make assertion failure fail-fast in the existing standalone harness helpers. Production QML and the historical lifecycle design, source spec, and FAIL report remain byte-for-byte unchanged.

## Architecture Decisions

| Option | Tradeoff | Decision |
|---|---|---|
| Reconcile the historical design in place | Removes its contradiction but rewrites historical context | Reject. The approved scope supersedes the proposal's earlier path; record reconciliation here. |
| Treat any nonzero exit as Error | Simple, but contradicts the approved provider contract and current behavior | Reject. Usable structured stdout may commit atomically for zero or nonzero exit; empty stdout is Error with no commit. |
| Keep only the current failure latch | Already prevents direct `Qt.exit(0)` today, but later callback statements still run | Strengthen. On failed `assert`, latch failure, request `Qt.exit(1)`, then throw to abort the callback; retain `finish()` as the final status gate. |
| Require automated `plasmawindowed` evidence | Replayable but unavailable in some Plasma/CI contexts | Reject. Permit manual evidence with mandatory provenance and explicit limitations. |

## Data Flow

```text
command stdout -> usable structured output -> atomic provider/error commit (exit 0 or nonzero)
               -> empty output             -> Error; retain snapshot

assert(false) -> log + latch -> Qt.exit(1) -> throw -> callback stops
all pass      -> finish() -> Qt.exit(0)
```

## Exit-code contract

The approved provider contract is:

- Usable structured stdout is parsed and may commit atomically when the command exits zero or nonzero.
- Empty stdout remains Error and MUST NOT commit any output.
- A nonzero exit code alone does not require Error or discard usable output.

This contract is documented in this remediation artifact only; the historical provider-usage source spec and FAIL verify report are preserved byte-for-byte.

## File Changes

| File | Action | Description |
|---|---|---|
| `openspec/changes/persistent-datasource-lifecycle-remediation/design.md` | Create | Record accepted semantics, integrity boundaries, and verification plan. |
| `docs/live-plasma-smoke.md` | Modify | Add an evidence-record template: source/classification, execution context, observed outcome, and date/reference; state manual evidence is environment-specific, non-replayable, and not automated coverage. |
| `tests/{CompactUsageButton,ErrorSummary,MainCompact,ProviderRow,RefreshInterval,RequestTimeout,RequestTimeoutSettings,TimeoutFeedbackPopup,UsageController,UsageControllerDataSourceLifecycle,UsageControllerFailure,UsageControllerLifecycle,UsageControllerPathCheck,UsageControllerPreflight,UsageModel}Harness.qml` | Modify | Apply the same fail-fast assertion helper; preserve passing flows and existing timeout `Qt.exit(1)` paths. |
| `openspec/changes/persistent-datasource-lifecycle/{design.md,specs/provider-usage-display/spec.md,verify-report.md}` | Protect | Read-only historical evidence; hash before and after remediation. |

`tests/UsageControllerTerminationHarness.qml`, `scripts/run-qml-tests.sh`, and all production files are unchanged.

## Interfaces / Contracts

The assertion helper keeps `assertionFailed` and `finish() { Qt.exit(assertionFailed ? 1 : 0) }`. Its failure branch logs, sets the latch, requests nonzero exit, and throws; this prevents subsequent callback statements from reaching normal completion.

A manual evidence record is admissible only with: evidence class (`user-provided`, `verifier-run`, or `fixture-backed`), observer/source, command path and Plasma/runtime context, observed Ready outcome (including visible rows/compact summary and no stuck Loading), and date or stable evidence reference. Missing provenance is not acceptance evidence.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Harness unit | Failure cannot be masked; passing behavior is unchanged | RED: temporary legacy-helper probe demonstrates failure followed by success can exit zero. GREEN: strengthened-helper probe must exit nonzero; statically confirm all 15 helpers match and no direct `Qt.exit(0)` exists. |
| Integration | Existing controller/model/UI behavior | Run `./scripts/run-qml-tests.sh`; require every normal harness and QtTest suite to pass. |
| Acceptance | Documentation and historical integrity | Review semantics/provenance fields; compare SHA-256 before and after. |

## Threat Matrix

| Boundary | Applicability | Safe/failure behavior | Planned RED tests |
|---|---|---|---|
| Documentation-like paths | N/A — no executable classification | No path is executed by this change | None |
| Git repository selection | N/A — no repository routing | Current repository remains authoritative | None |
| Commit state | N/A — no commit automation | No index mutation | None |
| Push state | N/A — no push automation | No remote mutation | None |
| PR commands | N/A — no PR automation | No PR command composition | None |
| QML process exit | Applicable | Failed assertion exits nonzero and aborts its callback; passing harness exits zero | Legacy masking probe, then fail-fast probe |

## Migration / Rollout

No migration required. Baseline hashes are: historical design `d7ecbc71b88d538d5acb9e25beb770bf60c66d567dbfb5bb7bdfd698ab86610a`; source spec `2750a345f0a6ca5670c52f5f97481f7154557a6143b6c63130f9b60bd072caf7`; FAIL report `a662864cec2edcedf3a5b8aa030cddce75f300487b27748cb52a5bb8e7b5a6e3`. Any mismatch blocks acceptance. Roll back only smoke-guide and harness-helper edits; never roll back production or alter historical evidence. Expected authored change is below 100 lines and low risk against the 800-line budget.

## Non-Goals

No production QML, command/provider/UI/timeout/snapshot change; no historical correction; no forced fixture-backed Plasma automation; no new product scenarios; no runner or termination-harness redesign.

## Open Questions

None.
