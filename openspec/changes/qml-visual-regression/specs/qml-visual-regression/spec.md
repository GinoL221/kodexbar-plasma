# QML Visual Regression Specification

## Purpose

Define deterministic offscreen visual checks that supplement existing behavioral harnesses and manual live-Plasma validation.

## Requirements

### Requirement: Deterministic Selected-Provider Fixtures

The suite MUST render one selected provider from fixed synthetic data in a fixed `450x400` window with deterministic text and software rendering. It SHALL maintain exactly four initial goldens: Breeze Light/Dark, each with Cost present/absent.

#### Scenario: Canonical matrix
- GIVEN the documented fixture
- WHEN scenarios are enumerated
- THEN exactly the four selected-provider combinations MUST run

#### Scenario: Fixture drift
- GIVEN data or dimensions differ from documented values
- WHEN a visual run starts
- THEN it MUST fail before comparison

### Requirement: Theme Setup

Each scenario MUST establish its requested Breeze Light or Dark appearance before validation and capture, without implying live-Plasma equivalence.

#### Scenario: Theme unavailable
- GIVEN the requested appearance cannot be established
- WHEN initialization runs
- THEN it MUST fail with theme and scenario and MUST NOT capture

### Requirement: Structural Preconditions

Behavioral harnesses SHALL remain authoritative. Geometry and accessibility assertions MUST precede capture in both Cost states and verify visible bounds, non-clipping, and required accessible names or roles.

#### Scenario: Preconditions pass
- GIVEN valid selected-provider geometry and accessibility
- WHEN pre-capture checks run
- THEN capture MAY proceed

#### Scenario: Precondition fails
- GIVEN any required assertion fails
- WHEN pre-capture checks run
- THEN the scenario MUST fail before capture

### Requirement: Asynchronous Capture

The suite MUST use Qt Quick offscreen `grabToImage` and wait for explicit asynchronous completion.

#### Scenario: Capture completes
- GIVEN preconditions passed
- WHEN capture succeeds
- THEN the decoded image MUST be compared

#### Scenario: Capture fails
- GIVEN capture was requested
- WHEN it fails or exceeds the documented timeout
- THEN comparison and golden updates MUST NOT occur

### Requirement: Calibrated RGBA Comparison

The comparator MUST compare decoded RGBA pixels, not bytes or hashes, using a documented threshold calibrated from repeat runs. Failure MUST report expected/actual paths, mismatch count/ratio, threshold, theme, scenario, and an available diff path.

#### Scenario: Threshold evaluation
- GIVEN equal-dimension RGBA images
- WHEN mismatch ratio is calculated
- THEN the documented calibrated acceptance rule MUST determine the result

#### Scenario: Malformed baseline
- GIVEN a baseline is undecodable or dimensionally incompatible
- WHEN comparison starts
- THEN it MUST fail distinctly and identify that baseline

### Requirement: Golden Update Safety

Normal runs MUST NOT mutate goldens. Replacement MUST require `UPDATE_GOLDENS=1` and MUST be limited to canonical scenarios.

#### Scenario: Missing baseline
- GIVEN a baseline is missing without update mode
- WHEN its scenario runs
- THEN it MUST fail without creating the baseline

#### Scenario: Explicit update
- GIVEN `UPDATE_GOLDENS=1` and successful canonical capture
- WHEN update mode runs
- THEN only that scenario's golden MAY be replaced and reported

### Requirement: Dependency and Runner Isolation

`scripts/run-visual-tests.sh` MUST validate required tools, including Pillow, without installation or sudo. It MUST remain independent from the main behavioral runner initially.

#### Scenario: Pillow unavailable
- GIVEN Pillow cannot be imported
- WHEN the visual runner starts
- THEN it MUST stop before capture with actionable guidance

#### Scenario: Behavioral run
- GIVEN the behavioral runner is invoked
- WHEN visual dependencies are unavailable
- THEN behavioral execution MUST remain unaffected

### Requirement: CI and Documentation Boundaries

CI MAY report visual results but MUST remain non-blocking initially. `docs/visual-regression.md` MUST document fixtures, calibration, updates, dependencies, and artifacts, and link `docs/live-plasma-smoke.md` and `docs/ui-parity-checklist.md`. It MUST NOT claim production changes, `PlasmoidItem`, assistive-technology traversal, `plasmawindowed` automation, or live-Plasma certification.

#### Scenario: CI failure
- GIVEN the visual job fails
- WHEN CI reports checks
- THEN failure MUST be visible but MUST NOT gate merging

#### Scenario: Scope interpretation
- GIVEN a reader reviews visual coverage
- WHEN certification scope is assessed
- THEN documentation MUST direct them to live smoke and parity review
