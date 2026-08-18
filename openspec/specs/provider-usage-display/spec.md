# Provider Usage Display Specification

## Purpose

Show external `codexbar` CLI usage without reimplementing CLI responsibilities.

## Requirements

### Requirement: Bounded timeout troubleshooting documentation

The README MUST document bounds, presets, fallback, refresh independence, and retry guidance. The smoke guide MUST cover labeling, keyboard access, wrapping, and Breeze light/dark readability. Neither MUST prescribe exclusions.
(Previously: Fixed 15 seconds.)

#### Scenario: User investigates a timeout
- GIVEN timeout documentation
- WHEN documentation is followed
- THEN timeout differs from refresh and diagnosis stays provider-neutral

### Requirement: Validated request timeout

The plasmoid MUST persist integer `requestTimeout` seconds, accepting 30–600, presets 60/120/180, and custom values. Others MUST resolve to 60. It MUST drive the watchdog independently of refresh. Tests MUST precede production changes and pass `./scripts/run-qml-tests.sh`.

#### Scenario: Supported value drives a request
- GIVEN persisted timeout 120
- WHEN a request starts
- THEN its watchdog is 120 seconds

#### Scenario: Custom boundary values
- GIVEN timeout 30 or 600
- WHEN resolved
- THEN that integer becomes active

#### Scenario: Unsupported persistence falls back
- GIVEN timeout is missing, malformed, fractional, or out-of-range
- WHEN resolved
- THEN 60 becomes active

#### Scenario: Strict-TDD suite
- GIVEN implementation ready
- WHEN runner executes
- THEN schema, resolver, wiring, feedback, UI, lifecycle, command, docs, and exclusions pass


### Requirement: Authoritative all-provider request

Refresh MUST invoke the authoritative path with exactly `usage --provider all --format json --json-only`. The plasmoid MUST NOT probe unapproved fallbacks or perform account actions.
(Previously: Refresh required a configured path and prohibited all fallback probing.)

#### Scenario: Valid request
- GIVEN an executable authoritative absolute CLI path
- WHEN refresh starts
- THEN one all-provider request is issued with exact arguments

#### Scenario: Invalid path
- GIVEN a missing, relative, or non-executable saved CLI path
- WHEN configuration is saved or refresh is requested
- THEN it is rejected before usage execution and recovery begins


### Requirement: Provider presentation

Tab selection across popup opens is governed by Requirement: Tab selection persists across popup reopen; the selector still exposes usable providers as follows. A native selector MUST expose `Overview` (grid icon) and usable providers with display name, exact `source` (accessible metadata), and either an authoritative icon or a themed fallback; every bundled provider icon MUST be visually distinct from every other bundled provider's icon and MUST adapt to the active Breeze theme, remaining a visible, non-blank mark in both Breeze Light and Breeze Dark rather than a fixed light-only or dark-only rendering. A bundled icon MUST NOT rely on a hardcoded absolute literal color (including pure white or pure near-black) that renders it indistinguishable from its background in either theme; bundled icons use `fill="currentColor"` (and `stroke="currentColor"` where the source strokes), matching the repository's existing theme-adaptive SVG convention, unless a documented literal-color fallback is used after a proven theme-adaptation defect, in which case that fallback MUST remain legible against both Breeze Light and Breeze Dark panel backgrounds. Provider tabs MAY use a custom Plasma chip strip (not only QQC2.TabBar) when required for reliable icon theming and layout. Overflowing tabs MUST remain reachable without a permanent horizontal scrollbar (for example side affordances). `Overview` MUST show providers in response order with exactly one summary card per provider: provider icon and display name, plus one bar per finite Session, Weekly, and/or Monthly window in that order (zero to three bars). The internal layout of each such bar is governed by Requirement: Overview summary row title/percent layout. When no window has a finite value, the row MUST show identity only and MUST NOT invent a percentage or bar. `Overview`'s body window selection MUST NOT be governed by `preferredRepresentativeWindow`. The popup MUST NOT present a global expandable provider-failure disclosure for optional CLI provider errors when usable providers are shown (those errors may remain in controller state for tests or debug).

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

