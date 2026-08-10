# Tasks: Configurable Request Timeout

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | 300–380 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | One reversible work unit / single PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Validated global timeout, native settings, and watchdog feedback | Single PR | `./scripts/run-qml-tests.sh` | Offscreen timeout/settings harnesses; manual `plasmawindowed` Breeze smoke | Timeout key, resolver, QML wiring/tests/docs only |

## Phase 1: Resolver and Configuration Contract

- [x] 1.1 **RED** — Create `tests/RequestTimeoutHarness.qml` and admit it in `scripts/run-qml-tests.sh`; prove 60/120/180, custom 30/600, missing/string/NaN/fractional/29/601 fallback 60, and ms conversion.
- [x] 1.2 **GREEN** — Add `requestTimeout` (Int, default 60, min 30, max 600) to `contents/config/main.xml` and implement `contents/code/RequestTimeout.js` parse/default/milliseconds APIs.
- [x] 1.3 **REFACTOR** — Keep `RequestTimeout.js` pure and parallel to `contents/code/RefreshInterval.js`; preserve refresh 1–3600/default-60 behavior.

## Phase 2: Native Settings UI

- [x] 2.1 **RED** — Create `tests/RequestTimeoutSettingsHarness.qml` for labeled, focusable preset/custom controls, persisted custom integers, correction guidance, wrapping, and refresh independence.
- [x] 2.2 **GREEN** — Update `contents/ui/config/configGeneral.qml` with one `cfg_requestTimeout`, QQC2 60/120/180/Custom selector, 30–600 SpinBox, accessible names, and native Kirigami/Breeze guidance.
- [x] 2.3 **REFACTOR** — Consolidate preset/custom synchronization without web controls or visual-gallery extraction; retain existing CLI-path and refresh controls.

## Phase 3: Watchdog Wiring and Lifecycle

- [x] 3.1 **RED** — Extend `tests/UsageControllerFixture.qml`, `UsageControllerFailureHarness.qml`, and `UsageControllerLifecycleHarness.qml` for 120-second exact feedback/release, retry/snapshot, stale, coalescing, empty, malformed, nonzero, and No data regressions.
- [x] 3.2 **GREEN** — Wire resolved milliseconds in `contents/ui/main.qml`; snapshot `timeoutMs` per preflight/command stage in `contents/ui/UsageController.qml` and interpolate the active command-stage seconds exactly.
- [x] 3.3 **REFACTOR** — Preserve the preflight timeout text, generation guards, one-active-source rule, and exact `usage --provider all --format json --json-only` command with no provider attribution/isolation.

## Phase 4: Readability, Documentation, and Evidence

- [x] 4.1 **RED** — Update `tests/TimeoutFeedbackPopupHarness.qml` for exact 180-second copy, 240×210 wrapping, focusable Refresh, and retained snapshot after retry.
- [x] 4.2 **GREEN** — Update `README.md` and `docs/live-plasma-smoke.md` with bounds/presets/fallback, refresh independence, retry, settings keyboard access, and manual Breeze light/dark checks.
- [x] 4.3 **REFACTOR/VERIFY** — Run the full runner and affected offscreen harnesses, `git diff --check`, scope/exclusion/command checks, and record single-unit rollback evidence; do not implement yet.
