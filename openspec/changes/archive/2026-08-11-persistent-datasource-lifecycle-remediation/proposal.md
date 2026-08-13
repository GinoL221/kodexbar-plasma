# Proposal: Persistent DataSource Lifecycle Remediation

## Intent

Reconcile the remediation documentation with the already-resolved implementation and approved provider semantics, while hardening QML harnesses against future assertion masking. Preserve the historical FAIL report byte-for-byte as historical evidence; this change documents the reconciliation separately.

## Scope

### In Scope
- Reconcile nonzero-with-usable-stdout semantics in `openspec/changes/persistent-datasource-lifecycle/design.md`.
- Record live Plasma evidence provenance and limitations in `docs/live-plasma-smoke.md`.
- Add preventive assertion-failure guards across the standalone QML harnesses.
- Document existing connection-scoped generation and snapshot-retention coverage without changing production behavior.

### Out of Scope
- Production QML changes, including `contents/ui/UsageController.qml`.
- Rewriting `openspec/changes/persistent-datasource-lifecycle/verify-report.md` or other historical artifacts.
- Forced fixture-backed `plasmawindowed` automation.
- Provider/UI/timeout redesign, spec reversion, or new scenario coverage.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- None. This is documentation reconciliation and harness assertion hardening; the existing behavioral requirements remain authoritative.

## Approach

Update `design.md` so its coherence table agrees with its interfaces and the provider-usage spec: usable structured stdout may commit despite a nonzero exit, while empty stdout remains Error. Clarify in `docs/live-plasma-smoke.md` that manual `plasmawindowed` evidence is acceptable when automation is infeasible, including provenance and limitations. Add minimal guard clauses to harness progression paths so failed assertions cannot be followed by success exits. Verify the full harness runner and retain the original FAIL report unchanged.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `openspec/changes/persistent-datasource-lifecycle/design.md` | Modified | Semantic reconciliation and existing-coverage explanation. |
| `docs/live-plasma-smoke.md` | Modified | Evidence provenance and limitations. |
| `tests/*Harness.qml` | Modified | Preventive assertion guards; no production behavior change. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Harness guard typo | Low | Review each harness and run the full runner. |
| Reconciliation mistaken for history rewrite | Low | Leave historical reports untouched; document separately. |
| Reviewer expects automated Plasma coverage | Low | Cite the spec allowance and state runtime limitations. |

## Rollback Plan

Revert this change's documentation edits and harness guard additions as one reviewable change. Historical artifacts and production source remain unchanged.

## Dependencies

- Existing provider-usage requirements, harness runner, and available manual Plasma evidence.

## Success Criteria

- [ ] `design.md` and `docs/live-plasma-smoke.md` explicitly reconcile the approved semantics and evidence path.
- [ ] All targeted harnesses retain nonzero failure status after assertion failures.
- [ ] Original historical FAIL report is byte-for-byte unchanged.
- [ ] Total change remains approximately 50–100 lines and below the 800-line review budget.