### Requirement: Protected native presentation

Enrichment MUST preserve exactly `usage --provider all --format json --json-only`, usage ownership, snapshots, timeout/failure distinctions, coalescing, and stale-response handling. Native Plasma/Kirigami UI MUST remain keyboard operable, popup-bounded, horizontally unclipped, and readable in Breeze Light and Dark.

#### Scenario: Usage regression and responsive checks
- GIVEN enriched fixtures at narrow and normal popup widths
- WHEN `./scripts/run-qml-tests.sh`, lint, package validation, and live theme/keyboard smoke run
- THEN the exact usage lifecycle passes and all content remains reachable and theme-readable

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

The UI MUST expose Loading, Error, and No data. Timeout MUST show exactly `CodexBar did not return all-provider usage within {seconds} seconds. Check enabled providers in CodexBar, temporarily disable a provider that hangs, then retry.`, using the active integer. Empty stdout MUST show exactly `CodexBar CLI returned no output.` Malformed, timeout, empty, and nonzero outcomes MUST remain distinct; valid unusable output MUST produce No data.
(Previously: Fixed 15-second behavior.)

#### Scenario: Request lifecycle
- GIVEN no newer result
- WHEN loading or failure happens
- THEN Loading or Error remains recoverable

#### Scenario: Watchdog timeout
- GIVEN an unfinished 120-second request
- WHEN 120 seconds elapse
- THEN request releases, exact 120-second Error appears, and snapshot remains

#### Scenario: Empty stdout
- GIVEN empty stdout before timeout
- WHEN handled
- THEN Error shows exactly `CodexBar CLI returned no output.` without timeout text

#### Scenario: Empty response
- GIVEN valid output has no usable data
- WHEN normalized
- THEN surfaces show No data

### Requirement: Mixed provider failures

Usable providers MUST remain primary and response-ordered. Errors MUST follow them in one global collapsed `ErrorSummary` with total count, response order, and bounded navigable expansion. Expanded failures MUST render only deterministic safe category messages; raw CLI diagnostics, local filesystem paths, API-key guidance, commands, and platform-specific internal details MUST NOT be exposed.

#### Scenario: Mixed result
- GIVEN usable providers and provider errors in one response
- WHEN the popup opens
- THEN usable providers are listed and failures remain in the bounded summary

### Requirement: Refresh and concurrency

Refresh MUST remain independent, default 60, and accept integers 1–3600. Invalid values MUST be rejected. Timeout retry MUST start one generation while retaining snapshots. One request MAY be active; triggers MUST coalesce, and stale responses MUST NOT replace results.
(Previously: Timeout independence was implicit.)

#### Scenario: Invalid interval
- GIVEN invalid refresh
- WHEN saved
- THEN validation blocks and explains correction

#### Scenario: Overlapping triggers
- GIVEN active refresh
- WHEN triggers overlap
- THEN no concurrent request starts and one follow-up MAY run

#### Scenario: Retry after timeout
- GIVEN timeout and snapshot
- WHEN Refresh is activated
- THEN one Loading generation starts, stale completion is ignored, and the snapshot remains

### Requirement: Native and accessible UI

Settings MUST retain its labeled native timeout control. The popup selector MUST expose keyboard-reachable entries, labels, and selected state. Narrow content MUST avoid horizontal clipping through bounded scrolling or elision and remain readable in Breeze light/dark.
(Previously: Configuration accessibility was unspecified.)

#### Scenario: Configure timeout accessibly
- GIVEN keyboard use in Breeze
- WHEN a preset or custom integer is entered
- THEN the labeled control persists it accessibly

### Requirement: MVP exclusions

The plasmoid MUST NOT add attribution, per-provider timeout/isolation, auth/probing, `--web-timeout`, CLI changes, or provider implementation. Refresh MUST issue exactly `usage --provider all --format json --json-only`.
(Previously: New exclusions were implicit.)

#### Scenario: Provider failure guidance
- GIVEN external setup is needed
- WHEN guidance appears
- THEN no auth, probing, or provider action occurs

#### Scenario: Unattributed timeout
- GIVEN timeout lacks identity
- WHEN feedback appears
- THEN no provider is inferred and exact command remains unchanged

