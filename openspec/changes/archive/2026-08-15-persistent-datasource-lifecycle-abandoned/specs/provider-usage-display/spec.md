# Delta for Provider Usage Display

## ADDED Requirements

### Requirement: Live Plasma lifecycle acceptance

Live Plasma acceptance MUST document lifecycle completion. Automated fixture-backed Plasma-host execution is optional when the environment supports it; documented manual `plasmawindowed` evidence from a real provider response is acceptable when that exact fixture path cannot be automated.

#### Scenario: Live successful lifecycle
- GIVEN `plasmawindowed` runs the plasmoid with either an executable fixture or a configured real CodexBar path
- WHEN preflight and the all-provider command complete
- THEN documented evidence shows Ready data without stuck Loading and identifies whether it was fixture-backed, verifier-run, or user-provided manual observation

## MODIFIED Requirements

### Requirement: Authoritative all-provider request

Refresh MUST preflight with exactly `test -x <shell-quoted absolute path>` and then invoke exactly `<shell-quoted absolute path> usage --provider all --format json --json-only`. Usable structured stdout MUST be parsed and committed after either a zero exit status or a nonzero status that represents optional provider failures; a nonzero status with empty stdout MUST remain an Error. The plasmoid MUST NOT probe fallbacks, combine boundaries, or perform account actions.
(Previously: Observable stage progression was unspecified.)

#### Scenario: Valid request
- GIVEN an executable absolute CLI path
- WHEN refresh starts and preflight succeeds
- THEN exactly one all-provider command is issued

#### Scenario: Invalid path
- GIVEN a missing, relative, or non-executable path
- WHEN configuration is saved or refresh is requested
- THEN no command is issued and an actionable error appears

#### Scenario: Successful command completion
- GIVEN preflight and all-provider output succeed
- WHEN the command reports exit code numeric `0` or string `"0"`
- THEN the complete result becomes Ready and the request is released

#### Scenario: Nonzero command completion
- GIVEN preflight succeeds and the command returns usable structured stdout with optional provider failures
- WHEN the command reports a numeric or numeric-string nonzero exit code
- THEN usable providers and provider errors commit atomically; when stdout is empty, no output commits and a nonzero-command Error appears

### Requirement: Global states and CLI failures

The UI MUST expose Loading, Error, and No data. Loading MUST persist through preflight and command execution until completion or configured timeout. Every failure MUST retain the last valid snapshot. Timeout MUST show exactly `CodexBar did not return all-provider usage within {seconds} seconds. Check enabled providers in CodexBar, temporarily disable a provider that hangs, then retry.` Empty stdout MUST show exactly `CodexBar CLI returned no output.` Malformed, timeout, path, empty, and nonzero outcomes MUST remain distinct; valid unusable output MUST produce No data.
(Previously: Loading continuity and universal snapshot retention were unspecified.)

#### Scenario: Request lifecycle
- GIVEN the current request has no terminal outcome
- WHEN preflight or command execution remains active
- THEN Loading remains and no partial output commits

#### Scenario: Watchdog timeout
- GIVEN an unfinished request with timeout 120
- WHEN 120 seconds elapse
- THEN the request releases, exact 120-second Error appears, and snapshot remains

#### Scenario: Empty stdout
- GIVEN empty stdout before timeout
- WHEN handled
- THEN Error shows exactly `CodexBar CLI returned no output.` without timeout text

#### Scenario: Empty response
- GIVEN valid output has no usable data
- WHEN normalized
- THEN surfaces show No data

#### Scenario: Failure retains snapshot
- GIVEN a previously committed valid snapshot
- WHEN path, command, malformed-output, empty-output, or timeout failure occurs
- THEN the snapshot remains while the matching Error appears

### Requirement: Refresh and concurrency

Refresh MUST remain independent, default 60, and accept integers 1–3600; other values MUST be rejected. One request MAY be active. Triggers MUST coalesce into at most one refresh starting after release. Released, wrong-stage, wrong-source, or superseded-generation callbacks MUST NOT alter state or snapshots.
(Previously: Queue ordering and stale callback classes were unspecified.)

#### Scenario: Invalid interval
- GIVEN invalid refresh
- WHEN saved
- THEN validation blocks and explains correction

#### Scenario: Overlapping triggers
- GIVEN multiple refresh triggers occur during one request
- WHEN that request reaches any terminal release
- THEN no concurrent request starts and one queued refresh follows release

#### Scenario: Retry after timeout
- GIVEN timeout and snapshot
- WHEN Refresh is activated
- THEN one Loading generation starts and the snapshot remains

#### Scenario: Stale callback invalidation
- GIVEN a callback has a released stage, wrong source, or older generation
- WHEN it arrives after release or a queued refresh starts
- THEN it cannot change state, snapshot, or request count
