# Lifecycle Remediation Integrity Specification

## Purpose

Define acceptance boundaries for reconciling lifecycle documentation and strengthening standalone QML test evidence without changing production behavior or historical evidence.

## Requirements

### Requirement: Exit-code semantics reconciliation

Design and spec-facing remediation artifacts MUST state that usable structured stdout is parsed and may commit atomically when the command exits zero or nonzero. They MUST state that empty stdout remains Error and MUST NOT describe nonzero exit alone as requiring Error or discarding usable output.

#### Scenario: Usable stdout with nonzero exit

- GIVEN a command returns usable structured stdout and a numeric or numeric-string nonzero exit code
- WHEN remediation artifacts describe the terminal outcome
- THEN they identify the output as eligible for atomic commit, including provider errors
- AND they do not require production changes

#### Scenario: Empty stdout with nonzero exit

- GIVEN a command returns empty stdout and a nonzero exit code
- WHEN remediation artifacts describe the terminal outcome
- THEN they require Error with no output commit

### Requirement: Manual live-evidence provenance

The live Plasma smoke guide MUST permit manual `plasmawindowed` evidence when automation is infeasible. Each recorded observation MUST identify its source, execution context, observed outcome, and date or evidence reference. It MUST distinguish user-provided observation from verifier-run or fixture-backed evidence and MUST disclose that manual evidence is environment-specific, non-replayable, and does not prove automated coverage.

#### Scenario: Manual real-provider evidence

- GIVEN fixture-backed `plasmawindowed` automation is infeasible
- WHEN a real-provider manual observation is recorded
- THEN provenance and observed Ready behavior are documented
- AND limitations prevent it from being represented as automated or verifier-run evidence

#### Scenario: Insufficient provenance

- GIVEN a screenshot or statement lacks source or execution context
- WHEN it is considered for live lifecycle acceptance
- THEN the guide requires the missing provenance before treating it as evidence

### Requirement: Standalone harness assertion integrity

Every targeted standalone QML harness MUST prevent execution from reaching a success exit after an assertion has failed. A failed assertion MUST retain a nonzero process outcome; passing assertions MUST preserve existing harness behavior. Hardening MUST NOT alter production QML behavior.

#### Scenario: Failed assertion before success path

- GIVEN a harness assertion fails before its normal completion path
- WHEN later callback statements would otherwise execute
- THEN the harness cannot report a zero exit status

#### Scenario: Passing harness

- GIVEN all assertions in a targeted harness pass
- WHEN the harness completes normally
- THEN its existing success outcome and exercised production behavior remain unchanged

### Requirement: Historical artifact immutability

The remediation MUST preserve the historical provider-usage source spec and original FAIL verify report unchanged. The verify report MUST remain byte-for-byte identical, including its FAIL verdict, findings, hashes, formatting, and final newline. Reconciliation MUST be expressed only in new remediation artifacts and approved current documentation.

#### Scenario: Remediation completion

- GIVEN the remediation edits are complete
- WHEN historical artifact hashes are compared with their pre-change hashes
- THEN both historical files match exactly

#### Scenario: Conflicting historical text

- GIVEN historical wording conflicts with the approved remediation interpretation
- WHEN the conflict is documented
- THEN no historical bytes are edited and the reconciliation is recorded separately

## Acceptance Criteria

- Exit semantics are coherent across remediation design/spec-facing artifacts.
- Manual evidence provenance and limitations are explicit in `docs/live-plasma-smoke.md`.
- The full QML runner passes and a deliberately failing assertion cannot end with success.
- Historical spec and FAIL report hashes remain unchanged.
- Authored changes remain below the 800-line review budget.

## Boundaries and Non-Goals

- No production QML, provider, UI, timeout, command-boundary, or snapshot-policy changes.
- No forced fixture-backed `plasmawindowed` automation or new product scenarios.
- No rewrite, correction, archival merge, or verdict change for historical artifacts.
- Harness edits are limited to assertion-result integrity and MUST NOT broaden behavioral scope.