### Requirement: Configuration-first path resolution

New installations MUST have no author default. Without a valid saved path, the plasmoid MUST try discovery, then show manual setup. A discovered path MUST become authoritative only after validation.

#### Scenario: First run discovers CodexBar
- GIVEN no saved path and an approved candidate is executable
- WHEN path resolution runs
- THEN the first valid candidate is configured
- AND all-provider refresh MAY proceed

#### Scenario: First run requires manual setup
- GIVEN no saved path and no approved candidate validates
- WHEN path resolution completes
- THEN no request runs and configuration guidance is shown

### Requirement: Deterministic bounded discovery

Discovery MUST evaluate only `$HOME/.local/bin/codexbar`, `/usr/local/bin/codexbar`, `/usr/bin/codexbar`, then `$HOMEBREW_PREFIX/bin/codexbar` when defined. Candidates MUST be absolute and executable through `test -x`; the first valid candidate MUST win. Discovery MUST NOT use inherited `PATH` or scan filesystems.

#### Scenario: Multiple candidates validate
- GIVEN two or more approved candidates are absolute and executable
- WHEN discovery runs
- THEN the earliest candidate is selected

#### Scenario: Optional Homebrew prefix is unavailable
- GIVEN `HOMEBREW_PREFIX` is undefined or non-absolute
- WHEN discovery runs
- THEN that candidate is skipped without broader probing

### Requirement: Saved-path migration and recovery

A valid saved path MUST remain authoritative. A missing, relative, or non-executable path MUST be revalidated, then fall back to approved discovery and guidance without erasing snapshots.

#### Scenario: Existing valid path survives upgrade
- GIVEN a saved path passes `test -x`
- WHEN the upgraded plasmoid refreshes
- THEN that path remains configured and discovery does not run

#### Scenario: Existing path becomes invalid
- GIVEN a saved path fails absolute or executable validation
- WHEN refresh is requested
- THEN approved discovery runs and failure shows configuration guidance
- AND any prior snapshot remains available

### Requirement: Setup and troubleshooting documentation

README and smoke guidance MUST cover installation, user-run `command -v codexbar`, saving an absolute path, external credentials, applicable OpenCode Go prerequisites, command verification, invalid-path and timeout troubleshooting, and live verification. It MUST distinguish terminal diagnosis from runtime discovery.

#### Scenario: User completes manual setup
- GIVEN discovery found no executable
- WHEN the documented setup and verification steps are followed
- THEN a validated absolute path can be saved without runtime `PATH` lookup

#### Scenario: External setup is incomplete
- GIVEN credentials or OpenCode Go prerequisites are missing
- WHEN troubleshooting guidance is followed
- THEN setup remains external and the plasmoid performs no automation

### Requirement: Conditional provider header metadata and dynamic details

The selected-provider header MUST show only CLI-supplied `version` and `loginMethod` as new metadata, omitting absent or invalid values without placeholders. Valid, non-excluded `usage.details[]` titles and label/value rows MUST appear verbatim in an accessible, theme-adaptive section that is collapsed by default and pointer- or keyboard-expandable. Invalid details MUST be ignored. Expanded content MUST remain popup-bounded and vertically scrollable without horizontal overflow.

#### Scenario: Header metadata is conditional

- GIVEN providers supply valid, absent, empty, or malformed version and login method values
- WHEN their provider views are displayed
- THEN valid values appear without additional raw metadata
- AND invalid values and their placeholders are omitted

#### Scenario: Details are collapsed and accessible

- GIVEN valid, non-excluded details in Breeze Light or Dark
- WHEN the provider view opens and the focused control is keyboard-activated
- THEN the control begins collapsed and reveals the supplied text verbatim
- AND its purpose and changed state are accessible and theme-readable

#### Scenario: Invalid details are safe

- GIVEN details are missing, non-array, or contain malformed entries or rows
- WHEN the provider view is displayed
- THEN invalid content is omitted without failure
- AND existing header and usage-window content remains available

#### Scenario: Expanded details remain bounded

