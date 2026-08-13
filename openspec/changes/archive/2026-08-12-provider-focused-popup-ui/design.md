# Design: Provider-Focused Popup UI

## Technical Approach

Keep `UsageController.qml`, `UsageModel.js`, compact representation, and settings unchanged. Add a presentation-only selector and reusable window renderer. `ProviderRow.qml` becomes a compact/detail composition; `main.qml` chooses `All` versus one provider and keeps the global error summary last. `ErrorSummary.qml` remains bounded and presentation-only, with deterministic safe classification for expanded failures.

## Architecture Decisions

| Option | Tradeoff | Decision and rationale |
|---|---|---|
| Horizontally scrollable `QQC2.TabBar` | More visible than a combo box; requires bounded overflow | Use it in `ProviderSelector.qml` because native tabs expose selection and arrow-key navigation without web-style cards or breakpoints. |
| Selector-owned transient state | Adds reconciliation logic outside `main.qml` | The selector receives providers, controller phase, and popup-open state, keeping fetch/model contracts untouched and making refresh behavior harness-testable. |
| Shared `UsageWindowRow.qml` | One additional component | Use compact and detail modes so finite/reset rules have one implementation and `ProviderRow.qml` does not duplicate them. |
| Existing icon lookup/fallback | Selector and row need one authority | Move the current lookup unchanged into `ProviderSelector`; pass its resolver to `ProviderRow`. Do not add discovery or another icon source. |

## Data Flow

    UsageController committed snapshot (unchanged)
             │
             ├── ProviderSelector ── selected provider identity / All
             │                              │
             └── main.qml ──────────────────┤
                         ├── ProviderRow compact × usable providers (All)
                         ├── ProviderRow detail × 1
                         └── global ErrorSummary

`ProviderSelector` filters usable providers (`windows.length > 0`) without mutating response order. Identity is the typed raw `provider` value; `All` uses a separate sentinel so a null provider remains selectable. On each closed→open transition it selects the first usable provider, or `All`; opening during initial loading keeps a pending default until the snapshot settles. During an open refresh it preserves explicit `All` or the selected identity after reorder. Missing/no-window selection falls back to first usable, then `All`.

## File Changes and Review Forecast

| File | Action | Authored changed-line target |
|---|---|---:|
| `contents/ui/ProviderSelector.qml` | Create native selector, reconciliation, accessibility | 75–90 |
| `contents/ui/UsageWindowRow.qml` | Create compact/detail window renderer | 55–70 |
| `contents/ui/ProviderRow.qml` | Modify to compose window rows and consume selector icon resolver | 55–70 |
| `contents/ui/main.qml` | Modify popup selection/view wiring only | 35–45 |
| `tests/ProviderSelectorHarness.qml` | Create selection/reorder/removal/reopen/narrow-keyboard RED coverage | 65–80 |
| `tests/ProviderRowHarness.qml` | Extend finite/missing/raw reset and compact/detail coverage | 20–30 |
| `scripts/run-qml-tests.sh` | Register the new harness | 1–3 |
| `docs/live-plasma-smoke.md` | Add selector/detail/theme/overflow checks | 15–25 |

Target: **321–413** changed lines; implementation MUST aim below 400 and, under `ask-on-risk`, stop for approval before apply if the concrete task forecast or diff exceeds 400. No generated files are excluded.

## Interfaces / Contracts

- `ProviderSelector`: inputs `providers`, `phase`, `popupOpen`; readonly `usableProviders`, `allSelected`, `selectedProvider`; selection remains in-memory only.
- `ProviderRow`: inputs `providerData`, `compact`, and selector-owned `iconResolver`; name and source remain exact/fallback-compatible.
- `UsageWindowRow`: inputs `windowData`, `compact`. A percentage is present only when `typeof value === "number" && isFinite(value)`. Only then render exact percentage text and native `QQC2.ProgressBar` (`0..100`; native visual saturation does not rewrite displayed data).
- A supplied window always retains its Session/Weekly/Monthly label. `resetsAt` and `resetDescription` render separately only when non-null/undefined and non-empty after string conversion; values are not parsed, combined, localized, or converted to durations. `All` removes progress bars but retains ordered window labels, finite percentage text, and supplied raw reset text.
- Use `Kirigami.Units`, `Kirigami.Theme`, `Kirigami.Icon`, `PlasmaComponents.Label`, `QQC2.TabBar/TabButton/ScrollView/ProgressBar`; no hardcoded colors, custom focus rings, decorative motion, or dashboard cards.
- Selector tabs show icon, elided name, and elided source while exposing full source through accessibility text. The selector scrolls horizontally; popup content scrolls vertically. Detail/reset text wraps, preventing horizontal clipping.
- Tabs use strong focus, native Left/Right/Home/End and activation semantics, `Accessible.name`, description, and selected state. Progress exposes its exact value; visual order equals focus order.

## Testing Strategy

| Layer | Coverage |
|---|---|
| Component RED harnesses | First usable, explicit `All`, pending load, reorder preservation, removal/no-window fallback, reopen reset, null identity, finite/string/null/non-finite percentages, exact resets, narrow focus/selection. |
| Regression | Run `./scripts/run-qml-tests.sh`; retain exact argv, compact highest-percent/ties, lifecycle/coalescing/stale/timeout/snapshot, errors, and settings assertions unchanged. |
| Live Plasma | `plasmawindowed`: Tab/arrow/Enter/Space selection, announced state, long-name horizontal overflow, wrapped detail, global error placement, refresh behavior, and Breeze Light/Dark readability. |

## Threat Matrix

N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary changes. Existing process integration is regression-only and unchanged.

## Migration / Rollout

No migration or feature flag required. Roll back only the listed presentation, harness, runner, and smoke-guide changes.

## Explicitly Out of Scope

No cost/credits/tokens, calculated reset durations, auth, provider/CLI switching, persistence, per-provider refresh, panel changes, new sources, executable/path discovery, controller/model/lifecycle/error/timeout/snapshot changes, or settings changes.

## Open Questions

None blocking. Duplicate identical raw provider identities would resolve to the first usable response entry because the CLI supplies no stable ID; this must not be “fixed” by inventing one.
