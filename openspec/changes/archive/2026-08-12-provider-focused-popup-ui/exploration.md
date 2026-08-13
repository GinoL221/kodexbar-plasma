# Exploration: provider-focused-popup-ui

## Problem Statement

The current Plasma popup renders every provider as a flat, vertically-stacked list (`main.qml` lines 96-105). Each `ProviderRow` shows the provider icon, name, raw source, and all available Session/Weekly/Monthly windows with `usedPercent` and raw reset metadata. While correct and accessible, this layout forces the user to scan all providers every time the popup opens. The target is a **provider-focused** popup where the user selects a single provider (or views all), and the selected provider gets a dedicated summary view with clear progress visualization and hierarchy.

## Current State

### Data Contract (immutable for this change)

The external `codexbar` CLI returns exactly `usage --provider all --format json --json-only`. The normalized model (`UsageModel.js`) exposes:

| Field | Type | Notes |
|-------|------|-------|
| `provider` | `string \| null` | Raw provider name from CLI |
| `source` | `string \| null` | Raw source identifier |
| `windows[]` | Array | Ordered: Session, Weekly, Monthly |
| `windows[].label` | `string` | Fixed labels from `windowDefinitions` |
| `windows[].usedPercent` | `number \| null` | Only finite numbers accepted |
| `windows[].resetsAt` | `raw` | Exact CLI value, no parsing |
| `windows[].resetDescription` | `raw` | Exact CLI value, no parsing |
| `errors[]` | Array | Committed provider failures |

The compact selection (`selectCompact`) picks the highest finite `usedPercent` with tie-breaking Session > Weekly > Monthly > CLI order.

### UI Surface

| File | Role |
|------|------|
| `contents/ui/main.qml` | `PlasmoidItem`: compact representation + `fullRepresentation` with flat `Repeater` of `ProviderRow` |
| `contents/ui/CompactUsageButton.qml` | Panel button: icon + highest percentage text |
| `contents/ui/ProviderRow.qml` | Provider card: icon, name, source, windows with `usedPercent` labels, raw reset text |
| `contents/ui/ErrorSummary.qml` | Expandable error disclosure (bounded to 20) |
| `contents/ui/UsageController.qml` | Lifecycle, refresh, timeout, coalescing (unchanged) |
| `contents/code/UsageModel.js` | Normalize + selectCompact (unchanged) |

### Existing Tests

- 3 `qmltestrunner` suites: `UsageModelTest` (8 assertions), `UsageControllerFixture` (12), `SettingsInteractionTest` (7)
- 16 executable `qml6` offscreen harnesses including `ProviderRowHarness`, `MainCompactHarness`, `CompactUsageButtonHarness`, `ErrorSummaryHarness`
- Manual live-Plasma smoke checklist in `docs/live-plasma-smoke.md`

### Provider Icons

49 SVG icons in `contents/icons/providers/` with a known-provider lookup table in `ProviderRow.iconSource()`. Unknown providers fall back to `dialog-information`.

## Current-State Gap

| Gap | Description |
|-----|-------------|
| No provider selection | All providers shown at once; no way to focus on one |
| No progress visualization | `usedPercent` rendered as text only ("72% used"); no bar or visual density |
| Flat hierarchy | Every window in every provider gets equal visual weight |
| No "All" aggregated view | Cannot see a cross-provider summary without scrolling the full list |
| No transient selection state | Popup always opens to the same flat list; no memory of last-selected provider within a session |

## User-Visible Outcome (target)

1. **Provider selector** at the top of the popup: horizontal set of tabs or a native selector with one entry per provider from the CLI response, plus an **All** pseudo-tab.
2. **All view**: equivalent to today's flat list (every provider, all windows), preserving current behavior for users who prefer it.
3. **Selected-provider view**: one provider gets dedicated space — larger icon, prominent name/source, each window rendered as a labeled progress bar (or equivalent native indicator) with `usedPercent`, and raw `resetsAt`/`resetDescription` below.
4. **Error summary** remains at the bottom, unchanged.
5. **Compact panel** remains unchanged — same highest-percentage logic, same button.
6. **Command** remains exactly `usage --provider all --format json --json-only`. The selector is presentation-only; it filters what is rendered, not what is fetched.

## Bounded Scope (first slice)

### In Scope

- Add a presentation-only provider selector with an `All` entry
- Render a focused summary for the selected provider with progress-bar-style `usedPercent` visualization
- Preserve the `All` view as the existing flat list
- Use native Plasma 6 / Kirigami controls only (e.g. `QQC2.TabBar`, `Kirigami.Separator`, `QQC2.ProgressBar` or custom bar with `Kirigami.Theme`)
- Preserve all existing accessible labels, keyboard navigation, theme adaptation, and narrow-popup behavior
- Add or update QML harnesses for the new components
- Update the live-Plasma smoke checklist for the new interaction

### Out of Scope (Non-Goals)

