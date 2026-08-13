# Tasks: Provider-Focused Popup UI

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 321–413 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 RED harnesses/runner → PR 2 GREEN Qml components → PR 3 docs/smoke |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: pending
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | RED harnesses + runner entry | PR 1 | `./scripts/run-qml-tests.sh` (ProviderSelectorHarness fails to load until component exists, ProviderRowHarness extended assertions fail) | `qml6 --software -f tests/ProviderSelectorHarness.qml` against fixture providers | Revert `tests/ProviderSelectorHarness.qml` creation, `ProviderRowHarness.qml` additions, runner line |
| 2 | GREEN selector/row/main composition | PR 2 | `./scripts/run-qml-tests.sh` (all harnesses green; lifecycle/argv snapshot unchanged) | `qml6 --software -f tests/ProviderSelectorHarness.qml`; `plasmawindowed` optional | Revert `contents/ui/ProviderSelector.qml`, `UsageWindowRow.qml`, `ProviderRow.qml`, `main.qml` |
| 3 | Smoke + docs | PR 3 | `git diff --check` plus manual smoke checklist | `plasmawindowed org.kde.kodexbar` (Breeze Light/Dark, Tab/arrow/Enter) | Revert `docs/live-plasma-smoke.md` section |

For `feature-branch-chain`: PR 1 base = feature/provider-focused-popup-ui tracker; PR 2 base = PR 1; PR 3 base = PR 2.

## Phase 1: RED Harnesses (strict TDD)

- [x] 1.1 Create `tests/ProviderSelectorHarness.qml`: assert first-usable default, explicit `All`, pending-load deferred default, reorder preserves identity, removal/no-window fallback to first usable then `All`, reopen reapplies default, null provider identity selectable, narrow-popup keyboard focus/selection order equals visual order.
- [x] 1.2 Extend `tests/ProviderRowHarness.qml` with assertions: finite/string/null/non-finite `usedPercent` renders progress only when finite; exact `resetsAt`/`resetDescription` unchanged; compact/detail modes; elided name/source with full source in accessibility text.
- [x] 1.3 Add `scripts/run-qml-tests.sh` harness entry `ProviderSelectorHarness` (qml6 offscreen block); keep exact lifecycle argv assertion `usage --provider all --format json --json-only` untouched.

## Phase 2: GREEN Shared Components

- [x] 2.1 Create `contents/ui/UsageWindowRow.qml`: inputs `windowData`, `compact`; render label always, percentage text + `QQC2.ProgressBar` (0..100) only when `typeof value === "number" && isFinite(value)`; `resetsAt`/`resetDescription` separate, non-empty after `String(...)`, no parsing/combining/durations; `Kirigami.Units`/`Kirigami.Theme`/`PlasmaComponents.Label`/`QQC2.ProgressBar` only; wrap detail text, no hardcoded colors.
- [x] 2.2 Create `contents/ui/ProviderSelector.qml`: `QQC2.TabBar` + `ScrollView` with `all` sentinel tab and one tab per usable provider (`windows.length > 0`), response order preserved; readonly `usableProviders`, `allSelected`, `selectedProvider`; on closed→open pick first usable else `All`; open-refresh preserves `All`/selected identity after reorder, fallback first usable then `All`; pending default until snapshot settles; tabs show `Kirigami.Icon` (existing lookup/fallback moved here), elided name + source, `Accessible.name`/description/selected; strong focus, Left/Right/Home/End/activation semantics.
- [x] 2.3 Modify `contents/ui/ProviderRow.qml`: compose `UsageWindowRow` (compact for `All`, detail for single), consume selector-owned `iconResolver`; name/source exact/fallback; remove duplicated finite/reset logic; progress bars omitted in `All`, labels + finite text + raw resets retained in order.
- [x] 2.4 Modify `contents/ui/main.qml`: instantiate `ProviderSelector` with `providers`, `phase`, `popupOpen`; render `All` compact `ProviderRow` per usable provider OR one detail `ProviderRow`; keep global `ErrorSummary` last and collapsed; no controller/model/lifecycle/error/snapshot/CLI changes.

## Phase 3: Regression Verification

- [x] 3.1 Run `./scripts/run-qml-tests.sh`; confirm ProviderSelectorHarness + extended ProviderRowHarness pass and existing lifecycle/coalescing/stale/timeout/snapshot/error/compact/settings/argv assertions remain green.
- [x] 3.2 Sanitize expanded `ErrorSummary` messages with RED coverage for raw diagnostics, local paths, API-key guidance, commands, and platform details; preserve count, order, bounded expansion, identity, and keyboard assertions.

## Phase 4: Docs & Smoke

- [x] 4.1 Append `docs/live-plasma-smoke.md` selector/detail checks: Tab/arrow/Enter/Space selection with announced state, long-name horizontal overflow, wrapped detail, global error placement after refresh, Breeze Light/Dark readability; note exact `usage --provider all --format json --json-only` stays unchanged.
- [x] 4.2 Manual `plasmawindowed` smoke reconciled from user-confirmed real interactive Plasma evidence: package update and live launch succeeded; provider selector navigation, first-provider/`All`/detail presentation, keyboard navigation, readable layout, and sanitized collapsed/expanded error summary were observed. Breeze theme switching, exact refresh reorder/disappear scenarios, and finite-only field variants were not independently evidenced.
