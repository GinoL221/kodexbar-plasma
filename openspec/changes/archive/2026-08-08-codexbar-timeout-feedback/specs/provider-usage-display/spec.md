# Delta for Provider Usage Display

## ADDED Requirements

### Requirement: Bounded timeout troubleshooting documentation

The README MUST document the 15-second all-provider watchdog, bounded diagnosis, and upstream provider disable-and-retry workaround. It MUST NOT prescribe attribution, auth, CLI, fallback-probing, or fetch changes.

#### Scenario: User investigates a timeout
- GIVEN a user investigates a timeout
- WHEN they follow its guidance
- THEN diagnosis uses bounded upstream enabled-provider controls
- AND they are directed to retry

## MODIFIED Requirements

### Requirement: Global states and CLI failures

The UI MUST expose Loading, Error, and No data. At the 15-second watchdog boundary, the popup MUST show exactly `CodexBar did not return all-provider usage within 15 seconds. Check enabled providers in CodexBar, temporarily disable a provider that hangs, then retry.` Empty stdout MUST instead show exactly `CodexBar CLI returned no output.` Malformed JSON, timeout, empty stdout, and nonzero exit MUST produce recoverable Error; parsed output without usable data MUST produce No data.
(Previously: Timeout lacked exact guidance and empty-stdout distinction.)

#### Scenario: Request lifecycle
- GIVEN no newer successful result
- WHEN a request loads, times out, exits nonzero, or returns malformed output
- THEN Loading or Error and manual refresh remain available

#### Scenario: Watchdog timeout
- GIVEN an all-provider request remains unfinished for 15 seconds
- WHEN the watchdog expires
- THEN the popup shows the exact provider-neutral timeout message
- AND Refresh remains available

#### Scenario: Empty stdout
- GIVEN the CLI completes with empty stdout before timeout
- WHEN the result is handled
- THEN Error shows exactly `CodexBar CLI returned no output.`
- AND the timeout message is not shown

#### Scenario: Empty response
- GIVEN a successful valid parsed response with no usable data
- WHEN it is normalized
- THEN compact and popup surfaces show No data

### Requirement: Refresh and concurrency

Users MUST be able to refresh manually and configure a positive interval; invalid intervals MUST be rejected. Refresh after timeout MUST start a new generation in Loading and retain the committed snapshot until valid replacement. Only one request MAY be active; triggers MUST coalesce into at most one follow-up, and stale responses MUST NOT replace newer results.
(Previously: Timeout retry omitted generation and snapshot semantics.)

#### Scenario: Invalid interval
- GIVEN a nonnumeric or nonpositive refresh interval
- WHEN configuration is saved
- THEN validation blocks it and explains correction

#### Scenario: Overlapping triggers
- GIVEN a refresh is active
- WHEN timer and manual triggers occur
- THEN no concurrent request starts; at most one follow-up runs

#### Scenario: Retry after timeout
- GIVEN a timeout with a committed snapshot visible
- WHEN the user activates Refresh
- THEN one new generation starts in Loading
- AND the snapshot remains until valid replacement

### Requirement: Native and accessible UI

All surfaces MUST use native Plasma 6/Kirigami behavior, system sizing, theming, keyboard navigation, and accessible names. Timeout guidance and Refresh MUST remain readable, reachable, labeled, and theme-adaptive in constrained geometry.
(Previously: Accessibility omitted actionable timeout guidance.)

#### Scenario: Keyboard and narrow layout
- GIVEN keyboard-only use with timeout guidance in a narrow panel
- WHEN the user navigates the plasmoid
- THEN guidance and Refresh are reachable, labeled, visible, and theme-adaptive

### Requirement: MVP exclusions

The plasmoid MUST NOT provide cost data, charts, provider/source switching, auth or cookie automation, provider implementation, custom fallback probing, reset/account actions, timeout provider attribution, per-provider isolation, fetch redesign, or CLI behavior changes.
(Previously: Exclusions omitted timeout attribution, isolation, fetch, and CLI boundaries.)

#### Scenario: Provider failure guidance
- GIVEN a failure that may require external credential setup
- WHEN guidance is shown
- THEN it remains informational and does not perform authentication or cookie synchronization

#### Scenario: Unattributed timeout
- GIVEN a timeout supplies no provider identity
- WHEN timeout feedback is shown
- THEN no provider is named or inferred
- AND no alternate probing or fetching begins
