# Delta for Provider Usage Display

## ADDED Requirements

### Requirement: Tab selection persists across popup reopen

The very first time the popup opens in a running widget session, the provider tab strip MUST default to `All` (Overview), regardless of whether usage data has already finished loading. Every subsequent popup open MUST restore whichever tab (`All` or a specific provider) was selected the last time the popup closed, rather than resetting to a default. If the previously-selected provider is no longer present when the popup reopens, the selector MUST fall back to its existing reconciliation behavior (first usable provider, or `All` if none). `All` MUST be a stable selection: it MUST NOT automatically switch to any provider tab on its own once usage data finishes loading — only an explicit user pick changes the selection.

#### Scenario: First open defaults to Overview
- GIVEN the popup has never been opened in this widget session
- WHEN it opens, even with usage data already loaded
- THEN the `All` tab is selected

#### Scenario: Reopen restores the last provider tab
- GIVEN the popup was previously open with a specific provider tab selected
- WHEN the popup closes and reopens
- THEN the same provider tab is selected again, not the default

#### Scenario: Reopen restores Overview
- GIVEN the popup was previously open with `All` selected
- WHEN the popup closes and reopens
- THEN `All` remains selected

#### Scenario: Vanished provider falls back sensibly
- GIVEN the previously-selected provider is no longer in the provider list when the popup reopens
- WHEN reconciliation runs
- THEN selection falls back to the first usable provider, or `All` if none exist — not an error state

#### Scenario: Overview never auto-switches away on its own
- GIVEN `All` is selected while usage data is still loading
- WHEN loading finishes with usable providers now available
- THEN `All` remains selected — no automatic switch to any provider tab

#### Scenario: Explicit picks survive loading churn
- GIVEN the user explicitly selects a specific provider tab, including while `phase === "loading"`
- WHEN the provider list or phase subsequently changes (refresh churn)
- THEN that explicit selection persists unless the provider itself disappears from the list
