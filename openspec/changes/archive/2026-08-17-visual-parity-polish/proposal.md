# Proposal: Visual Parity Polish

## Intent

The popup shows correct data in a flat layout. `UsageWindowRow` crowds label, bar and percent on one line with resets stranded below; `ProviderHeader` stacks all identity in one left column with no plan emphasis; tabs and Cost carry visual noise. Users cannot answer "how close am I to my limit, and when does it reset" at a glance. Fix readability using only data the CLI already returns.

## Scope

### In Scope

1. `UsageWindowRow.qml`: title → full-width bar → `% used` | `Resets in…` in one band; density/separator polish.
2. `ProviderHeader.qml`: two columns — identity/source plus clean `Updated` left, plan/login badge right.
3. `ProviderSelector.qml`: tab noise reduction, plus `%`-in-tab label (requires a `provider-usage-display` requirement delta — see Capabilities).
4. `CostSection.qml`: typography polish plus an informational footer (status / last-updated), no new controls.
5. Regenerate goldens via the existing Docker `UPDATE_GOLDENS=1` harness; Breeze Light/Dark smoke; `docs/ui-parity-checklist.md` pass.

### Out of Scope

- Extra usage / per-model windows and `usage.providerCost` — no CLI backing.
- Threshold-colored usage bar (tab/row) — no color-by-threshold module exists; percent already carries the signal; deferred as a separate future change (tracked in Engram backlog).
- Relocating the single global Refresh control.
- Auth, Add Account, Quit, redemption, Settings or About controls.
- macOS glass skin, web CSS, fixed brand colors, tray-app behavior.
- Changing `usage --provider all --format json --json-only` or the `cost` command.
- Computing pricing, pace or resets in QML.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `provider-usage-display`: presentation requirements for window-row hierarchy, header plan/login badge and informational footer, PLUS a genuine requirement delta: the tab requirement changes from "icon and short provider name only" to "icon, short provider name, and usage percent". Runtime, command and exclusion requirements unchanged.
- `provider-cost-estimate`: no requirement change — Cost is typography only, inside the existing fail-closed contract.

## Approach

One change, five chained work units (exploration Approach 1, matching `qml-visual-regression`). Layout only: no controller, model or CLI surface touched. Kirigami.Units / Kirigami.Theme exclusively, no hardcoded colors. `objectName` aliases asserted by existing harnesses change RED-first in the same TDD cycle. Goldens regenerate once, in the final unit.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/ui/UsageWindowRow.qml` | Modified | Row hierarchy restructure |
| `contents/ui/ProviderHeader.qml` | Modified | Two columns + plan badge |
| `contents/ui/ProviderSelector.qml` | Modified | Tab polish |
| `contents/ui/CostSection.qml` | Modified | Typography |
| `contents/ui/main.qml` | Modified | Informational footer |
| `tests/*Harness.qml`, `tests/*Test.qml` | Modified | objectName assertions |
| `tests/visual/goldens/*.png` | Modified | Regenerated |
| `docs/ui-parity-checklist.md` | Modified | Verification record |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Restructure breaks harness assertions | High | Update them RED-first, same cycle |
| Golden churn across slices | High | Regenerate once, final unit |
| Footer drifts into a control | Med | Read-only text; checklist gate |
| Threshold color as sole signal | Med | Semantic theme colors, redundant to percent |
| Slice exceeds 400-line budget | Med | Stacked-to-main, one slice per PR |

## Rollback Plan

Each slice is one PR over QML view files and their tests. Revert the offending PR and re-run `./scripts/run-visual-tests.sh`; goldens restore from the prior commit. No data, config, schema or CLI contract is involved, so rollback is total.

## Dependencies

- Applied `qml-visual-regression` harness and Docker for golden regeneration.

## Success Criteria

- [ ] A window reads as title → bar → `% used` / `Resets in…` in one band.
- [ ] Header shows identity left, plan/login badge right, uncluttered `Updated`.
- [ ] Cost and footer read cleanly with no new control added.
- [ ] `run-qml-tests.sh` and `run-visual-tests.sh` pass with regenerated goldens.
- [ ] Breeze Light/Dark smoke and `docs/ui-parity-checklist.md` pass.
- [ ] Usage and cost CLI invocations unchanged.
