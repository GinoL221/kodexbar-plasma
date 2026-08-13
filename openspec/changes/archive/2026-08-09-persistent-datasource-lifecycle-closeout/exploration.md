## Exploration: Persistent DataSource Lifecycle Closeout

### Current State
This is an administrative reconciliation, not a product redesign. The final committed state is `d027c1e` plus `dca2671`; the working tree is clean. The current suite passes: 27 QtTest assertions (8 UsageModel, 12 UsageControllerFixture, 7 SettingsInteraction) and 16 executable QML harnesses; `git diff --check` also passes. The settings suite still emits offscreen `i18n`/`i18np` warnings.

Evidence must remain separate:
- **Live product evidence:** `apply-progress.md` records a user-provided real-provider `plasmawindowed` observation with populated rows and compact `100%`; `docs/live-plasma-smoke.md` remains a manual, non-automated checklist. This exploration did not execute Plasma-host acceptance.
- **Automated-suite evidence:** the current runner proves the offscreen QtTest and executable-harness scope, including fixture argv and PID-termination checks. It does not prove live Plasma host behavior.
- **Incremental review evidence:** native `gentle-ai review status` reports authoritative approved state for `review-bf49b254cb6fa962`, snapshot `sha256:bf49b254cb6fa9623c450514ed71b949550b90ee772b5cbc75c1bcfe2f8af518`. Its reviewed increment is `d027c1e..dca2671` (four accessibility/harness files), not the original lifecycle candidate.
- **Historical original-SDD candidate:** `persistent-datasource-lifecycle/verify-report.md` remains an admitted `FAIL` (0/4 requirements, 10/14 scenarios) for its historical evidence revision. Native SDD status still reports verify/archive blocked. Later suite and incremental-review evidence do not make that old report pass retroactively.

### Affected Areas
- `openspec/changes/persistent-datasource-lifecycle-closeout/exploration.md` — records the bounded evidence classification for the new closeout change.
- `openspec/changes/persistent-datasource-lifecycle/verify-report.md` — historical failed candidate that must be cited, not rewritten.
- `openspec/changes/persistent-datasource-lifecycle/apply-progress.md` — source of recorded manual live observation and later remediation history.
- `scripts/run-qml-tests.sh` and `docs/live-plasma-smoke.md` — define the current automated and manual evidence boundaries.

### Approaches
1. **Evidence-only closeout** — Create small closeout artifacts that classify the final baseline evidence and explicitly retain the original failed SDD record.
   - Pros: Truthful, observable, source-free, and preserves audit history.
   - Cons: Does not archive or unblock the original lifecycle change.
   - Effort: Low.

2. **Retroactive original-change archive** — Treat the current passing suite and incremental approval as acceptance of the historical lifecycle candidate.
   - Pros: Produces a single archived lifecycle folder.
   - Cons: Falsely changes the meaning of the admitted FAIL and exceeds the evidence scope.
   - Effort: Low, but unacceptable.

### Recommendation
Use evidence-only closeout. Define success as a concise proposal/spec/design/tasks set that records the four evidence classes, cites exact revisions and commands, and states that only the closeout reconciliation may be archived. Keep `persistent-datasource-lifecycle` active and historically blocked unless an authority-valid separate process resolves it.

### Risks
- Conflating the approved four-file incremental review with acceptance of the original lifecycle candidate.
- Treating recorded manual Plasma observation as verifier-run automated host coverage.
- Copying stale counts or the old FAIL verdict into a claim about the current automated suite.

### Ready for Proposal
Yes — propose an evidence-only administrative closure with no source, test, documentation, or historical-artifact modification; its observable output is a reconciliation record, not a retroactive pass or archive of the original change.
