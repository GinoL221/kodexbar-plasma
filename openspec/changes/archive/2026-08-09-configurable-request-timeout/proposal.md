# Proposal: Configurable Request Timeout

## Intent

Replace the hard-coded 15-second all-provider watchdog with one user-controlled request timeout. This addresses slow provider batches without claiming provider attribution or redesigning the authoritative CLI fetch.

## Scope

### In Scope
- Persist global `requestTimeout` seconds with curated presets 60/120/180 and bounded custom integers 30–600; default and invalid/missing fallback: 60.
- Keep `Refresh interval` independent at default 60 seconds and its existing 1–3600 range.
- Generate provider-neutral timeout feedback from the active value, preserve snapshots, release requests, and allow retry.
- Add strict-TDD QML/harness coverage, native UI checks, and documentation.

### Out of Scope / Non-goals
- Per-provider timeouts, isolation, attribution, authentication/probing, `--web-timeout`, CLI changes, or provider implementation.
- Changing the exact command: `usage --provider all --format json --json-only`.

## Capabilities

### New Capabilities
- None; this is a configuration and timeout extension to provider usage display.

### Modified Capabilities
- `provider-usage-display`: replace fixed 15-second timeout requirements with validated configurable bounds, dynamic provider-neutral feedback, and unchanged lifecycle/exclusion rules.

## Approach

Add the Plasma configuration key and a Kirigami `FormLayout` control. Resolve persisted values through `contents/code/RequestTimeout.js`, convert validated seconds to milliseconds in `main.qml`, and inject that value into `UsageController`. Keep generation, coalescing, stale-response rejection, snapshot retention, and all non-timeout error distinctions unchanged. Message example: `CodexBar did not return all-provider usage within 120 seconds. Check enabled providers in CodexBar, temporarily disable a provider that hangs, then retry.`

## Config Contract

`requestTimeout` is an integer in seconds; accepted runtime values are 30–600, with UI presets 60/120/180. Missing, malformed, or unsupported values resolve to 60. Existing installations need no migration. Refresh is untouched.

## Affected Areas

| Area | Impact |
|---|---|
| `contents/config/main.xml`, `contents/ui/config/configGeneral.qml` | New persisted setting and native control |
| `contents/ui/main.qml`, `contents/ui/UsageController.qml`, `contents/code/RequestTimeout.js` | Validation, wiring, watchdog, dynamic message |
| `tests/*`, `scripts/run-qml-tests.sh` | Strict-TDD behavior and visual/readability coverage |
| `README.md`, `docs/live-plasma-smoke.md` | User and manual verification guidance |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Longer waits hide real failures | Med | Curated presets, bounds, and explicit dynamic guidance |
| Corrupt config reaches timer | Med | Shared resolver and fallback tests |
| Long copy clips in popup | Med | Narrow, keyboard, light/dark Breeze checks |

## Rollback Plan

Revert the configuration key, resolver, UI/wiring, tests, and documentation. No data migration or refresh-setting rollback is required.

## Success Criteria

- [ ] Runner proves 30–600 validation, 60 fallback, millisecond conversion, dynamic exact messages, retry/snapshot behavior, and unchanged command.
- [ ] Native control is labeled, keyboard-reachable, wrapped, and readable in Breeze light/dark themes.
- [ ] Existing installations retain 60-second request and refresh defaults; no excluded capability is introduced.
