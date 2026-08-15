# Tasks: Final Popup Parity

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated authored changed lines | 650–850 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | Four independently green work units |
| Delivery strategy | ask-on-risk |
| Chain strategy | feature-branch-chain |
| Size exception needed | No—unless chaining is declined |

Decision needed before apply: No — resolved
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Cost fixture/model contract | PR 1 | `./scripts/run-qml-tests.sh` | Offscreen cost-model fixture | `CostModel.js`, cost fixture, capture docs/tests |
| 2 | Isolated cost lifecycle | PR 2 | `./scripts/run-qml-tests.sh` | Offscreen DataSource lifecycle race harness | `CostController.qml`, usage generation, lifecycle tests |
| 3 | Safe selected-detail UI | PR 3a + PR 3b (split) | `./scripts/run-qml-tests.sh` | ProviderRow/Selector narrow-width harness | extractors, popup components, UI tests |
| 4 | Release evidence | PR 4 | `./scripts/lint-qml.sh` | `plasmawindowed` Breeze/keyboard smoke | docs, package/lint/smoke evidence |

### PR 2 Size Exception (accepted)

PR 2 landed at ~569 authored changed lines, above the ~400-line per-unit target. Maintainer accepted `size:exception` on 2026-08-15: the overage is real-subprocess race/coalescing/60s-termination coverage for `CostController.qml` (the exact runtime boundary this work unit exists to prove), not padding. No further split was requested. `./scripts/run-qml-tests.sh` exit 0, all pre-existing `UsageController*` regressions and the 17/17 `UsageControllerFixture` suite (including the new `committedGeneration` case) remain green.

### PR 3 Split (accepted, replaces single PR 3)

Work Unit 3 landed at ~894 authored changed lines as one batch, well above target and above PR2's exception. Maintainer chose to split rather than accept a size:exception on 2026-08-15:

- **PR 3a** (`feat/final-popup-parity-03a-provider-details-extractors`, targets PR 2 branch): tasks 3.1–3.2. `contents/code/ProviderDetails.js` fail-closed extractors (email, organization, pace-by-window, credits remaining, reset credits, updatedAt) plus `tests/ProviderDetailsHarness.qml` and `tests/ProviderDetailsIntegrationTest.qml`. ~324 authored lines.
- **PR 3b** (`feat/final-popup-parity-03b-native-detail-components`, targets PR 3a branch): tasks 3.3–3.4. Native `ProviderHeader.qml`, `ResetCreditsSection.qml`, `CostSection.qml`, `contents/code/CostRequestPolicy.js`; wiring in `main.qml`, `ProviderSelector.qml`, `ProviderRow.qml`, `UsageWindowRow.qml`; `tests/ProviderRowHarness.qml`, `tests/ProviderSelectorHarness.qml`, `tests/CostRequestPolicyHarness.qml`. Consumes PR 3a's extractors — cannot land independently of it.

Both slices verified together as one working tree before the split: `./scripts/run-qml-tests.sh` exit 0 (0 FAIL), `./scripts/lint-qml.sh` exit 0 (68 accepted i18n warnings, 0 unaccepted).

## Phase 1: Contract Foundation

- [x] 1.1 RED: Extend `tests/test_cli_contract_fixture.py` for `tests/fixtures/codexbar-cost-capture.json`: redaction, key/type fidelity, version/date, source, and exact cost argv evidence.
- [x] 1.2 GREEN: Add the redacted cost fixture, `docs/cli-contract-capture.md` evidence, and `contents/code/CostModel.js` finite/non-negative, matching-provider normalization; refactor copied snapshots.
- [x] 1.3 RED: Add cost-model QtTest coverage to `scripts/run-qml-tests.sh` for empty, partial, non-finite, wrong-provider, unsupported, and nonzero results hiding data.

## Phase 2: Independent Cost Lifecycle

- [x] 2.1 RED: Extend `tests/UsageControllerFixture.qml` plus a focused cost DataSource harness to preserve exact `usage --provider all --format json --json-only` argv and all existing usage lifecycle/coalescing/timeout/stale regressions.
- [x] 2.2 GREEN: Expose only successful `committedGeneration` in `contents/ui/UsageController.qml`; do not change its command or lifecycle branches.
- [x] 2.3 RED/GREEN: Create `contents/ui/CostController.qml` and tests for allowlisted shell-quoted `cost --provider {provider} --format json --json-only`, validated path, provider/generation/serial races, coalescing, replacement, and 60s termination.
- [x] 2.4 REFACTOR: Prove failed, timed-out, or stale cost never mutates usage and publishes no diagnostics.

