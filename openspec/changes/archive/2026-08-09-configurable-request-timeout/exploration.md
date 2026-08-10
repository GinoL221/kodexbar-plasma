## Exploration: configurable-request-timeout

### Current State
`UsageController.qml` has a hard-coded 15,000 ms watchdog for one authoritative `codexbar usage --provider all --format json --json-only` request. A timeout releases the active source, preserves the committed snapshot, and permits Refresh; the timeout text is also hard-coded to 15 seconds. `refreshInterval` is a separate persisted setting with a 60-second default and a 1–3600-second range. It controls the polling timer only and must remain 60 seconds by default.

The timeout callback has no provider identity. Therefore Claude's observed slowness supports longer user-selected limits but cannot support truthful per-provider limits or attribution while the single all-provider request remains unchanged.

### Affected Areas
- `contents/config/main.xml` — add persisted integer `requestTimeout` with default 60 seconds for new and existing installations.
- `contents/ui/config/configGeneral.qml` — add a native Kirigami settings control with the supported timeout presets and explanatory copy distinct from refresh cadence.
- `contents/ui/main.qml` — read and validate the persisted timeout, convert seconds to milliseconds, and pass it to `UsageController` without changing the refresh timer default or behavior.
- `contents/ui/UsageController.qml` — generate the timeout message from the active configured timeout while retaining command construction, request release, generations, coalescing, and snapshot behavior.
- `contents/code/RequestTimeout.js` — provide a small shared preset validator/default resolver, keeping corrupt or legacy missing configuration safe.
- `tests/UsageControllerFixture.qml`, `tests/UsageControllerFailureHarness.qml`, `tests/TimeoutFeedbackPopupHarness.qml` — add RED/GREEN coverage for defaults, dynamic copy, retry, retained snapshots, and narrow native popup readability.
- `tests/RequestTimeoutHarness.qml` and `scripts/run-qml-tests.sh` — exercise timeout preset validation through the strict-TDD runner.
- `README.md` and `docs/live-plasma-smoke.md` — explain request timeout versus refresh interval and add manual settings/theme/keyboard checks.
- `openspec/specs/provider-usage-display/spec.md` — later delta specification must replace the fixed-15-second requirement while retaining the no-attribution and no-isolation exclusions.

### Approaches
1. **Global curated timeout presets** — Persist one global timeout in seconds; support only 60 (default), 120, and 180, resolve missing/invalid values to 60, and derive dynamic generic timeout feedback.
   - Pros: Matches the supported provider needs; no false per-provider attribution; bounded predictable waits; simple Plasma-native UI; backward-compatible because no prior timeout key exists.
   - Cons: Does not suit every possible future latency or identify the slow provider.
   - Effort: Medium.

2. **Global free numeric timeout** — Persist any bounded whole-second value through a `SpinBox`.
   - Pros: Maximum flexibility without fetch redesign.
   - Cons: Requires arbitrary range/product-policy decisions, invites very long unresponsive waits, and adds validation/correction complexity without a stated need beyond 60/120/180.
   - Effort: Medium.

3. **Per-provider timeout or isolated fetches** — Apply different timeouts by provider or run separate requests.
   - Pros: Could accommodate Claude separately and prevent one provider from blocking results.
   - Cons: Impossible to attribute within the current one-command hang and violates the explicit all-provider command and deferred isolation/fetch redesign scope.
   - Effort: High and out of scope.

### Recommendation
Choose one global curated request-timeout setting: 60 seconds by default, with 120 and 180 second selectable presets. Treat these as the complete accepted set rather than accepting free numeric input. Persist it as an integer in the Plasma configuration; resolve a missing key (existing installations) or any unsupported value to 60 seconds at runtime. The configuration UI should label it `Request timeout:` and explain that it is the maximum wait for one all-provider CLI request, while `Refresh interval:` remains the independent polling cadence with its existing 60-second default and 1–3600 range.

The command-stage error must be dynamic and provider-neutral, for example: `CodexBar did not return all-provider usage within 120 seconds. Check enabled providers in CodexBar, temporarily disable a provider that hangs, then retry.` A timeout must still release the request, retain the prior snapshot, and let Refresh begin exactly one new generation. Empty stdout, preflight timeout, malformed JSON, and nonzero exit retain their current distinct behavior. The external command remains exactly `usage --provider all --format json --json-only`.

Strict TDD should first add failing runner coverage for 60/120/180 resolution, invalid/missing fallback to 60, milliseconds conversion, dynamic exact messages, and the unchanged fixed command. Existing fixture/harness coverage should prove timeout retry, stale completion rejection, one-active-request coalescing, and snapshot retention at a non-default preset. The popup harness and manual live checklist should verify preset labeling, keyboard reachability, wrapping at 180-second copy, and Breeze light/dark readability. The estimated implementation is 180–280 changed lines, below the 800-line review budget; one reversible work unit is appropriate.

Rollback is a revert of the new configuration key, resolver, settings UI, controller wiring, tests, and documentation. Since prior installations have no persisted timeout key and refresh configuration is untouched, no data migration is required.

### Risks
- A 180-second watchdog can make a genuine all-provider failure appear stalled longer; curated presets and explicit dynamic feedback make that tradeoff intentional.
- Plasma configuration may contain malformed or unsupported persisted integer values; runtime fallback to 60 seconds and UI correction must prevent zero, negative, or arbitrary values reaching the timer.
- Longer dynamic feedback must remain readable and keyboard-accessible in the constrained popup; offscreen harnesses help, but live Breeze/theme verification remains manual.
- Disconnecting the executable data source still bounds widget state rather than proving upstream child-process termination; this change must not claim otherwise.

### Ready for Proposal
Yes — propose a bounded global timeout configuration change with 60/120/180-second presets, a 60-second backward-compatible default, dynamic provider-neutral feedback, strict-TDD coverage, and unchanged 60-second refresh default. Explicitly exclude provider attribution, per-provider timeouts, fetch isolation, `--web-timeout`, provider auth/probing, and any CLI command change.
