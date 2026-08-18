# Delta for Provider Usage Display

## ADDED Requirements

### Requirement: Usage window row band layout

Each selected-provider detail window row — that is, a window row rendered in the selected-provider tab view, not an Overview summary row — MUST render, top to bottom: a title, a full-width progress bar, then a trailing band. The band MUST always show `{percent}% used` when `usedPercent` is finite. For the reset side of the band, the row MUST show the CLI-supplied `resetDescription` verbatim, unmodified, with no added prefix or literal wording, when `resetDescription` is a non-empty string. When `resetDescription` is absent or empty but `resetsAt` is present, the band MUST fall back to the existing verbatim `Reset: {resetsAt}` text. When neither `resetDescription` nor `resetsAt` is present, the band MUST show only `{percent}% used`, with no reset placeholder text. The row MUST NOT compute, concatenate with invented wording, or fabricate any percent, reset, or pace value beyond the existing normalized `windows[]` contract — `resetDescription` already varies in wording per provider (e.g. some providers' CLI-supplied text already reads "Resets in 23h 59m" or starts with "Resets"), so the UI MUST NOT prepend its own "Resets in" or similar wording on top of it. Overview's summary rows use a different internal layout entirely; see Requirement: Overview summary row title/percent layout.

#### Scenario: Window with a CLI-supplied reset description
- GIVEN a selected-provider detail row's window has a finite `usedPercent` and a non-empty `resetDescription`
- WHEN the row renders
- THEN the band shows percent used and the verbatim `resetDescription` text together, with no added prefix

#### Scenario: Window with resetsAt but no resetDescription
- GIVEN a selected-provider detail row's window has a finite `usedPercent`, a valid `resetsAt`, and no `resetDescription`
- WHEN the row renders
- THEN the band shows percent used and the verbatim `Reset: {resetsAt}` text together

#### Scenario: Window with neither resetDescription nor resetsAt
- GIVEN a selected-provider detail row's window has a finite `usedPercent` and neither a valid `resetsAt` nor a `resetDescription`
- WHEN the row renders
- THEN the band shows only percent used, with no reset text or placeholder

### Requirement: Overview summary row title/percent layout

Each bar shown within an Overview summary row MUST render as a **single horizontal line**: window title on the left, a progress bar in the middle, and `{percent}% used` on the right when `usedPercent` is finite. A summary row's bar MUST NOT render a trailing band, MUST NOT show `resetDescription` or `resetsAt` text in any form, and MUST NOT show a reset placeholder — regardless of whether the underlying window supplies a `resetDescription` or `resetsAt` value. This layout applies only within Overview; it does not alter Requirement: Usage window row band layout, which continues to govern selected-provider detail rows unchanged.

(Previously: title and percent on one line above a full-width bar — superseded by live Overview reference density.)

#### Scenario: Summary bar with a finite percent
- GIVEN an Overview summary row's window has a finite `usedPercent`
- WHEN that window's bar renders
- THEN one line shows the window title, a progress bar, and `{percent}% used` together

#### Scenario: Summary row with no finite percentage shows identity only
- GIVEN a provider's Session, Weekly, and Monthly percentages are all missing, nonnumeric, or non-finite (per Requirement: Provider presentation's "Provider has no finite percentage" scenario)
- WHEN the Overview row renders
- THEN only provider identity is shown, with no title/percent line, no bar, and no invented percent

#### Scenario: Summary rows never show reset text
- GIVEN an Overview summary row's window supplies a non-empty `resetDescription`, a valid `resetsAt`, both, or neither
- WHEN that window's bar renders
- THEN no reset text, reset placeholder, or trailing band appears, in every case

### Requirement: Provider header identity and plan badge

The selected-provider header MUST use two columns: the left column MUST show the provider display name and the `Updated` timestamp when available; the right column MUST show a plan/login badge built from `loginMethod` when it passes the existing `ProviderDetailsLogic.validLoginMethod` check. When `loginMethod` is absent or invalid, the badge MUST be omitted entirely, never shown as a placeholder such as "Unknown". The primary header chrome MUST NOT show CLI version, account email, or organization (those fields remain validated for optional secondary surfaces / accessibility contracts but MUST stay off the default detail header).

#### Scenario: Valid login method shows a badge
- GIVEN a selected provider's `loginMethod` passes `validLoginMethod`
- WHEN the header renders
- THEN the right column shows the plan/login badge and the left column shows display name and Updated when present

#### Scenario: Absent or invalid login method omits the badge
- GIVEN a selected provider's `loginMethod` is absent or fails `validLoginMethod`
- WHEN the header renders
- THEN the right column shows no badge and no placeholder text, while the left column is unaffected

#### Scenario: Version email and organization stay off primary chrome
- GIVEN a selected provider supplies valid version, email, and organization
- WHEN the detail header renders
- THEN version, email, and organization are not shown in the primary header columns

### Requirement: Informational popup footer

The popup MUST show a read-only footer with only the controller's current phase/status (including a loading phrase such as `Loading usage…` while loading). The footer MUST NOT show a provider count, an error count, a last-updated timestamp, or any Settings, About, Quit, or Add Account control. Loading status MUST NOT be duplicated as a scroll-body label that grows the popup layout; body phase copy is limited to terminal no-data/error messaging.

#### Scenario: Footer shows status
- GIVEN the controller has a current phase/status
- WHEN the popup is open
- THEN the footer shows exactly that one piece of information

#### Scenario: Footer excludes counts, timestamp, and controls
- GIVEN the popup is open in any provider/error state
- WHEN the footer renders
- THEN it shows no provider count, no error count, no last-updated timestamp, and no Settings, About, Quit, or Add Account control

