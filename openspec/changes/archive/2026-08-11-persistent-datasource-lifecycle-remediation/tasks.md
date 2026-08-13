# Tasks: Persistent DataSource Lifecycle Remediation

## Dependencies

- Read `proposal.md`, `specs/remediation-integrity/spec.md`, and `design.md` before implementation.
- Preserve the historical `persistent-datasource-lifecycle` design, source spec, and verify report byte-for-byte.
- Do not modify production QML, the CLI/provider boundary, timeout policy, snapshot behavior, or the termination harness.

## Implementation Tasks

- [x] 1.1 Capture baseline SHA-256 values for the historical design, provider spec, and FAIL report; record the values in apply evidence and define a check-only comparison command.
- [x] 1.2 Add the accepted nonzero-exit contract to the remediation documentation: usable structured stdout commits atomically for zero or nonzero exit; empty stdout remains Error with no commit. Do not edit historical artifacts.
- [x] 1.3 Update `docs/live-plasma-smoke.md` with a manual-evidence record template covering evidence class, observer/source, command and Plasma/runtime context, Ready outcome, visible provider rows, compact summary, date/reference, and explicit automation limitations.
- [x] 1.4 Add a RED probe proving the legacy harness assertion pattern can continue after a failed assertion and reach a success exit.
- [x] 1.5 Strengthen the shared assertion helper pattern in the 15 helper-based harnesses so a failed assertion latches failure, requests `Qt.exit(1)`, and throws to stop the callback; preserve `finish()` as the final exit gate.
- [x] 1.6 Add a GREEN probe proving the strengthened helper exits nonzero after a failed assertion and cannot reach normal success completion.
- [x] 1.7 Statically verify all 15 helper-based harnesses use the strengthened pattern and that `UsageControllerTerminationHarness.qml` remains unchanged because it has no assertion helper.
- [x] 1.8 Run focused probes for the assertion hardening and verify normal passing harness behavior remains unchanged.
- [x] 1.9 Run `./scripts/run-qml-tests.sh` and record exit status, QtTest outcomes, standalone harness outcomes, and known non-failing offscreen warnings.
- [x] 1.10 Run `git diff --check` and verify that only the approved documentation and harness files changed; no production QML or historical artifact changed.
- [x] 1.11 Persist apply evidence with baseline/final hashes, test results, provenance documentation, rollback boundary, and explicit confirmation that the historical FAIL remains byte-identical.

## Work Units and Rollback

1. Documentation reconciliation (`design.md` in this change and `docs/live-plasma-smoke.md`).
2. Assertion helper RED/GREEN probes and 15-harness hardening.
3. Full verification and historical-integrity evidence.

Rollback removes only the remediation documentation and harness-helper/probe changes. It never modifies production QML or historical lifecycle artifacts.

## Review Workload Forecast

- Estimated authored lines: 50–100.
- 800-line review budget risk: Low.
- Chained PRs recommended: No.
- Decision needed before apply: No.