- GIVEN expanded valid details exceed the popup's available height or width
- WHEN the user navigates the expanded content
- THEN vertical scrolling keeps all content reachable within the popup
- AND no horizontal overflow obscures content or controls

#### Scenario: Presentation enrichment preserves runtime boundaries

- GIVEN header metadata or dynamic details are displayed
- WHEN usage refreshes or the compact view is evaluated
- THEN normalized provider data, request lifecycle, and compact selection remain unchanged
- AND the exact all-provider CLI request remains unchanged

### Requirement: Provider-focused exclusions

The plasmoid MUST NOT compute or fabricate pace, credits, resets, identity, organization, cost, or tokens. It MAY display only the selected-provider fields authorized above, prior version/login/details, and cost governed by `provider-cost-estimate`; other raw fields MUST remain unrendered. It MUST NOT add auth, Add Account, Quit, redeem/mutation, pricing tables, QML price calculation, CLI/provider switching, persistent selection, provider implementation, or external data changes.
(Previously: pace, credits, cost, email, organization, and tokens were prohibited from display.)

#### Scenario: Missing commercial or reset data
- GIVEN output lacks valid commercial or reset data
- WHEN usage is displayed
- THEN none is fabricated or requested and unavailable sections are absent

#### Scenario: Verbatim passthrough of unmodeled fields
- GIVEN a provider carries unmodeled CLI-supplied fields
- WHEN normalized
- THEN they remain unmodified under `raw` and are neither computed nor fabricated

#### Scenario: Raw preservation authorizes bounded display
- GIVEN richer raw data is normalized
- WHEN any non-selected or selected-provider surface renders
- THEN only fields authorized for that surface appear and no raw diagnostics are exposed

#### Scenario: Fixture provenance and redaction
- GIVEN committed usage fixtures and capture documentation
- WHEN inspected
- THEN real CLI version/date and key/type fidelity are recorded while sensitive leaf values are substituted

### Requirement: Preserved runtime boundaries

Refresh MUST invoke exactly `usage --provider all --format json --json-only`. The plasmoid MUST preserve compact-panel selection, lifecycle, coalescing, stale-response handling, timeouts, failure distinctions, and snapshots. Provider executables, credentials, and paths MUST NOT be discovered.

#### Scenario: Portable path is resolved
- GIVEN a configured or discovered path passes validation
- WHEN refresh runs
- THEN lifecycle, timeout, provider, failure, and snapshot behavior are unchanged

## Acceptance Criteria

- No maintainer path remains as default or fallback.
- Tests cover order, absolute paths, and `test -x` outcomes.
- Valid paths survive; invalid paths fail closed.
- QML suites preserve protected runtime contracts.

## Non-Goals

Provider/auth implementation, setup automation, inherited `PATH`, filesystem scanning, arbitrary probing, and command or lifecycle changes are excluded.

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

### Requirement: Parallel package transition guidance

The installation and live-smoke documentation MUST identify `org.kde.plasma.kodexbar` as the legacy package and `org.kde.plasma.kodexbar.plasma` as the current package. It MUST explain that both package IDs MAY coexist, installation and updates of the current product MUST target `org.kde.plasma.kodexbar.plasma`, and users MUST add a new `KodexBar Plasma` widget rather than expect an existing legacy instance to change identity. Optional configuration-copy guidance MUST be manual and MUST preserve the destination instance's independent `General` settings: `codexbarCommand`, refresh interval, request timeout, and representative window. Guidance MUST NOT require package removal, panel mutation, or package/panel migration.

#### Scenario: Install the current product alongside legacy

- GIVEN the legacy package is installed
- WHEN a user follows current-product installation and add-widget guidance
- THEN `org.kde.plasma.kodexbar.plasma` is targeted and a new `KodexBar Plasma` instance is added
- AND the legacy package and its panel instances remain unchanged

#### Scenario: Update the current product

- GIVEN both package IDs coexist
- WHEN a user follows current-product update guidance
- THEN only `org.kde.plasma.kodexbar.plasma` is targeted
- AND no cross-ID conversion or removal is prescribed

#### Scenario: Optionally copy configuration

