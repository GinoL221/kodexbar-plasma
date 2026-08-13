## Exploration: compact-all-provider-bars

### Current State

The Plasma popup has a provider-focused layout with a `QQC2.TabBar` selector (`ProviderSelector.qml`) exposing `All` plus one tab per usable provider. Two content modes exist in `main.qml`:

1. **All view** (`allSelected`): a `Repeater` of `ProviderRow` with `compact: true`. Each provider renders its icon, name, source, and ALL windows (Session/Weekly/Monthly) via `UsageWindowRow`. In compact mode, `UsageWindowRow` hides the `QQC2.ProgressBar` but retains the percentage text label and raw reset text. This means the All view is a vertically-stacked list of every provider × every window — text only, no visual bars.

2. **Selected-provider view**: a single `ProviderRow` with `compact: false` showing ALL windows with full progress bars, reset text wrapping, and detail layout.

**Key data flow**: `UsageController` → `committedProviders` → `ProviderSelector` (selection state) → `main.qml` (conditional rendering). The `UsageModel.selectCompact()` function already computes the global highest finite `usedPercent` with Session → Weekly → Monthly → CLI-order tie-breaking for the panel button. Per-provider window definitions are `{primary: "Session", secondary: "Weekly", tertiary: "Monthly"}`.

**Compact panel** (`CompactUsageButton.qml`): shows a single percentage from `selectCompact`. Unchanged.

**External CLI boundary**: `usage --provider all --format json --json-only` is immutable. No data-contract changes.

### Affected Areas

- `contents/ui/main.qml` — All-view `Repeater` must switch from "all windows compact" to "representative bar per provider"
- `contents/ui/ProviderRow.qml` — May need a representative-window mode or the All view must stop using it for per-provider rows
- `contents/ui/UsageWindowRow.qml` — Already handles finite-percent gating and progress bar rendering; reusable for the representative bar
- `contents/code/UsageModel.js` — Needs a `selectRepresentative(windows)` function: first finite `usedPercent` in Session → Weekly → Monthly order
- `tests/ProviderRowHarness.qml` — Must cover the new compact-representative layout
- `tests/MainCompactHarness.qml` — May need minor extension for All-view representative selection
- `scripts/run-qml-tests.sh` — Register any new harness
- `docs/live-plasma-smoke.md` — Add checks for the new All-view bar layout
- `openspec/specs/provider-usage-display/spec.md` — Delta for the modified All-view requirement

### Approaches

1. **Representative-bar row in All view** — Replace the current All-view `Repeater` (which shows every window per provider) with one compact row per provider: icon, name, source (elided), a single `QQC2.ProgressBar` for the representative window, percentage text, and optional raw reset text (elided). The representative window is computed by `selectRepresentative(windows)`: first finite `usedPercent` in Session → Weekly → Monthly order; if none, no bar is rendered.
   - Pros: Most compact; visually scannable across providers; reuses `selectCompact` fallback pattern; consistent with panel button logic; fits 400-line budget comfortably (~130–200 authored lines)
   - Cons: Non-representative windows are hidden in All view (user must select the provider tab to see them); information trade-off by design
   - Effort: Low–Medium

2. **All windows with inline thin bars in compact mode** — Keep showing every window per provider but render a thin progress bar for each window even in compact mode, alongside the existing percentage text.
   - Pros: No information loss; adds visual density
   - Cons: Does not reduce vertical space — All view remains as tall as today; less "compact"; bars at small scale may be hard to read with many windows
   - Effort: Low

3. **Representative bar + expandable detail per provider** — Default to one representative bar per provider; tapping/clicking a provider row in All view expands it to show full window detail inline.
   - Pros: Compact default with on-demand detail
   - Cons: Adds interaction state (expanded/collapsed per row) that complicates the transient selection model; more code; risks conflicting with the tab-based selection; not aligned with Plasma popup conventions for simple disclosure
   - Effort: Medium–High

### Recommendation

**Approach 1 — Representative-bar row in All view.** It directly addresses the "compact All + bars" goal, reuses the existing Session → Weekly → Monthly fallback pattern already established in `selectCompact`, stays well within the 400-line review budget, and preserves the detailed provider tabs as the path to full window visibility. The information trade-off (non-representative windows hidden in All) is intentional: the user sees a scannable cross-provider comparison at a glance and drills into a provider tab for full detail.

Implementation sketch:
- Add `selectRepresentative(windows)` to `UsageModel.js`: iterate `windowDefinitions` order, return first window with finite `usedPercent`, or `null`.
- Modify the All-view `Repeater` in `main.qml`: instead of `ProviderRow compact: true` (which shows all windows), use a new compact layout per provider — icon + name + source header (reuse `ProviderRow` header pattern), then a single `UsageWindowRow` for the representative window with `compact: false` (to show the bar), or nothing if no representative exists.
- Alternatively, add a `representative: bool` property to `ProviderRow` that, when true, filters `windows` to only the representative one and renders it with a bar (ignoring `compact` for that row). This keeps the component boundary clean.
- Detailed provider tabs remain unchanged (`compact: false`, all windows visible).

### Risks

- **Representative fallback edge case**: If a provider has windows but none with finite `usedPercent` (all null/non-finite), the row should still show the provider identity but with no bar and no percentage — just icon, name, source. Must be tested explicitly.
- **Visual regression in Breeze themes**: The progress bar in the compact All row must be readable at the narrower width. Use `QQC2.ProgressBar` with `Layout.fillWidth` inside a bounded row; test both Light and Dark.
- **Test harness coverage**: The existing `ProviderRowHarness` asserts `countProgressBars(compactRow) === 0`. The new representative mode needs its own assertion path — either a new harness instance or a modified compact-row fixture.
- **Spec delta scope**: The `Provider presentation` requirement currently says "`All` MUST show presentation-only compact summaries in provider order; detail MUST show every supplied Session, Weekly, and Monthly window." The delta must update the All-view description to mention the representative bar without breaking the detail-view contract.

### Ready for Proposal

**Yes.** The exploration has enough detail to proceed to `sdd-propose`. The orchestrator should tell the user:

- The change is bounded to presentation: one new pure function in `UsageModel.js`, a modified All-view layout in `main.qml`, and minor `ProviderRow`/`UsageWindowRow` adjustments.
- Detailed provider tabs and the external CLI boundary are untouched.
- The representative window fallback (Session → Weekly → Monthly) follows the existing `selectCompact` pattern — no new product decision needed.
- Estimated authored changed lines: ~130–200, within the 400-line budget.
- Strict TDD applies: new/updated harnesses must precede or accompany production QML changes.
