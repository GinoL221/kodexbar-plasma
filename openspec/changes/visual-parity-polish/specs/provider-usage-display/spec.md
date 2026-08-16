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

### Requirement: Provider presentation

On open, the popup MUST select the first response-ordered provider having a window. A native selector MUST expose `Overview` (grid icon) and usable providers with name, exact `source`, and either an authoritative icon or a themed fallback; every bundled provider icon MUST be visually distinct from every other bundled provider's icon and MUST adapt to the active Breeze theme, remaining a visible, non-blank mark in both Breeze Light and Breeze Dark rather than a fixed light-only or dark-only rendering. A bundled icon MUST NOT rely on a hardcoded absolute literal color (including pure white or pure near-black) that renders it indistinguishable from its background in either theme; bundled icons use `fill="currentColor"` (and `stroke="currentColor"` where the source strokes), matching the repository's existing theme-adaptive SVG convention, unless a documented literal-color fallback is used after a proven `Kirigami.Icon` theme-adaptation defect, in which case that fallback MUST remain legible against both Breeze Light and Breeze Dark panel backgrounds. `Overview` MUST show providers in response order with exactly one summary row per provider. Each summary row MUST preserve provider identity and MUST show a separate Session bar and a separate Weekly bar together when Session and Weekly each individually have a finite `usedPercent`. When only one of Session or Weekly is finite, the row MUST show only that bar, with no invented bar for the other. When neither Session nor Weekly is finite but Monthly is finite, the row MUST fall back to showing the Monthly bar alone, preserving visibility of the only available real data. When no window has a finite value, the row MUST show identity only and MUST NOT invent a percentage or bar. `Overview`'s body window selection MUST NOT be governed by `preferredRepresentativeWindow`; that persisted global setting (Automatic default, or Session, Weekly, Monthly) continues to govern only the compact-panel effective window (Requirement: Deterministic compact summary, unchanged) and the selected-provider tab's usage percent (Requirement: Selected-provider enrichment, unchanged by this requirement). This persisted settings-panel preference differs from the transient popup provider/tab selection banned under Requirement: Provider-focused exclusions and MUST NOT be read as that banned persistent selection. `Overview` rows MUST NOT expand or expose additional window detail. Existing provider tabs MUST continue to show every supplied Session, Weekly, and Monthly window with exact raw resets; missing values MUST be omitted. Selection MUST be transient. Refresh or reorder MUST preserve `Overview` or the selected provider by identity; otherwise it MUST select the first usable provider, or `Overview`. Reopening MUST reapply the default. The stable four-key contract — `provider`, `source`, and `windows[]` (with each window's `key`, `label`, `usedPercent`, `resetsAt`, and `resetDescription`) — MUST remain shape-stable in value, type, and ordering across normalization; additive siblings on a provider entry, such as a verbatim `raw` passthrough, MAY be present without altering that stability.

(Previously: the tab was named `All` and showed exactly one representative usage bar per provider, chosen by the global `preferredRepresentativeWindow` setting across a Session-then-Weekly-then-Monthly fallback order; it is renamed `Overview` with a grid icon, now shows Session and Weekly as independent bars together when each is finite, falls back to Monthly alone only when neither is finite, and its body is no longer governed by `preferredRepresentativeWindow`.)

#### Scenario: Heterogeneous providers

- GIVEN providers with nullable source, windows, reset fields, or unknown icons
- WHEN results are displayed
- THEN values are preserved, absent fields are omitted, and a themed fallback icon is used

#### Scenario: Overview shows Session and Weekly together

- GIVEN a provider has finite Session and finite Weekly percentages
- WHEN `Overview` is displayed
- THEN the row shows a separate Session bar and a separate Weekly bar for that provider

#### Scenario: Only Session is finite

- GIVEN Session is finite and Weekly is missing or non-finite
- WHEN `Overview` is displayed
- THEN the row shows only the Session bar, with no invented Weekly bar

#### Scenario: Only Weekly is finite

- GIVEN Weekly is finite and Session is missing or non-finite
- WHEN `Overview` is displayed
- THEN the row shows only the Weekly bar, with no invented Session bar

#### Scenario: Monthly fallback when Session and Weekly are absent

- GIVEN Session and Weekly are both missing or non-finite and Monthly is finite
- WHEN `Overview` is displayed
- THEN the row shows only the Monthly bar for that provider

#### Scenario: Provider has no finite percentage

- GIVEN Session, Weekly, and Monthly percentages are missing, nonnumeric, or non-finite
- WHEN `Overview` is displayed
- THEN the provider identity remains visible without a bar or invented percentage

#### Scenario: Full detail remains in provider tab

- GIVEN a provider supplies Session, Weekly, and Monthly windows
- WHEN its provider tab is selected
- THEN every supplied window and exact raw reset remains visible

#### Scenario: Overview summaries are not expandable

- GIVEN a provider summary is visible in `Overview`
- WHEN the user navigates or activates the row
- THEN no inline window details or expandable content are revealed

#### Scenario: preferredRepresentativeWindow does not govern Overview

- GIVEN `preferredRepresentativeWindow` is set to any value, including an explicit Session, Weekly, or Monthly preference
- WHEN `Overview` is displayed
- THEN each provider's bars render per the Session/Weekly/Monthly-fallback rules above, unaffected by that setting

#### Scenario: Every known provider renders a distinct, visible icon

- GIVEN every provider key in `contents/code/ProviderIcons.js` `knownProviders`
- WHEN its icon is rendered at `Kirigami.Units.iconSizes.smallMedium`
- THEN it renders a visible, non-blank mark that is visually distinguishable from every other provider's icon, in both Breeze Light and Breeze Dark

#### Scenario: No hardcoded literal color defeats theme adaptation

- GIVEN a bundled provider icon's SVG source
- WHEN the active Breeze theme changes between Light and Dark
- THEN the icon MUST NOT render a fixed white or fixed near-black mark that becomes indistinguishable from the panel background in either theme

#### Scenario: Codex and Azure OpenAI show their own brand mark

- GIVEN `codex.svg`, `azureopenai.svg`, and `openai.svg`
- WHEN their provider icons are rendered
- THEN each renders geometry visually distinct from the other two; none is byte-identical or visually identical to another provider's mark

#### Scenario: Documented literal-color fallback remains legible

- GIVEN the `currentColor` convention is proven inadequate for one icon by the manual smoke check
- WHEN a literal-color fallback is used for that icon instead
- THEN the fallback is documented as an exception and remains legible against both Breeze Light and Breeze Dark panel backgrounds

#### Scenario: Manual Breeze Light and Dark smoke check gates acceptance

- GIVEN no CI QML runtime exists to prove visual icon color or contrast
- WHEN the icon rendering fix is verified
- THEN a manual `plasmawindowed` smoke check, run once in Breeze Light and once in Breeze Dark per `docs/live-plasma-smoke.md`, confirms every provider in `knownProviders` renders a legible, distinct icon in both runs before the change is accepted

#### Scenario: Icon-only fix preserves unrelated runtime boundaries

- GIVEN the provider icon rendering fix is applied
- WHEN the change is reviewed
- THEN legacy and current package IDs, the exact `usage --provider all --format json --json-only` invocation (Requirement: Authoritative all-provider request), provider selection behavior, accessibility (Requirement: Native and accessible UI), the responsive layout (Requirement: Responsive contract preserves runtime boundaries), user configuration, and `contents/config/` remain unchanged

#### Scenario: Four-key contract values are unregressed by raw addition

- GIVEN any payload already covered by an existing `UsageModelTest` scenario
- WHEN it is normalized
- THEN `provider`, `source`, and every `windows[]` entry's `key`, `label`, `usedPercent`, `resetsAt`, and `resetDescription` equal their current values exactly, unaffected by the additive `raw` sibling

#### Scenario: Window-level unknown-key dropping remains unchanged

- GIVEN a `usage` object containing an unrecognized window key
- WHEN it is normalized
- THEN `windows` contains only recognized windows, exactly as before the `raw` addition

#### Scenario: Error entries remain unaffected by raw addition

- GIVEN an entry with a non-null `error`
- WHEN it is normalized
- THEN it is still routed to `errors` with `{provider, source, error}` and does not appear in `providers`, and gains no `raw` sibling
