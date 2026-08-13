# Closeout Evidence Specification

## Purpose

Define the administrative evidence required to close and archive this reconciliation without changing production behavior or the historical lifecycle verdict.

## Requirements

### Requirement: Final committed baseline identity

The closeout record MUST identify the final committed baseline as `d027c1e` followed by `dca2671`, and MUST record whether the verification worktree is clean.

#### Scenario: Baseline identity is verified

- GIVEN closeout verification runs from the intended repository
- WHEN the committed revision and worktree state are captured
- THEN the evidence identifies `d027c1e` plus `dca2671` and a clean worktree

#### Scenario: Baseline does not match

- GIVEN either commit identity is absent or the worktree is not clean
- WHEN archive eligibility is evaluated
- THEN the closeout MUST remain ineligible for archive

### Requirement: Current automated test evidence

The closeout record MUST cite `./scripts/run-qml-tests.sh` as the current automated command and MUST report exactly 27 passing QtTest assertions—8 UsageModel, 12 UsageControllerFixture, and 7 SettingsInteraction—and 16 successful executable QML harnesses. It MUST NOT claim that this command automates live Plasma host acceptance.

#### Scenario: Current suite matches expected counts

- GIVEN the configured test command is executed on the final baseline
- WHEN it exits successfully with the exact assertion and harness counts
- THEN those counts are recorded as offscreen automated-suite evidence

#### Scenario: Counts drift

- GIVEN the command or any count differs from the required values
- WHEN verification evaluates the result
- THEN archive eligibility MUST be denied until the record reflects fresh evidence

### Requirement: Git diff validation

The closeout verification MUST run `git diff --check` and MUST require a successful exit before archive.

#### Scenario: Diff check succeeds

- GIVEN the final baseline is selected
- WHEN `git diff --check` runs
- THEN its successful result is recorded as closeout evidence

### Requirement: Incremental review receipt scope

The closeout record MUST identify approved receipt `review-bf49b254cb6fa962`, snapshot `sha256:bf49b254cb6fa9623c450514ed71b949550b90ee772b5cbc75c1bcfe2f8af518`, and reviewed range `d027c1e..dca2671`. It MUST constrain that approval to the four accessibility/harness files in that increment and MUST NOT extend it to the original lifecycle candidate.

#### Scenario: Receipt is scoped correctly

- GIVEN the approved native receipt is cited
- WHEN its evidentiary scope is stated
- THEN only `d027c1e..dca2671` is classified as reviewed

### Requirement: Manual live Plasma evidence provenance

The closeout record MUST classify the `apply-progress.md` observation of real-provider `plasmawindowed`, populated provider rows, and compact `100%` as user-provided manual evidence. It MUST NOT describe this observation as automated or verifier-executed host acceptance.

#### Scenario: Manual provenance is preserved

- GIVEN the live observation is included
- WHEN its provenance and limits are recorded
- THEN it remains manual corroboration distinct from automated evidence

### Requirement: Original lifecycle FAIL preservation

The closeout MUST preserve `persistent-datasource-lifecycle/verify-report.md` unchanged as an admitted `FAIL` with 0/4 requirements and 10/14 compliant scenarios. Later evidence MUST NOT rewrite, supersede, or reinterpret that verdict as PASS.

#### Scenario: Historical verdict remains authoritative

- GIVEN current tests or incremental review pass
- WHEN the original lifecycle report is referenced
- THEN its FAIL verdict and blocked status remain explicit and unchanged

### Requirement: Closeout-only archive eligibility

Only the `persistent-datasource-lifecycle-closeout` artifacts MAY become archive-eligible, and only after fresh verification satisfies every requirement in this specification. The original `persistent-datasource-lifecycle` change MUST remain active and blocked.

#### Scenario: Closeout qualifies for archive

- GIVEN all baseline, command, count, diff, receipt, provenance, and preservation checks pass
- WHEN closeout archive eligibility is evaluated
- THEN only the closeout artifact folder is eligible for archive

#### Scenario: Evidence is incomplete or conflated

- GIVEN any required evidence is missing or exceeds its stated scope
- WHEN archive eligibility is evaluated
- THEN the closeout MUST remain ineligible and the original change MUST remain blocked