## Phase 3: Selected-Provider Presentation

- [x] 3.1 RED: Extend `tests/ProviderDetailsIntegrationTest.qml` for valid/invalid pace, remaining credit, positive reset expiries, email-only header, opaque UUID/hex org rejection, raw preservation, and fixture PII fail-closed cases.
- [x] 3.2 GREEN: Extend `contents/code/ProviderDetails.js` with copied normalized extractors and identity fallback; keep all unmodeled fields under `raw` and unrendered.
- [x] 3.3 RED: Extend `tests/ProviderSelectorHarness.qml` and `tests/ProviderRowHarness.qml` for icon/short-name tabs, compact `All`, cost-free `All`, conditional cost failure, disclosure accessibility, and narrow-width reachability.
- [x] 3.4 GREEN/REFACTOR: Wire selected-provider cost in `contents/ui/main.qml`; update `ProviderSelector.qml`, `ProviderRow.qml`, `UsageWindowRow.qml`; add native `ProviderHeader.qml`, `ResetCreditsSection.qml`, and `CostSection.qml` with Breeze-safe wrapping and no redeem.

## Phase 4: Release Verification

- [x] 4.1 Update `README.md` and `docs/live-plasma-smoke.md` with optional local-cost, exclusions, reset disclosure, and privacy expectations.
- [x] 4.2 Run `./scripts/run-qml-tests.sh`, `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, and `git diff --check`; record results.
- [~] 4.3 Manually smoke `plasmawindowed` in Breeze Light/Dark: keyboard disclosure, selected identity, narrow popup scrolling, cost isolation, and unchanged `All`. Partially done — see "PR 4 partial live evidence" in `docs/live-plasma-smoke.md`. Live `plasmawindowed` load-tested against real `codexbar` CLI data: found and fixed a fatal QML id-scoping bug (`main.qml` alias into `fullRepresentation`'s implicit `Component` — invisible to any offscreen test), confirmed Ready state, tabs (icon + short name), and cost-free `All`. Remaining: provider-tab selection, keyboard disclosure toggle, narrow-width resize, and Breeze Light/Dark switch — no pointer/keyboard input-simulation tool available in this session (`xdotool`/`wtype` absent, `ydotoold` not running, no passwordless sudo to start it). Needs a human pass before merge.

**2026-08-15 addendum**: maintainer (Gino) ran the codex/grok/`All` portion of this checklist manually against real `codexbar` data and sent screenshots. Found a second bug: `CostSection.qml`'s "Last 30 days" line rendered `$10,4552 (1,39811e+08 tokens)` — scientific notation with a locale decimal comma — for large token counts, while `Credits remaining`, pace pass-through, and `All`'s cost-free/compact rendering were all correct. Root cause: raw `sessionCostUSD`/`sessionTokens`/`last30DaysCostUSD`/`last30DaysTokens` were interpolated directly into `i18n()`'s `%1`/`%2`, and KDE's locale-aware double formatting flips to scientific notation past ~6 significant digits. Fixed with deterministic `formatUsd`/`formatTokens` helpers in `CostSection.qml` (fixed 2-decimal cost, comma-grouped integer tokens, no `toLocaleString()`/engine-locale dependency) — display formatting only, no price calculation. RED-GREEN: added a `largeCostRow` case to `tests/ProviderRowHarness.qml` (139,811,000 / 987,654,321 tokens, 10.4552 / 245.6 USD) reproducing the exact magnitude; confirmed RED (exit 1) before the fix, GREEN (exit 0) after. Full suite and lint green.

**2026-08-15 addendum 2**: maintainer continued the checklist and hit a third, real bug: with all 6 real providers + `All` (7 tabs) at the popup's real width, the provider tab bar's horizontal scroll was unreliable — `grok` scrolled off-screen with no clear affordance, clicking a partially-visible `copilot` tab often didn't register, and the visible tab window drifted (`codex`/`claude` then `grok` disappearing) between two screenshots of the same selection with only a background data refresh in between, no user scroll action. Root cause: `ProviderSelector.qml` wrapped `QQC2.TabBar` in an outer `QQC2.ScrollView`, even though `TabBar`'s own `contentItem` is already a Flickable-backed `ListView` with `highlightRangeMode` that scrolls `currentIndex` into view on its own. The outer `ScrollView` auto-wrapped `TabBar` in a second, decoupled Flickable whose `contentWidth` tracked `TabBar`'s *unclamped* `implicitWidth` while the rendered `TabBar` stayed clamped to the available width — creating phantom scroll space, competing hit-testing with `TabButton` delegates, and a `contentX` that could drift on any `implicitWidth` recompute (e.g. every usage refresh) with no selection change. Fixed by removing the outer `ScrollView` entirely and letting `TabBar` manage its own scrolling (`clip: true` moved onto `TabBar` itself). Selection semantics (`_selectedIndex`/`_selectedIdentity`/`_reconcile()`) untouched. RED-GREEN: `tests/ProviderSelectorHarness.qml` gained geometry assertions (delegate position mapped into the selector's coordinate space) for the maintainer's exact 6-provider set at a narrow width — selecting `grok` (last tab) and `codex` (first tab, after scrolling right) must land fully inside the visible viewport, and a same-provider-set data refresh must not shift an already-visible selected tab. Confirmed RED (exit 1) against the unfixed tree via `git stash`, GREEN (exit 0) after. Full suite and lint green. Real click/keyboard reachability still needs a live human pass — this sandbox has no pointer/keyboard input simulation, only programmatic `currentIndex` assertions.

**2026-08-15 addendum 3**: removing the outer `ScrollView` (addendum 2) also removed its scrollbar, leaving zero visual affordance that hidden tabs exist. Maintainer: "desapareció la barra para moverme y ahora para que aparezcan, tengo que pararme en la última visible." Fixed by attaching `QQC2.ScrollBar { policy: AsNeeded }` directly to `TabBar`'s own internal Flickable (`tabBar.contentItem`, cast `as ListView` for qmllint's static Flickable-type check) via `Component.onCompleted`, not by re-wrapping `TabBar` in a second `ScrollView`/Flickable — same single source of truth for scroll position as addendum 2 established, just with a visible thumb/track drawn on top. Confirmed empirically that attaching `ScrollBar.horizontal` directly on `TabBar` itself (rather than its `contentItem`) is silently inert: Qt Quick Controls' `ScrollBar` attached property only binds to a `Flickable`, and `TabBar` is a `Container`, not a `Flickable` (verified via isolated repro scripts before writing the fix). Also discovered and worked around a real, reproducible Qt 6.11 QML engine ordering quirk: `pragma ComponentBehavior: Bound` (present in `ProviderSelector.qml`) defers a nested `Component.onCompleted` handler's execution to a later event-loop pass than an external caller's synchronous script — confirmed with a minimal two-file repro before touching test code — so the harness's assertion of the attached scrollbar is deferred one `Qt.callLater` tick (real users are unaffected: this settles well before the popup's first paint). RED-GREEN: `tests/ProviderSelectorHarness.qml` gained assertions on the maintainer's exact narrow 7-tab set that `tabBar.contentItem`'s horizontal `ScrollBar` exists, uses `AsNeeded` policy, and reports `size < 1.0` (overflowing); then, after widening the fixture past `tabBar.implicitWidth`, that `size` settles back to `~1.0` (`>= 0.999` tolerance for float rounding in the settled ratio, one more `Qt.callLater` tick for the `ColumnLayout`/`Flickable` geometry to resettle). Confirmed RED (exit 1) against the unfixed tree via `git stash`, GREEN (exit 0) after. The tab-reachability geometry assertions from addendum 2 pass unmodified. Full suite (`./scripts/run-qml-tests.sh`, exit 0) and lint (`./scripts/lint-qml.sh`, 68 accepted i18n warnings, 0 unaccepted) both green — the naive `tabBar.contentItem.QQC2.ScrollBar.horizontal` access without the `as ListView` cast triggered a new `Quick.attached-property-type` qmllint warning ("ScrollBar attached property must be attached to an object deriving from Flickable or ScrollView") that the lint baseline script fails closed on; the cast satisfies qmllint's static check without changing runtime behavior. Real interactive scrollbar dragging still needs a live human pass — no pointer simulation available in this sandbox.
