# Proposal: Actionable CodexBar Timeout Feedback

## Intent

Make the 15-second all-provider timeout understandable and recoverable. Users should know the boundary, workaround, and retry path without losing committed usage data. The UI remains provider-neutral because timeout callbacks contain no provider attribution.

## Scope

### In Scope
- Replace timeout copy with actionable generic guidance: check enabled CodexBar providers, temporarily disable a hanging provider, and retry.
- Preserve the watchdog, external CLI boundary, lifecycle, concurrency, generation, and snapshot behavior.
- Document the bounded workaround in `README.md` and add QML coverage.

### Out of Scope / Non-goals
- Per-provider isolation, attribution, fetch redesign, auth, CLI changes, or fallback probing.
- Naming Claude in runtime UI; any Claude reference in documentation must be explicitly environment-specific.

## Business Rules and Observable Outcomes

- Timeout means the all-provider request did not finish within 15 seconds; it is distinct from empty stdout (`CodexBar CLI returned no output.`).
- Popup shows the actionable error and Refresh remains available.
- Refresh after timeout is a new attempt: state returns to Loading, generation increments, and any prior committed snapshot remains visible/retained until replacement.
- No provider identity may be inferred from the timeout.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `provider-usage-display`: clarify actionable timeout feedback, distinct empty-output handling, and retry/snapshot semantics.

## Approach

Update `UsageController.qml` timeout text, using existing native Plasma/Kirigami error and Refresh surfaces. Extend harnesses for wording, retry generation, snapshot retention, and empty-output distinction. Add README troubleshooting and, if useful, a manual smoke check. Follow strict TDD with `./scripts/run-qml-tests.sh`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/ui/UsageController.qml` | Modified | Actionable generic timeout message; preserve lifecycle. |
| `tests/UsageControllerFixture.qml` | Modified | Timeout, retry, and generation assertions. |
| `tests/UsageControllerFailureHarness.qml` / `tests/MainCompactHarness.qml` | Modified | Snapshot-retention/user-visible coverage as needed. |
| `README.md` | Modified | Bounded diagnostic and provider-toggle workaround. |
| `docs/live-plasma-smoke.md` | Optional | Manual timeout/retry and narrow-layout check. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Upstream provider behavior changes | Med | Keep workaround generic and bounded; do not alter CLI behavior. |
| Copy regression or stale snapshot loss | Low | Focused executable harness assertions. |

## Rollback Plan

Revert the proposal's QML, documentation, and test changes. Existing timeout handling, refresh behavior, and CLI invocation remain recoverable without migration.

## Dependencies

- Existing CodexBar enabled-provider controls and `scripts/run-qml-tests.sh`.

## Success Criteria

- [ ] Popup timeout copy explains the 15-second all-provider boundary and workaround without naming a provider.
- [ ] Empty stdout remains a distinct error.
- [ ] Retry, generation, and committed-snapshot behavior are executable-test verified.
- [ ] README documents the bounded diagnostic and retry path.
