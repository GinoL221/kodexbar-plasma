# Provider Cost Estimate Specification

## Purpose

Show optional CLI-reported cost for the selected provider without affecting usage.

## Requirements

### Requirement: Provider-specific cost contract

For a supported selected provider, the system MUST invoke exactly `cost --provider {provider} --format json --json-only` through the validated configured executable. A successful matching payload MUST render CLI-supplied `sessionCostUSD`, `sessionTokens`, `last30DaysCostUSD`, and `last30DaysTokens` only in selected detail and label `source: local` as a local token-cost estimate. It MUST NOT calculate prices.

#### Scenario: Matching local estimate
- GIVEN the selected provider returns a valid matching local payload
- WHEN cost completes
- THEN Session and 30-day cost/token values appear with local-estimate labeling

#### Scenario: All summary remains cost-free
- GIVEN one or more cost snapshots exist
- WHEN `All` is selected
- THEN no summary row displays cost or tokens

### Requirement: Independent correlated lifecycle

Cost MUST use provider- and usage-generation correlation independent of usage. Normal refresh SHOULD refresh applicable cost; selecting a provider MUST request it when missing or stale. Duplicate active requests MUST coalesce, and callbacks for an old provider or generation MUST be discarded.

#### Scenario: Refresh and selection reuse fresh data
- GIVEN matching cost is fresh or already loading
- WHEN refresh or provider selection requests it again
- THEN no duplicate concurrent request starts

#### Scenario: Stale callback is ignored
- GIVEN provider selection or usage generation changes during cost loading
- WHEN the old callback completes
- THEN it is discarded and cannot alter displayed cost or usage

### Requirement: Fail-closed optional rendering

Empty, malformed, unsupported, nonzero-exit, or unavailable cost results MUST hide the Cost section, preserve Usage unchanged, and MUST NOT expose raw diagnostics. Fixtures and capture documentation MUST record a redacted real cost payload, command, CLI version/date, source, and key/type fidelity; focused tests MUST cover command, correlation, coalescing, staleness, failures, and rendering.

#### Scenario: Cost fails independently
- GIVEN usable usage and a failed or invalid cost result
- WHEN selected detail renders
- THEN Usage remains available and Cost is absent without diagnostic leakage

#### Scenario: Contract evidence is verified
- GIVEN the documented redacted cost fixture
- WHEN the strict QML test runner executes
- THEN exact command and lifecycle cases pass against the recorded schema

## Non-Goals

Authentication, account actions, provider/CLI changes, pricing tables, QML estimation, diagnostics, and cost in `All` are excluded.
