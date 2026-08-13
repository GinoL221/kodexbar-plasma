# Proposal: Persistent DataSource Lifecycle Closeout

## Intent

Create a bounded administrative closeout that reconciles the current committed baseline (`d027c1e` plus `dca2671`) with current automated evidence, the incremental native review receipt, and the user-provided live Plasma observation. This is an evidence record only: it introduces no capability, changes no production source, and does not retroactively approve the original lifecycle candidate.

The original `persistent-datasource-lifecycle/verify-report.md` remains an authoritative historical `FAIL` (0/4 requirements, 10/14 scenarios) and must be cited without rewriting, superseding, or reclassifying it.

## Scope

### In Scope
- Record the clean final baseline and current automated evidence: 27 QtTest assertions, 16 executable QML harnesses, and passing `git diff --check`.
- Classify the incremental approved native receipt `review-bf49b254cb6fa962` as evidence for `d027c1e..dca2671` only.
- Preserve provenance and limits of the recorded live `plasmawindowed` observation, including populated provider rows and compact `100%`.
- Produce closeout artifacts that can be freshly verified and archived from the current baseline.

### Out of Scope
- Any production, test, documentation, configuration, commit, or historical-artifact modification.
- Reopening, unblocking, approving, or archiving `persistent-datasource-lifecycle`.
- Treating manual Plasma evidence as automated host acceptance.

## Capabilities

### New Capabilities
None. This is an administrative evidence reconciliation.

### Modified Capabilities
None. No product requirement changes.

## Approach

Create concise closeout specs/design/tasks and a fresh verification report that separate four evidence classes: committed state, automated suite, incremental review receipt, and user-provided live observation. Verification must assert the historical FAIL remains unchanged and that only the closeout change is eligible for archive.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `openspec/changes/persistent-datasource-lifecycle-closeout/` | New | Closeout evidence artifacts only. |
| `openspec/changes/persistent-datasource-lifecycle/verify-report.md` | Preserved | Historical FAIL remains immutable and blocked. |
| `scripts/run-qml-tests.sh`, `docs/live-plasma-smoke.md` | Evidence only | Referenced for current boundaries; not modified. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Conflating incremental approval or manual observation with original acceptance | High | Label each evidence class and retain the historical FAIL explicitly. |
| Stale counts or claims exceed current evidence | Med | Re-run and hash current evidence during closeout verification. |

## Rollback Plan

Delete or revert only the closeout artifact folder. Do not touch production source or the original lifecycle artifacts.

## Dependencies

- Current clean baseline, native review receipt, and available configured test runner.

## Success Criteria

- [ ] Closeout verification passes against the current baseline and evidence classifications.
- [ ] Only the closeout folder is archived; the original lifecycle change remains active and blocked.
- [ ] No retroactive approval or production behavior change is claimed.