- GIVEN a user wants equivalent settings in a new current-product instance
- WHEN the optional copy guidance is followed
- THEN the four documented `General` settings are copied per instance
- AND no package identity or panel containment is rewritten

### Requirement: Constrained current-product usage rows

Within the current product's popup, provider and window usage rows MUST adapt to constrained available width. Every finite percentage selected for display MUST remain visible and non-clipped, the row's visible content MUST remain within its allocated bounds, and its progress bar MUST consume the width available after required labels and spacing without overflowing. These rules MUST NOT change the legacy UI.

#### Scenario: Finite percentage at constrained width

- GIVEN a current-product provider or window row has a finite percentage and constrained width
- WHEN the row is laid out
- THEN the percentage is visible in full and does not intersect or exceed the row bounds
- AND the progress bar occupies the remaining available width without clipping

#### Scenario: Wider allocation remains usable

- GIVEN the same current-product row receives additional width
- WHEN the row is laid out again
- THEN the percentage remains visible and non-clipped
- AND the progress bar expands to use the additional available width

### Requirement: Responsive contract preserves runtime boundaries

Responsive behavior MUST preserve package identity, all per-instance settings, provider data semantics, and exactly `usage --provider all --format json --json-only`. It MUST NOT change CLI contracts, providers, authentication, fetching, controller lifecycle, compact selection, or failure handling. Executable responsive tests MUST establish the constrained-width behavior before production changes and MUST pass through `./scripts/run-qml-tests.sh`.

#### Scenario: Responsive suite observes row geometry

- GIVEN constrained provider and window row fixtures with finite percentages
- WHEN `./scripts/run-qml-tests.sh` executes
- THEN tests observe visible non-clipped percentages, bounded row content, and progress bars using available width
- AND the exact all-provider command remains verified

#### Scenario: Unrelated behavior remains outside the change

- GIVEN the responsive and documentation acceptance checks pass
- WHEN the change is reviewed
- THEN package IDs, per-instance settings, panels, legacy UI, provider behavior, and lifecycle behavior are unchanged

### Requirement: Usage window threshold risk marker

Each rendered usage window bar (Overview summary and selected-provider detail alike) MUST classify its finite `usedPercent` into a fixed level — `ok` (<70), `warn` (70–89.99), `critical` (90–99.99), `exhausted` (>=100) — via pure classification logic, with no level for non-finite or absent `usedPercent`. The `warn`, `critical`, and `exhausted` levels MUST render one risk marker icon positioned adjacent to the window's percent value, sized independently of the bar's own height so it stays legible on thin Overview bars: in Overview summary mode the marker sits after the bar, immediately before the percent text; in selected-provider detail mode the marker sits immediately after the percent text. `warn` uses a bundled warning-triangle glyph (`contents/icons/threshold-warning.svg`) colored `Kirigami.Theme.neutralTextColor`; `critical` uses a bundled critical-circle glyph (`contents/icons/threshold-critical.svg`) colored `Kirigami.Theme.negativeTextColor`; `exhausted` uses a bundled octagon-with-diagonal-slash glyph (`contents/icons/threshold-exhausted.svg`), also colored `Kirigami.Theme.negativeTextColor` — `critical` and `exhausted` share the same color and are distinguished by icon shape only, not color. All three are recolorable mask icons, not a system icon-theme lookup. The `ok` level and the no-level case MUST render no marker. The bar fill color (`ProviderIcons.accent()`, `Kirigami.Theme.highlightColor` fallback) MUST remain identical at every level; the marker MUST NOT recolor, resize, or otherwise alter the fill, and MUST NOT be overlaid on top of the bar itself. The marker's layout slot MUST be reserved at a fixed width regardless of threshold level — bar track length MUST stay identical across all windows whether or not a given window shows a marker (`ok`/no-level windows render the marker invisible-but-space-reserved, not absent-and-collapsed), preserving the existing fixed-column, equal-track-length convention. Marker presence, position, icon, and color rules MUST apply identically whether the bar renders in Overview summary mode or selected-provider detail mode, using one shared implementation so all levels and both modes cannot diverge. `ProviderSelector.qml`'s tab underline usage bar MUST NOT gain this marker; it remains brand-accent only, unchanged. Each window's accessible description MUST append risk phrasing after its existing percent entry when the level is `warn`, `critical`, or `exhausted` — `warn` appends `"Elevated usage"`, `critical` appends `"Critical usage"`, `exhausted` appends `"Quota exhausted"` — leaving all other entries and their relative order unchanged; `ok` and no-level add no risk phrasing. Threshold boundaries (70/90/100) are fixed v1 policy, not user-configurable, and this marker is a UI-only display change with no CLI invocation, model, schema, or controller change.