| Exclusion | Rationale |
|-----------|-----------|
| Cost, credits, or token amounts | Not in the data contract |
| Calculated or parsed reset durations | Only raw `resetsAt`/`resetDescription` are available |
| Provider authentication or switching | External CLI ownership |
| CLI argument changes | Command is authoritative and immutable |
| New external data sources | UI must not reimplement providers or fetching |
| Persistent selection across popup reopens | First slice is transient (within-session) only |
| Per-provider refresh or isolation | Refresh remains global and all-provider |
| Compact representation changes | Panel button stays as-is |

## Data Limitations

The UI redesign **must not fabricate** any of these:

- Cost, credits, or token counts (CLI does not supply them)
- Parsed or human-readable reset countdowns (only raw ISO timestamps or free-text descriptions are available)
- Provider stable IDs (only the raw `provider` string, which may be `null`)
- Last-updated timestamps
- Provider health or status beyond `error` entries already committed
- Window ordering beyond Session > Weekly > Monthly from `windowDefinitions`

## Interaction and Accessibility Requirements

| Requirement | Implementation constraint |
|-------------|--------------------------|
| Keyboard navigation | `TabBar` entries must be keyboard-reachable; `Tab`/`Shift+Tab` traverse selector, content, refresh, errors |
| Accessible labels | Each tab MUST have `Accessible.name`; selected provider summary MUST describe current `usedPercent` and window count |
| Focus indication | Native Plasma focus rings; no custom focus styling that breaks Breeze |
| Theme adaptation | All colors via `Kirigami.Theme` tokens; progress bar must be readable in Breeze Light and Dark |
| Narrow popup | Provider selector must wrap or scroll horizontally when provider count exceeds available width; content area must remain usable at `gridUnit * 30` minimum width |
| Screen reader | Selection change MUST announce the new provider; progress bar MUST expose its value semantically |
| Reduced motion | No decorative animations; any transition must respect system preferences |

## Approaches

### Approach 1: Horizontal TabBar with All + provider tabs

Use `QQC2.TabBar` at the top of the popup. First entry is `All`; subsequent entries are one per provider from the CLI response (raw `provider` string as tab label). Selecting a tab switches the content area between the full list (All) and a focused provider summary.

- **Pros**: Native Plasma control, keyboard-accessible by default, clear visual state, familiar pattern
- **Cons**: Horizontal overflow with many providers (10+); tab labels may truncate; `TabBar` may not scroll natively on all Plasma versions
- **Effort**: Medium — new selector component, new provider-detail component, update `main.qml` layout

### Approach 2: ComboBox / dropdown provider selector

Use `QQC2.ComboBox` with `All` + provider entries. Selecting changes the content area.

- **Pros**: Compact, handles unlimited providers, single-row footprint
- **Cons**: Less discoverable than tabs; hides provider names; extra click to switch; feels more like a settings control than a popup navigation
- **Effort**: Low-Medium — selector plus content swap; simpler layout

### Approach 3: Segmented button group (Kirigami-style)

Use a horizontal row of `QQC2.ToolButton` with exclusive check state, `All` first.

- **Pros**: Very native Plasma look, compact, keyboard-accessible
- **Cons**: No built-in overflow handling; manual layout for many providers; more custom code than `TabBar`
- **Effort**: Medium-High — custom layout, manual exclusive selection logic

### Recommendation

**Approach 1 (horizontal TabBar)** is recommended. It is the most native Plasma pattern for this use case, has built-in keyboard accessibility, and communicates the available options at a glance. The overflow concern is real but manageable: the popup already has `gridUnit * 30` minimum width and `TabBar` can be wrapped in a `QQC2.ScrollView` for horizontal scrolling when needed. The first slice should start with the assumption that provider counts are reasonable (<10) and add horizontal scroll overflow as a defensive measure.

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Tab overflow with many providers | Medium | Wrap `TabBar` in horizontal `ScrollView`; truncate long provider names with ellipsis; ensure minimum tab width for touch/keyboard |
| Transient selection lost on popup close | Low | Document as first-slice limitation; future slices may persist selection in `Plasmoid.configuration` |
| Progress bar accessibility | Medium | Use `QQC2.ProgressBar` with `Accessible.name`/`Accessible.description`; verify with screen reader in live smoke |
| Unknown provider icons in selector | Low | Tab labels use raw `provider` string; icon shown in detail view only; fallback `dialog-information` already exists |
| Breaking existing harnesses | Medium | `ProviderRowHarness` and `MainCompactHarness` must be updated or new harnesses created; run `./scripts/run-qml-tests.sh` after every change |
| Breeze theme contrast on progress bar | Medium | Use `Kirigami.Theme.highlightColor` for filled portion; test both Light and Dark in live smoke |
| Tab state vs. refresh | Low | Selection is transient and presentation-only; refresh replaces provider list and resets selection to `All` |
| 400-line review budget | Medium | Keep changes surgical: new selector component, new detail component, minimal `main.qml` surgery; provider row may need thinning for reuse in detail view |