#### Scenario: Loading does not enlarge the scroll body
- GIVEN the controller phase is loading
- WHEN the popup is open
- THEN loading copy appears in the footer and not as an extra growing label above the provider list

## MODIFIED Requirements

### Requirement: Selected-provider enrichment

Selected-provider detail MUST map valid CLI-supplied `pace.primary`, `pace.secondary`, and `pace.tertiary` to Session, Weekly, and Monthly; show `credits.remaining` only when it is a finite number greater than zero; and show reset-credit `availableCount` plus an expandable list of valid `credits[]` expirations only when the count is positive. Its primary header MUST show display name and Updated plus plan/login badge when valid, and MUST NOT show email, organization, or version in that chrome. Tabs MUST show an icon and short display name; when a finite representative `usedPercent` exists, the tab MUST expose that percent via an underline usage bar and accessible name, not as numeric text in the visible tab label. When no finite percentage exists, the tab MUST show icon and name only, with no invented percent. `Overview` MUST remain compact and omit email, organization, pace, credits, resets, and cost.
(Previously: tabs put percent in the visible label; header showed email/org; credits of 0 could render.)

#### Scenario: Valid enrichment is displayed
- GIVEN a selected provider supplies valid pace, positive credits, and positive reset-credit data
- WHEN its detail is shown
- THEN values appear in the window, credit, and reset sections without requiring email in the header

#### Scenario: Invalid or zero data is hidden
- GIVEN enrichment is absent, malformed, non-finite, credits remaining is zero, or reset `availableCount` is zero
- WHEN detail is shown
- THEN affected fields or sections are omitted without placeholders or failure

#### Scenario: Expirations are accessible
- GIVEN positive reset credits include valid expirations
- WHEN the keyboard-reachable disclosure is activated
- THEN it announces expanded state and exposes the expirations without a redeem action

#### Scenario: Privacy remains provider-scoped
- GIVEN email and an opaque organization are supplied
- WHEN tabs, Overview, and selected detail render
- THEN email and organization are not shown in primary chrome, and tabs show icon, display name, and underline percent when available

#### Scenario: Tab shows a usage percent without numeric label text
- GIVEN a provider has a finite representative `usedPercent`
- WHEN its tab renders
- THEN the tab shows icon and display name, exposes that percent on an underline bar and in the accessible name, and does not append a numeric percent to the visible tab text

#### Scenario: Tab omits percent when none is finite
- GIVEN a provider has no finite `usedPercent` in any window
- WHEN its tab renders
- THEN the tab shows icon and display name only, without an invented percent

### Requirement: Provider presentation

On open, the popup MUST select the first response-ordered provider having a window. A native selector MUST expose `Overview` (grid icon) and usable providers with display name, exact `source` (accessible metadata), and either an authoritative icon or a themed fallback; every bundled provider icon MUST be visually distinct from every other bundled provider's icon and MUST adapt to the active Breeze theme, remaining a visible, non-blank mark in both Breeze Light and Breeze Dark rather than a fixed light-only or dark-only rendering. A bundled icon MUST NOT rely on a hardcoded absolute literal color (including pure white or pure near-black) that renders it indistinguishable from its background in either theme; bundled icons use `fill="currentColor"` (and `stroke="currentColor"` where the source strokes), matching the repository's existing theme-adaptive SVG convention, unless a documented literal-color fallback is used after a proven theme-adaptation defect, in which case that fallback MUST remain legible against both Breeze Light and Breeze Dark panel backgrounds. Provider tabs MAY use a custom Plasma chip strip (not only QQC2.TabBar) when required for reliable icon theming and layout. Overflowing tabs MUST remain reachable without a permanent horizontal scrollbar (for example side affordances). `Overview` MUST show providers in response order with exactly one summary card per provider: provider icon and display name, plus one bar per finite Session, Weekly, and/or Monthly window in that order (zero to three bars). The internal layout of each such bar is governed by Requirement: Overview summary row title/percent layout. When no window has a finite value, the row MUST show identity only and MUST NOT invent a percentage or bar. `Overview`'s body window selection MUST NOT be governed by `preferredRepresentativeWindow`. The popup MUST NOT present a global expandable provider-failure disclosure for optional CLI provider errors when usable providers are shown (those errors may remain in controller state for tests or debug).

(Previously: Session+Weekly exclusive of Monthly; percent in tab text; native TabBar assumed; ErrorSummary in popup.)

#### Scenario: Heterogeneous providers

- GIVEN providers with nullable source, windows, reset fields, or unknown icons
- WHEN results are displayed
- THEN values are preserved, absent fields are omitted, and a themed fallback icon is used

#### Scenario: Overview shows Session Weekly and Monthly together when all finite

- GIVEN a provider has finite Session, Weekly, and Monthly percentages
- WHEN `Overview` is displayed
- THEN the card shows three bars in Session, Weekly, Monthly order

#### Scenario: Overview shows Session and Weekly together

- GIVEN a provider has finite Session and finite Weekly percentages and Monthly is missing or non-finite
- WHEN `Overview` is displayed
- THEN the row shows a separate Session bar and a separate Weekly bar for that provider

#### Scenario: Only Session is finite

- GIVEN Session is finite and Weekly and Monthly are missing or non-finite
- WHEN `Overview` is displayed
- THEN the row shows only the Session bar, with no invented Weekly or Monthly bar

#### Scenario: Only Weekly is finite

- GIVEN Weekly is finite and Session and Monthly are missing or non-finite
- WHEN `Overview` is displayed
- THEN the row shows only the Weekly bar, with no invented Session or Monthly bar

#### Scenario: Monthly alone when Session and Weekly are absent

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
- THEN each provider's bars render per the finite Session/Weekly/Monthly rules above, unaffected by that setting

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
