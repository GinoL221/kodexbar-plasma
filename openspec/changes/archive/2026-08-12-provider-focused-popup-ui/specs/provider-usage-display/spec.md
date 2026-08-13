# Delta for Provider Usage Display

## ADDED Requirements

### Requirement: Provider-focused exclusions

The plasmoid MUST NOT add cost, credits, tokens, calculated reset durations, auth, CLI/provider switching, persistent selection, or external data changes.

#### Scenario: Missing commercial or reset data
- GIVEN output lacks commercial fields or calculated reset duration
- WHEN usage is displayed
- THEN none is fabricated or requested

## MODIFIED Requirements

### Requirement: Provider presentation

On open, the popup MUST select the first response-ordered provider having a window. A native selector MUST expose `All` and usable providers with name, authoritative icon/fallback, and exact `source`. `All` MUST show presentation-only compact summaries in provider order; detail MUST show every supplied Session, Weekly, and Monthly window. Progress MUST require finite `usedPercent`; missing values MUST be omitted and raw resets MUST remain exact. Selection MUST be transient. Refresh/reorder MUST preserve `All` or the selected provider by identity; otherwise it MUST select the first usable provider, or `All`. Reopening MUST reapply the default.
(Previously: No selector or finite-progress rule.)

#### Scenario: Popup chooses first usable provider
- GIVEN ordered providers where the first has no windows and the second has Weekly usage
- WHEN the popup opens
- THEN the second provider is selected and its Weekly detail is shown

#### Scenario: All and detail preserve supplied data
- GIVEN providers with different windows and raw resets
- WHEN `All` and an individual provider are viewed
- THEN summaries retain provider order and detail shows every supplied window
- AND missing values are omitted while supplied resets remain exact

#### Scenario: Progress requires a finite percentage
- GIVEN finite, missing, nonnumeric, or non-finite `usedPercent`
- WHEN detail is rendered
- THEN progress appears only for finite values and no value is invented

#### Scenario: Refresh reorders providers
- GIVEN refresh reorders the selected usable provider
- WHEN refreshed data is presented
- THEN the same provider remains selected by identity

#### Scenario: Selected provider disappears
- GIVEN refresh removes the selected provider or its windows
- WHEN refreshed data is presented
- THEN the first usable provider is selected, or `All` if none exists

### Requirement: Mixed provider failures

Usable providers MUST remain primary and response-ordered. Errors MUST follow them in one global collapsed `ErrorSummary` with total count, response order, and bounded navigable expansion. Expanded failures MUST render only deterministic safe category messages; raw CLI diagnostics, local filesystem paths, API-key guidance, commands, and platform-specific internal details MUST NOT be exposed.
(Previously: Summary placement and ordering unspecified.)

#### Scenario: Mixed result
- GIVEN usable providers and provider errors
- WHEN the popup opens
- THEN providers precede one global collapsed counted summary
- AND expansion preserves error order in bounded navigable content

#### Scenario: Expanded failure details are sanitized
- GIVEN provider failures containing authentication guidance, API-key text, commands, local paths, or platform diagnostics
- WHEN the error summary is expanded
- THEN each failure shows a useful safe category/message
- AND none of the raw diagnostic details are rendered

### Requirement: Native and accessible UI

Settings MUST retain its labeled native timeout control. The popup selector MUST expose keyboard-reachable entries, labels, and selected state. Narrow content MUST avoid horizontal clipping through bounded scrolling or elision and remain readable in Breeze light/dark.
(Previously: Popup accessibility was unspecified.)

#### Scenario: Configure timeout accessibly
- GIVEN keyboard use in Breeze
- WHEN a preset or custom integer is entered
- THEN the labeled control persists it accessibly

#### Scenario: Keyboard selection is announced
- GIVEN focus on the popup selector
- WHEN keyboard navigation changes selection
- THEN the view changes and accessibility state identifies the entry

#### Scenario: Narrow themed popup
- GIVEN long names in a narrow Breeze light or dark popup
- WHEN content overflows
- THEN controls remain readable and keyboard-operable without horizontal clipping

### Requirement: Preserved runtime boundaries

Refresh MUST invoke exactly `usage --provider all --format json --json-only`. Compact-panel selection, lifecycle, coalescing, stale-response handling, timeouts, failure distinctions, and snapshots MUST remain unchanged. Provider executables, credentials, and paths MUST NOT be discovered.
(Previously: Command and compact preservation were implicit.)

#### Scenario: Provider-focused popup refreshes
- GIVEN an authoritative path and snapshot
- WHEN popup refresh runs during overlapping triggers or a timeout
- THEN command, compact selection, lifecycle, timeout, and snapshot semantics remain unchanged
