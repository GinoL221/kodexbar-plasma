# Provider Usage Display Specification

## Purpose

Show external `codexbar` CLI usage without reimplementing CLI responsibilities.

## Requirements

### Requirement: Authoritative all-provider request

Refresh MUST invoke the configured absolute CLI path with `usage --provider all --format json --json-only`. The plasmoid MUST NOT probe fallbacks or perform account actions.

#### Scenario: Valid request
- GIVEN an executable absolute CLI path
- WHEN refresh starts
- THEN one all-provider usage request is issued

#### Scenario: Invalid path
- GIVEN a missing, relative, or non-executable CLI path
- WHEN configuration is saved or refresh is requested
- THEN the request is blocked and an actionable error is shown

### Requirement: Provider presentation

The popup MUST list usable providers in CLI order, show raw `source` values exactly, and show available Session, Weekly, and Monthly windows. Missing windows MUST be omitted. Reset values MUST be exact and informational.

#### Scenario: Heterogeneous providers
- GIVEN providers with nullable source, windows, reset fields, or unknown icons
- WHEN results are displayed
- THEN values are preserved, absent fields are omitted, and a themed fallback icon is used

### Requirement: Deterministic compact summary

The compact view MUST select the highest finite percentage. Ties MUST prefer Session, Weekly, Monthly, then the first provider in CLI order.

#### Scenario: Percentage tie
- GIVEN equal highest percentages across windows or providers
- WHEN compact selection runs
- THEN the required window and provider order determines the result

#### Scenario: Invalid percentage
- GIVEN null, nonnumeric, or non-finite percentages
- WHEN compact selection runs
- THEN they are ignored and no percentage is invented

### Requirement: Global states and CLI failures

The UI MUST expose Loading, Error, and No data. Malformed JSON, timeout, and nonzero exit MUST produce recoverable Error without accepting invalid output; a valid empty response MUST produce No data.

#### Scenario: Request lifecycle
- GIVEN no newer successful result
- WHEN a request loads, times out, exits nonzero, or returns malformed output
- THEN Loading or Error and manual refresh remain available

#### Scenario: Empty response
- GIVEN a successful valid response with no usable data
- WHEN it is normalized
- THEN compact and popup surfaces show No data

### Requirement: Mixed provider failures

Usable providers MUST remain primary when entries fail. Failures MUST appear in a collapsed, expandable counted summary; expanded content MUST be bounded and navigable.

#### Scenario: Mixed result
- GIVEN usable providers and provider errors in one response
- WHEN the popup opens
- THEN usable providers are listed and failures remain in the bounded summary

### Requirement: Refresh and concurrency

Users MUST be able to refresh manually and configure a positive interval. Invalid intervals MUST be rejected. Only one request MAY be active; overlapping triggers MUST coalesce into at most one follow-up, and stale responses MUST NOT replace newer results.

#### Scenario: Invalid interval
- GIVEN a nonnumeric or nonpositive refresh interval
- WHEN configuration is saved
- THEN validation blocks the value and explains the correction

#### Scenario: Overlapping triggers
- GIVEN a refresh is active
- WHEN timer and manual triggers occur
- THEN no concurrent request starts and at most one follow-up refresh runs

### Requirement: Native and accessible UI

All surfaces MUST use native Plasma 6/Kirigami behavior, system sizing, theming, keyboard navigation, and accessible names. Lists and errors MUST work in constrained geometry.

#### Scenario: Keyboard and narrow layout
- GIVEN keyboard-only use in a narrow panel
- WHEN the user opens and navigates the plasmoid
- THEN every action and disclosed item is reachable, labeled, visible, and theme-adaptive

### Requirement: MVP exclusions

The plasmoid MUST NOT provide cost data, charts, provider/source switching, auth or cookie automation, provider implementation, custom fallback probing, or reset/account actions.

#### Scenario: Provider failure guidance
- GIVEN a failure that may require external credential setup
- WHEN guidance is shown
- THEN it remains informational and does not perform authentication or cookie synchronization
