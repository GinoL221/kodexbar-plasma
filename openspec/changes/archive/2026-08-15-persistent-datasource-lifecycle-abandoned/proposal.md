# Proposal: Persistent DataSource Lifecycle

## Intent

Fix the live Plasma lifecycle failure where successful executable preflight is followed by a command source that never delivers data, leaving the UI in Loading until timeout. Prioritize reliable complete all-provider data while preserving the existing CLI boundary, timeout behavior, snapshots, and concurrency semantics.

## Scope

### In Scope
- Replace request-scoped dynamic executable objects with persistent, stage-specific `DataSource` children for preflight and the authoritative all-provider command.
- Add explicit stage, source, active-state, and generation guards so stale or incorrect callbacks cannot commit data; rely on release-before-disconnect and the termination proof to invalidate reused-source callbacks.
- Add regression coverage for successful preflight-to-command completion, release termination, stale callbacks, retained snapshots after path failure, and documented live Plasma smoke acceptance.

### Out of Scope
- Changes to the CLI command, providers, timeout configuration or text, data model, or UI redesign.
- Provider isolation, authentication, probing, fetching, or changes to refresh/coalescing policy.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `provider-usage-display`: DataSource lifecycle MUST reliably complete the validated all-provider request, show Loading until completion or configured timeout, and retain the last valid snapshot after failure.

## Approach

Declare persistent preflight and command `Plasma5Support.DataSource` children in `UsageController.qml`. Activate one stage at a time; disconnect and invalidate logical activity before release, and queue any coalesced follow-up only after release. Keep the exact quoted `test -x` preflight and `usage --provider all --format json --json-only` command unchanged. Use RED-first QML fixtures and executable lifecycle harnesses, retaining disconnect-termination proof and adding a `plasmawindowed` smoke check.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/ui/UsageController.qml` | Modified | Persistent stage lifecycle and callback guards. |
| `tests/UsageControllerFixture.qml` | Modified | Sequencing and stale-callback contracts. |
| `tests/*Lifecycle*`, `tests/UsageControllerTerminationHarness.qml` | Modified/New | Real executable lifecycle and termination coverage. |
| `scripts/run-qml-tests.sh`, `docs/live-plasma-smoke.md` | Modified | Harness admission and live acceptance guidance. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Persistent objects weaken identity-based stale detection. | Med | Gate callbacks with active state, stage, source, and generation; release metadata before disconnect and prove executable termination before reconnect. |
| Offscreen tests miss Plasma-host behavior. | Med | Require equivalent `plasmawindowed` smoke acceptance. |

## Rollback Plan

Revert the controller, focused tests, harness script, and smoke-documentation changes together. The unchanged command and persisted settings require no migration.

## Dependencies

- Existing Plasma `DataSource` support and QML test infrastructure.

## Success Criteria

- [ ] A successful preflight reaches Ready with complete all-provider data and no stuck Loading state.
- [ ] Loading persists until completion or configured timeout; failures retain the last valid snapshot.
- [ ] `./scripts/run-qml-tests.sh` passes, and documented manual live Plasma evidence demonstrates Ready without stuck Loading within the 800-line review budget.
