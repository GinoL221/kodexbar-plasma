# Delta for Provider Usage Display

## ADDED Requirements

### Requirement: Usage window row band layout

Each provider usage window row MUST render, top to bottom: a title, a full-width progress bar, then a trailing band. The band MUST always show `{percent}% used` when `usedPercent` is finite. For the reset side of the band, the row MUST show the CLI-supplied `resetDescription` verbatim, unmodified, with no added prefix or literal wording, when `resetDescription` is a non-empty string. When `resetDescription` is absent or empty but `resetsAt` is present, the band MUST fall back to the existing verbatim `Reset: {resetsAt}` text. When neither `resetDescription` nor `resetsAt` is present, the band MUST show only `{percent}% used`, with no reset placeholder text. The row MUST NOT compute, concatenate with invented wording, or fabricate any percent, reset, or pace value beyond the existing normalized `windows[]` contract — `resetDescription` already varies in wording per provider (e.g. some providers' CLI-supplied text already reads "Resets in 23h 59m" or starts with "Resets"), so the UI MUST NOT prepend its own "Resets in" or similar wording on top of it.

#### Scenario: Window with a CLI-supplied reset description
- GIVEN a window has a finite `usedPercent` and a non-empty `resetDescription`
- WHEN the row renders
- THEN the band shows percent used and the verbatim `resetDescription` text together, with no added prefix

#### Scenario: Window with resetsAt but no resetDescription
- GIVEN a window has a finite `usedPercent`, a valid `resetsAt`, and no `resetDescription`
- WHEN the row renders
- THEN the band shows percent used and the verbatim `Reset: {resetsAt}` text together

#### Scenario: Window with neither resetDescription nor resetsAt
- GIVEN a window has a finite `usedPercent` and neither a valid `resetsAt` nor a `resetDescription`
- WHEN the row renders
- THEN the band shows only percent used, with no reset text or placeholder

### Requirement: Provider header identity and plan badge

The selected-provider header MUST use two columns: the left column MUST show identity, `source`, and the `Updated` timestamp; the right column MUST show a plan/login badge built from `loginMethod` when it passes the existing `ProviderDetailsLogic.validLoginMethod` check. When `loginMethod` is absent or invalid, the badge MUST be omitted entirely, never shown as a placeholder such as "Unknown".

#### Scenario: Valid login method shows a badge
- GIVEN a selected provider's `loginMethod` passes `validLoginMethod`
- WHEN the header renders
- THEN the right column shows the plan/login badge and the left column shows identity, source, and Updated

#### Scenario: Absent or invalid login method omits the badge
- GIVEN a selected provider's `loginMethod` is absent or fails `validLoginMethod`
- WHEN the header renders
- THEN the right column shows no badge and no placeholder text, while the left column is unaffected

### Requirement: Informational popup footer

The popup MUST show a read-only footer with only the controller's current phase/status and the last-updated timestamp. The footer MUST NOT show a provider count, an error count, or any Settings, About, Quit, or Add Account control.

#### Scenario: Footer shows status and last-updated
- GIVEN the controller has a current phase/status and a last-updated timestamp
- WHEN the popup is open
- THEN the footer shows exactly those two pieces of information

#### Scenario: Footer excludes counts and controls
- GIVEN the popup is open in any provider/error state
- WHEN the footer renders
- THEN it shows no provider count, no error count, and no Settings, About, Quit, or Add Account control

## MODIFIED Requirements

### Requirement: Selected-provider enrichment

Selected-provider detail MUST map valid CLI-supplied `pace.primary`, `pace.secondary`, and `pace.tertiary` to Session, Weekly, and Monthly; show valid `credits.remaining`; and show reset-credit `availableCount` plus an expandable list of valid `credits[]` expirations only when the count is positive. Its header MUST show supplied account email and MAY show a human-readable organization, but MUST omit UUID/hex-like organizations. Tabs MUST contain an icon, short provider name, and a usage percent when a finite representative `usedPercent` exists for that provider; when no finite percentage exists, the tab MUST show icon and short name only, with no invented percent. `All` MUST remain compact and omit email, organization, pace, credits, resets, and cost.
(Previously: Tabs contained an icon and short provider name only, with no usage percent.)

#### Scenario: Valid enrichment is displayed
- GIVEN a selected provider supplies valid identity, pace, credit, and positive reset-credit data
- WHEN its detail is shown
- THEN values appear in the specified header, window, credit, and reset sections

#### Scenario: Invalid or zero data is hidden
- GIVEN enrichment is absent, malformed, non-finite, or reset `availableCount` is zero
- WHEN detail is shown
- THEN affected fields or sections are omitted without placeholders or failure

#### Scenario: Expirations are accessible
- GIVEN positive reset credits include valid expirations
- WHEN the keyboard-reachable disclosure is activated
- THEN it announces expanded state and exposes the expirations without a redeem action

#### Scenario: Privacy remains provider-scoped
- GIVEN email and an opaque organization are supplied
- WHEN tabs, `All`, and selected detail render
- THEN only the selected header shows email, organization is omitted, and tabs show icon, short name, and usage percent when available

#### Scenario: Tab shows a usage percent
- GIVEN a provider has a finite representative `usedPercent`
- WHEN its tab renders
- THEN the tab shows icon, short name, and that percent, sourced only from the existing normalized `windows[]` contract

#### Scenario: Tab omits percent when none is finite
- GIVEN a provider has no finite `usedPercent` in any window
- WHEN its tab renders
- THEN the tab shows icon and short name only, without an invented percent
