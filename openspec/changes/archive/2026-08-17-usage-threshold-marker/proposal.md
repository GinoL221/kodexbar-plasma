# Proposal: Usage Threshold Marker

## Intent

Bars answer "how much have I used" but not "should I care yet". At a glance a 68% and a 94% bar differ only by fill length and a percent string the eye skips. Users hit provider limits mid-task with no earlier visual warning. Add a risk signal that is redundant to the percent, not a replacement for it, without sacrificing the brand-accent fill that identifies the provider.

## Scope

### In Scope

1. `contents/code/UsageThreshold.js` (new, `.pragma library`): pure `usedPercent` → level classification — `ok` (<70), `warn` (70–89.99), `critical` (>=90); non-finite/absent → no level.
2. `contents/ui/UsageWindowRow.qml`: a small circular dot anchored at the right edge of the bar fill, rendered in BOTH bar blocks (summary `~151-181`, detail `~228-252`). `warn` → `Kirigami.Theme.neutralTextColor`, `critical` → `Kirigami.Theme.negativeTextColor`, `ok` → no dot.
3. Bar fill stays brand accent ALWAYS (`ProviderIcons.accent()`, `Kirigami.Theme.highlightColor` fallback). Threshold never recolors the fill.
4. `Accessible.description`: risk phrasing appended after the existing percent entry; existing entry text and relative order unchanged.
5. New harnesses `tests/UsageThresholdHarness.qml` (pure JS levels) and `tests/UsageWindowThresholdHarness.qml` (dot presence, geometry, color, both modes).
6. Harness split: move the `weeklySummaryWindowRow`/`monthlySummaryWindowRow` fixtures, their D20 elide asserts, and the `summaryPercentColumnWidth`/`summaryLabelColumnWidth` floor checks out of `tests/ProviderRowHarness.qml` (841 lines) into the existing `tests/SummaryBarNormalizeHarness.qml` — those are column-width/elide concerns, not composition.

### Out of Scope

- Threshold recoloring the bar fill (rejected alternative).
- Threshold on `ProviderSelector.qml` tab underline bars — brand only, unchanged.
- User-configurable thresholds, settings, or preferences.
- Splitting `tests/ProviderSelectorHarness.qml` — tabs carry no threshold.
- Rewriting the rest of `ProviderRowHarness.qml`: composition, cost, credits, D10 window selection, overview indent, a11y, reset precedence and responsive popup geometry stay put.
- `usage.providerCost`, in-popup Settings/About, self-hosted CI, Auth/Quit, fabricated CLI metrics.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `provider-usage-display`: genuine requirement delta — window bars gain a threshold risk marker with fixed 70/90 boundaries, the accent fill is pinned as threshold-independent, tab underlines are explicitly excluded, and the accessible description gains risk phrasing. Runtime, command and exclusion requirements unchanged.

## Approach

Classification is pure JS in `UsageThreshold.js`, mirroring the `UsageModel.js` / `ProviderIcons.js` convention, so levels are unit-testable without a scene. The dot is one reusable inline `Component` declared once in `UsageWindowRow.qml` and instantiated in each bar block, both reading the same level property and fill geometry — one right-edge clamp implementation, so summary and detail cannot drift. Strict TDD: no production code before a task's harness assert is RED.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/code/UsageThreshold.js` | New | Pure level classification |
| `contents/ui/UsageWindowRow.qml` | Modified | Dot component, both bar blocks, a11y |
| `tests/UsageThresholdHarness.qml` | New | Level boundaries |
| `tests/UsageWindowThresholdHarness.qml` | New | Dot render/geometry/color |
| `tests/SummaryBarNormalizeHarness.qml` | Modified | Receives moved column/elide asserts |
| `tests/ProviderRowHarness.qml` | Modified | Loses moved asserts only |
| `tests/visual/goldens/*.png` | Modified | Regenerated once |
| `docs/ui-parity-checklist.md` | Modified | Verification record |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Dot clamp overhangs at 100% / underhangs near 0% | Med | Flagged as an open design question; moot below 70% |
| Summary/detail dot drift | Med | Single shared Component, asserted in both modes |
| Harness move silently drops asserts | Med | Move RED-first; assert count checked both files |
| Dot as sole signal for color-blind users | Med | Semantic theme colors, redundant to percent text |
| Golden churn | Med | Regenerate once, final unit |
| Slice exceeds 400-line budget | Med | Split marker work from harness move |

## Rollback Plan

Two independent reverts. Reverting the marker PR removes `UsageThreshold.js`, its two harnesses and the `UsageWindowRow.qml` dot; bars return to accent-only fill. Reverting the harness-split PR restores `ProviderRowHarness.qml`. No model, controller, config, schema or CLI surface is touched, so rollback is total; re-run `./scripts/run-qml-tests.sh` and `./scripts/run-visual-tests.sh`.

## Dependencies

- Existing qml6 offscreen harness runner and Docker golden regeneration.

## Success Criteria

- [ ] A window at >=90% is distinguishable from one at 68% without reading the percent.
- [ ] Bar fill is the provider accent at every threshold level.
- [ ] Dot appears identically in Overview summary and detail bars; absent below 70% and when `usedPercent` is non-finite.
- [ ] Tab underline bars are visually unchanged.
- [ ] `ProviderRowHarness.qml` and `SummaryBarNormalizeHarness.qml` together assert everything the pre-split file asserted.
- [ ] `run-qml-tests.sh`, `lint-qml.sh` and `run-visual-tests.sh` pass; Breeze Light/Dark smoke passes.
- [ ] Usage and cost CLI invocations unchanged.
