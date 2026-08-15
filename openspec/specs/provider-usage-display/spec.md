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

On open, the popup MUST select the first response-ordered provider having a window. A native selector MUST expose `All` and usable providers with name, exact `source`, and either an authoritative icon or a themed fallback; every bundled provider icon MUST be visually distinct from every other bundled provider's icon and MUST adapt to the active Breeze theme, remaining a visible, non-blank mark in both Breeze Light and Breeze Dark rather than a fixed light-only or dark-only rendering. A bundled icon MUST NOT rely on a hardcoded absolute literal color (including pure white or pure near-black) that renders it indistinguishable from its background in either theme; bundled icons use `fill="currentColor"` (and `stroke="currentColor"` where the source strokes), matching the repository's existing theme-adaptive SVG convention, unless a documented literal-color fallback is used after a proven `Kirigami.Icon` theme-adaptation defect, in which case that fallback MUST remain legible against both Breeze Light and Breeze Dark panel backgrounds. `All` MUST show providers in response order with exactly one summary row per provider. Each summary row MUST preserve provider identity and MUST show exactly one representative usage bar when a finite `usedPercent` exists in that provider's effective window. A persisted global `preferredRepresentativeWindow` setting (Automatic default, or Session, Weekly, Monthly) governs the effective window uniformly for every provider in `All`; no per-provider override exists. Automatic, absent, or an unrecognized value MUST select the first finite value in Session, then Weekly, then Monthly order, unchanged from prior behavior. An explicit window with a finite value for that provider MUST be used. An explicit window with no finite value for that provider MUST fall back to that automatic order for that provider only. When no window has a finite value, the row MUST show identity only and MUST NOT invent a percentage or bar, regardless of the setting. A fallback bar MUST render with no visual distinction beyond its existing per-window label. This setting MUST NOT affect compact-panel selection (Requirement: Deterministic compact summary), which stays fixed. This persisted settings-panel preference differs from the transient popup provider/tab selection banned under Requirement: Provider-focused exclusions and MUST NOT be read as that banned persistent selection. `All` rows MUST NOT expand or expose additional window detail. Existing provider tabs MUST continue to show every supplied Session, Weekly, and Monthly window with exact raw resets; missing values MUST be omitted. Selection MUST be transient. Refresh or reorder MUST preserve `All` or the selected provider by identity; otherwise it MUST select the first usable provider, or `All`. Reopening MUST reapply the default. The stable four-key contract — `provider`, `source`, and `windows[]` (with each window's `key`, `label`, `usedPercent`, `resetsAt`, and `resetDescription`) — MUST remain shape-stable in value, type, and ordering across normalization; additive siblings on a provider entry, such as a verbatim `raw` passthrough, MAY be present without altering that stability.

(Previously: a bundled icon or themed fallback was accepted with no requirement that it be visually distinct per provider or adapt to the active Breeze theme, permitting hardcoded literal-color icons that could render as a blank block or an invisible mark in one theme; the four-key contract's stability under additive provider-entry fields was unaddressed, with no explicit guarantee constraining whether a new key could alter `provider`, `source`, or `windows[]` value, type, or ordering.)

#### Scenario: Heterogeneous providers

- GIVEN providers with nullable source, windows, reset fields, or unknown icons
- WHEN results are displayed
- THEN values are preserved, absent fields are omitted, and a themed fallback icon is used

#### Scenario: Session is representative

- GIVEN a provider has finite Session, Weekly, and Monthly percentages
- WHEN `All` is displayed
- THEN exactly one bar uses the Session percentage for that provider

#### Scenario: Representative fallback order

- GIVEN Session is missing or non-finite and Weekly and Monthly are finite
- WHEN `All` is displayed
- THEN exactly one bar uses the Weekly percentage for that provider

#### Scenario: Monthly is the only finite window

- GIVEN only Monthly has a finite percentage
- WHEN `All` is displayed
- THEN exactly one bar uses the Monthly percentage for that provider

#### Scenario: Provider has no finite percentage

- GIVEN Session, Weekly, and Monthly percentages are missing, nonnumeric, or non-finite, for any `preferredRepresentativeWindow` value
- WHEN `All` is displayed
- THEN the provider identity remains visible without a bar or invented percentage

#### Scenario: Full detail remains in provider tab

- GIVEN a provider supplies Session, Weekly, and Monthly windows
- WHEN its provider tab is selected
- THEN every supplied window and exact raw reset remains visible

#### Scenario: All summaries are not expandable

- GIVEN a provider summary is visible in `All`
- WHEN the user navigates or activates the row
- THEN no inline window details or expandable content are revealed

#### Scenario: Explicit preferred window with a finite value

- GIVEN `preferredRepresentativeWindow` is Weekly and a provider has a finite Weekly percentage
- WHEN `All` is displayed
- THEN exactly one bar uses that provider's Weekly percentage

#### Scenario: Per-provider fallback under an explicit preference

- GIVEN `preferredRepresentativeWindow` is Monthly; one provider lacks a finite Monthly value but has a finite Session value; another provider has a finite Monthly value
- WHEN `All` is displayed
- THEN the first provider falls back to Session while the second still uses Monthly

#### Scenario: Automatic preserves current default behavior

- GIVEN `preferredRepresentativeWindow` is Automatic, absent, or an unrecognized persisted value
- WHEN `All` is displayed
- THEN every provider's bar selection follows the exact Session-then-Weekly-then-Monthly order, unchanged

#### Scenario: Preference is global, not per-provider

- GIVEN `preferredRepresentativeWindow` is set to an explicit window
- WHEN `All` is displayed
- THEN the same preferred window governs selection for every provider uniformly, with no per-provider override

#### Scenario: Fallback bar has no special visual treatment

- GIVEN a provider's bar is rendered via automatic fallback rather than the explicit preference
- WHEN `All` is displayed
- THEN the bar uses identical styling to any other representative bar, distinguished only by its existing per-window label

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

Selected-provider detail MUST map valid CLI-supplied `pace.primary`, `pace.secondary`, and `pace.tertiary` to Session, Weekly, and Monthly; show valid `credits.remaining`; and show reset-credit `availableCount` plus an expandable list of valid `credits[]` expirations only when the count is positive. Its header MUST show supplied account email and MAY show a human-readable organization, but MUST omit UUID/hex-like organizations. Tabs MUST contain an icon and short provider name only; `All` MUST remain compact and omit email, organization, pace, credits, resets, and cost.

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
- THEN only the selected header shows email, organization is omitted, and tabs show icon plus short name

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
