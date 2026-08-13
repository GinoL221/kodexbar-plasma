# Design: Compact All-Provider Usage Bars

## Technical Approach

Keep normalization, controller lifecycle, and the external `codexbar` request unchanged. Add a pure `UsageModel.selectRepresentative(windows)` selector, then make `ProviderRow` explicitly support summary versus detail presentation. In `All`, each provider row renders its identity plus only the selected window through the existing native `UsageWindowRow`; detail tabs continue rendering every normalized window.

The work follows strict RED-GREEN-REFACTOR and is estimated at 180–260 changed lines, below the 400-line review budget.

## Architecture Decisions

| Option | Tradeoff | Decision |
|---|---|---|
| Select the representative window in `UsageModel.js` | Adds one model API but keeps finite-value and priority rules out of QML layout code | Chosen: one pure selector returns the original normalized window or `null`. |
| Select inside each QML delegate | Fewer model lines, but duplicates domain ordering and is harder to unit-test | Rejected. |
| Add explicit `summary` mode to `ProviderRow`/`UsageWindowRow` | Small internal contract change; clearly separates one-window summary from all-window detail | Chosen over overloading the old `compact` flag, whose current meaning is “hide bars.” |
| Create a new summary component | Strong isolation but duplicates provider identity, accessibility, icon, and elision behavior | Rejected to keep behavior consistent and scope bounded. |

## Data Flow

```text
codexbar JSON → UsageController → UsageModel.normalize()
                                      │
                         committedProviders (response order)
                                      │
          All → ProviderRow(summary) → selectRepresentative(windows)
                                      → zero/one UsageWindowRow + bar
       provider tab → ProviderRow(detail) → every UsageWindowRow
```

`CompactUsageButton` continues using global `selectCompact()` and is unaffected.

## File Changes

| File | Action | Description |
|---|---|---|
| `contents/code/UsageModel.js` | Modify | Add canonical Session → Weekly → Monthly finite representative selection. |
| `contents/ui/main.qml` | Modify | Mark only `All` delegates as summaries; retain detail-tab wiring. |
| `contents/ui/ProviderRow.qml` | Modify | Derive a zero-or-one summary window while preserving identity, icons, source, accessibility, and non-interactive structure. |
| `contents/ui/UsageWindowRow.qml` | Modify | Replace bar-hiding compact semantics with a one-line summary that shows label, percentage, and native `QQC2.ProgressBar` but omits reset lines. |
| `tests/UsageModelTest.qml`, `tests/UsageModelHarness.qml` | Modify | Add RED cases for priority, fallback, non-finite values, and `null`. |
| `tests/ProviderRowHarness.qml` | Modify | Prove one bar per summary, identity-only fallback, no controls/expansion, narrow elision, and unchanged detail rows. |
| `tests/MainCompactHarness.qml` | Modify | Prove per-provider representative selection remains separate from global panel selection and retained snapshots. |
| `docs/live-plasma-smoke.md` | Modify | Replace the obsolete no-bar check with one-bar, identity-only, non-expansion, narrow-layout, and Breeze Light/Dark checks. |

`scripts/run-qml-tests.sh` needs no change: all modified QtTest inputs and executable harnesses are already registered.

## Interfaces / Contracts

```javascript
selectRepresentative(windows) // normalized window object | null
```

- Priority is `primary` (Session), `secondary` (Weekly), then `tertiary` (Monthly), independent of percentage magnitude.
- A candidate requires numeric, finite `usedPercent`; missing, string, `NaN`, and infinities are ignored.
- No value is cloned or fabricated.
- `ProviderRow.summary === true` renders identity and at most one window; `false` renders all supplied windows.
- `UsageWindowRow.summary === true` keeps the representative label, percentage, and bar on the summary surface but leaves exact reset fields to the unchanged detail tab.
- Summary rows introduce no click handler, disclosure control, or expansion state.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit | Selector precedence and invalid-value fallback | Add failing `UsageModelTest.qml` cases first. |
| Component | Exact bar count/value, identity-only state, preserved detail/reset data, accessibility and narrow geometry | Extend `ProviderRowHarness.qml` before production QML. |
| Integration | Per-provider summaries coexist with unchanged global compact selection and snapshots | Extend `MainCompactHarness.qml`; run `./scripts/run-qml-tests.sh`. |
| E2E | Native bar readability, keyboard non-expansion, elision, Breeze themes | Update and execute the manual live-Plasma checklist. |

## Threat Matrix

N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary changes.

## Migration / Rollout

No migration or feature flag required. Roll back the model/UI/test/doc edits together; CLI, persisted configuration, provider tabs, and lifecycle data remain compatible.

## Open Questions

None.
