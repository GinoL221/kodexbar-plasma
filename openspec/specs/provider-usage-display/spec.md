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

On open, the popup MUST select the first response-ordered provider having a window. A native selector MUST expose `All` and usable providers with name, authoritative icon or themed fallback, and exact `source`. `All` MUST show providers in response order with exactly one summary row per provider. Each summary row MUST preserve provider identity and MUST show exactly one representative usage bar when a finite `usedPercent` exists in that provider's effective window. A persisted global `preferredRepresentativeWindow` setting (Automatic default, or Session, Weekly, Monthly) governs the effective window uniformly for every provider in `All`; no per-provider override exists. Automatic, absent, or an unrecognized value MUST select the first finite value in Session, then Weekly, then Monthly order, unchanged from prior behavior. An explicit window with a finite value for that provider MUST be used. An explicit window with no finite value for that provider MUST fall back to that automatic order for that provider only. When no window has a finite value, the row MUST show identity only and MUST NOT invent a percentage or bar, regardless of the setting. A fallback bar MUST render with no visual distinction beyond its existing per-window label. This setting MUST NOT affect compact-panel selection (Requirement: Deterministic compact summary), which stays fixed. This persisted settings-panel preference differs from the transient popup provider/tab selection banned under Requirement: Provider-focused exclusions and MUST NOT be read as that banned persistent selection. `All` rows MUST NOT expand or expose additional window detail. Existing provider tabs MUST continue to show every supplied Session, Weekly, and Monthly window with exact raw resets; missing values MUST be omitted. Selection MUST be transient. Refresh or reorder MUST preserve `All` or the selected provider by identity; otherwise it MUST select the first usable provider, or `All`. Reopening MUST reapply the default.

(Previously: unconditional Session → Weekly → Monthly order with no configurable preference.)

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

### Requirement: Provider-focused exclusions

The plasmoid MUST NOT add cost, credits, tokens, calculated reset durations, auth, CLI/provider switching, persistent selection, or external data changes.

#### Scenario: Missing commercial or reset data
- GIVEN output lacks commercial fields or calculated reset duration
- WHEN usage is displayed
- THEN none is fabricated or requested

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
