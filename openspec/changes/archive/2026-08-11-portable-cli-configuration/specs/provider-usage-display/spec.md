# Delta for Provider Usage Display

## ADDED Requirements

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

### Requirement: Preserved runtime boundaries

This change MUST preserve provider behavior, external auth ownership, refresh/coalescing/stale-response lifecycle, watchdog/timeouts, failure distinctions, and snapshots. Providers MUST remain downstream of one external `codexbar`. Provider executables, credentials, and paths MUST NOT be discovered.

#### Scenario: Portable path is resolved
- GIVEN a configured or discovered path passes validation
- WHEN refresh runs
- THEN lifecycle, timeout, provider, failure, and snapshot behavior are unchanged

## MODIFIED Requirements

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

## Acceptance Criteria

- No maintainer path remains as default or fallback.
- Tests cover order, absolute paths, and `test -x` outcomes.
- Valid paths survive; invalid paths fail closed.
- QML suites preserve protected runtime contracts.

## Non-Goals

Provider/auth implementation, setup automation, inherited `PATH`, filesystem scanning, arbitrary probing, and command or lifecycle changes are excluded.