## Affected Files and Symbols

| File | Impact |
|------|--------|
| `contents/ui/main.qml` | **Modify** — replace flat `Repeater` in `fullRepresentation` with selector + conditional content (All view vs. selected provider detail) |
| `contents/ui/ProviderSelector.qml` | **New** — horizontal `TabBar` with `All` + one tab per provider; exposes `selectedProvider` (null = All) |
| `contents/ui/ProviderDetailView.qml` | **New** — focused single-provider layout with progress bars for each window |
| `contents/ui/ProviderRow.qml` | **Possibly refactor** — extract progress-bar rendering so it can be reused in both `ProviderRow` (All view) and `ProviderDetailView`; or keep `ProviderRow` as-is for All view and build detail view independently |
| `contents/ui/CompactUsageButton.qml` | **Unchanged** |
| `contents/ui/ErrorSummary.qml` | **Unchanged** |
| `contents/ui/UsageController.qml` | **Unchanged** |
| `contents/code/UsageModel.js` | **Unchanged** — normalization and `selectCompact` stay as-is |
| `tests/ProviderSelectorHarness.qml` | **New** — verify tab creation, All default, selection change, unknown provider handling |
| `tests/ProviderDetailViewHarness.qml` | **New** — verify progress bar rendering, accessible labels, null-percentage handling |
| `tests/ProviderRowHarness.qml` | **Update** if `ProviderRow` is refactored |
| `tests/MainCompactHarness.qml` | **Unchanged** — compact selection logic is untouched |
| `scripts/run-qml-tests.sh` | **Update** — add new harness names to the harness loop |
| `docs/live-plasma-smoke.md` | **Update** — add keyboard and visual checks for provider selector and detail view |
| `openspec/specs/provider-usage-display/spec.md` | **Delta** — add/modify requirements for provider selector, All view, provider detail, progress visualization |

## Testing Implications

| Test | Action |
|------|--------|
| `UsageModelTest.qml` | **Unchanged** — normalization and `selectCompact` are not affected |
| `UsageControllerFixture.qml` | **Unchanged** — lifecycle is not affected |
| `SettingsInteractionTest.qml` | **Unchanged** — settings are not affected |
| `ProviderSelectorHarness.qml` | **New** — tab creation from provider list, `All` as default, selection changes, empty provider list, null provider names, keyboard focus |
| `ProviderDetailViewHarness.qml` | **New** — progress bar values, null-percentage handling, window labels, reset text, accessible names, narrow geometry |
| `ProviderRowHarness.qml` | **Update** if refactored; otherwise unchanged |
| `MainCompactHarness.qml` | **Unchanged** |
| `scripts/run-qml-tests.sh` | Add new harnesses to the loop |

Strict TDD applies: RED-GREEN-REFACTOR for every new component. Harnesses must be written before or alongside production QML.

## Open Product Questions

1. **Default selection on popup open**: Should the popup always open to `All` (preserving current behavior), or should it remember the last-selected provider within the session? **Recommendation for first slice: always open to `All`.**
2. **Tab label for null provider**: When `provider` is `null`, the tab label currently falls back to "Provider". Should the tab show a more descriptive placeholder like "(unknown)"? **Recommendation: use the existing "Provider" fallback for consistency.**
3. **Progress bar style**: Use native `QQC2.ProgressBar` (indeterminate-capable, standard look) or a custom bar using `Rectangle` with `Kirigami.Theme.highlightColor`? **Recommendation: `QQC2.ProgressBar` for native look; customize palette via Kirigami theme tokens if needed.**
4. **Tab overflow strategy**: Horizontal scroll, dropdown overflow menu, or wrap to multiple rows? **Recommendation: horizontal scroll via `ScrollView` for first slice.**
5. **Progress bar labeling**: Show "72% used" inside/beside the bar, or as a separate label? **Recommendation: separate label row above the bar for accessibility and narrow-popup readability.**

## Readiness Assessment

| Dimension | Status |
|-----------|--------|
| Codebase understood | Yes — all QML, JS model, tests, and specs reviewed |
| Data contract clear | Yes — bounded to existing `UsageModel.js` output |
| Non-goals explicit | Yes — no cost/credits/tokens/auth/CLI changes |
| Affected files identified | Yes — 2 new QML components, 1 modified, harnesses, docs |
| Risk within budget | Yes — 400-line review budget is tight but achievable with surgical changes |
| Open questions blocking | No — recommendations provided for all open questions |

## Ready for Proposal

**Yes.** The exploration has enough detail to proceed to `sdd-propose`. The orchestrator should tell the user:

- The redesign is bounded to presentation-only changes using the existing data contract
- Two new QML components (`ProviderSelector`, `ProviderDetailView`) plus a minimal `main.qml` surgery
- Existing tests preserved; two new harnesses required under strict TDD
- The 400-line review budget is achievable but requires disciplined scoping — no scope creep into persistence, auth, or CLI changes
- Five open product questions have recommendations; the user should confirm before proposal