#### Scenario: Below warn threshold shows no risk marker
- GIVEN a finite `usedPercent` below 70
- WHEN the bar renders in summary or detail mode
- THEN no risk marker icon appears

#### Scenario: Warn range shows a neutral risk marker
- GIVEN a finite `usedPercent` in [70, 90)
- WHEN the bar renders
- THEN the bundled warning-triangle marker (`threshold-warning.svg`) appears adjacent to the percent text, colored `Kirigami.Theme.neutralTextColor`

#### Scenario: Critical range shows a negative risk marker
- GIVEN a finite `usedPercent` in [90, 100)
- WHEN the bar renders
- THEN the bundled critical-circle marker (`threshold-critical.svg`) appears adjacent to the percent text, colored `Kirigami.Theme.negativeTextColor`

#### Scenario: Exhausted level shows a distinct negative risk marker
- GIVEN a finite `usedPercent` >= 100
- WHEN the bar renders
- THEN the bundled octagon-with-slash marker (`threshold-exhausted.svg`) appears adjacent to the percent text, colored `Kirigami.Theme.negativeTextColor` — same color as `critical`, distinguished only by icon shape

#### Scenario: Fill color is threshold-independent
- GIVEN any threshold level, including no level
- WHEN the bar renders
- THEN the fill remains `ProviderIcons.accent()` or the `Kirigami.Theme.highlightColor` fallback, never threshold-colored

#### Scenario: Bar track length is threshold-independent
- GIVEN two Overview summary windows with the same label and percent-text width but different threshold levels (e.g. one `ok`, one `exhausted`)
- WHEN both bars render
- THEN their track widths are equal — the reserved marker slot does not shrink the bar on rows that show a marker relative to rows that don't

#### Scenario: Non-finite or absent percent shows no bar and no risk marker
- GIVEN `usedPercent` is non-finite or absent
- WHEN the row renders
- THEN no bar is rendered and no risk marker appears, preserving existing behavior

#### Scenario: Accessible description gains risk phrasing at risk levels
- GIVEN a window's level is `warn`, `critical`, or `exhausted`
- WHEN its accessible description is computed
- THEN risk phrasing (`"Elevated usage"`, `"Critical usage"`, or `"Quota exhausted"` respectively) is appended after the existing percent entry, with existing entries and their order otherwise unchanged

#### Scenario: Tab underline bar is excluded from the marker
- GIVEN `ProviderSelector.qml`'s tab underline usage bar
- WHEN any provider tab renders at any threshold level, including `exhausted`
- THEN the underline shows brand accent color only, with no risk marker icon or recoloring

#### Scenario: Summary and detail modes stay identical
- GIVEN the same provider and window rendered in both Overview summary mode and selected-provider detail mode
- WHEN each bar renders
- THEN risk marker presence, icon, and color match exactly between the two modes, with no mode-specific divergence

### Requirement: Compact panel presentation

The compact/panel representation MUST show only the KodexBar logo icon, sized at least `Kirigami.Units.iconSizes.smallMedium`, with no visible percentage or status text beside it. The current percentage/status text MUST remain available through the control's accessible name for assistive technology.

#### Scenario: Icon-only panel button
- GIVEN the compact representation renders
- WHEN the panel button is shown
- THEN only the logo icon is visible, at or above `iconSizes.smallMedium`, with no adjacent text label

#### Scenario: Percentage remains accessible
- GIVEN a computed usage percentage exists
- WHEN the panel button's accessible name is queried
- THEN it still reports the percentage, even though no visible text shows it

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
