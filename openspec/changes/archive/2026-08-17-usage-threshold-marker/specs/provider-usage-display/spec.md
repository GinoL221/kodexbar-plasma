# Delta for Provider Usage Display

## ADDED Requirements

### Requirement: Usage window threshold risk marker

Each rendered usage window bar (Overview summary and selected-provider detail alike) MUST classify its finite `usedPercent` into a fixed level — `ok` (<70), `warn` (70–89.99), `critical` (>=90) — via pure classification logic, with no level for non-finite or absent `usedPercent`. The `warn` and `critical` levels MUST render one risk marker icon positioned adjacent to the window's percent value, sized independently of the bar's own height so it stays legible on thin Overview bars: in Overview summary mode the marker sits after the bar, immediately before the percent text; in selected-provider detail mode the marker sits immediately after the percent text. `warn` uses a bundled warning-triangle glyph (`contents/icons/threshold-warning.svg`) colored `Kirigami.Theme.neutralTextColor`, `critical` uses a bundled critical-circle glyph (`contents/icons/threshold-critical.svg`) colored `Kirigami.Theme.negativeTextColor`; both are recolorable mask icons, not a system icon-theme lookup. The `ok` level and the no-level case MUST render no marker. The bar fill color (`ProviderIcons.accent()`, `Kirigami.Theme.highlightColor` fallback) MUST remain identical at every level; the marker MUST NOT recolor, resize, or otherwise alter the fill, and MUST NOT be overlaid on top of the bar itself. The marker's layout slot MUST be reserved at a fixed width regardless of threshold level — bar track length MUST stay identical across all windows whether or not a given window shows a marker (`ok`/no-level windows render the marker invisible-but-space-reserved, not absent-and-collapsed), preserving the existing fixed-column, equal-track-length convention. Marker presence, position, icon, and color rules MUST apply identically whether the bar renders in Overview summary mode or selected-provider detail mode, using one shared implementation so the two cannot diverge. `ProviderSelector.qml`'s tab underline usage bar MUST NOT gain this marker; it remains brand-accent only, unchanged. Each window's accessible description MUST append risk phrasing after its existing percent entry when the level is `warn` or `critical`, leaving all other entries and their relative order unchanged; `ok` and no-level add no risk phrasing. Threshold boundaries (70/90) are fixed v1 policy, not user-configurable, and this marker is a UI-only display change with no CLI invocation, model, schema, or controller change.

#### Scenario: Below warn threshold shows no risk marker
- GIVEN a finite `usedPercent` below 70
- WHEN the bar renders in summary or detail mode
- THEN no risk marker icon appears

#### Scenario: Warn range shows a neutral risk marker
- GIVEN a finite `usedPercent` in [70, 90)
- WHEN the bar renders
- THEN the bundled warning-triangle marker (`threshold-warning.svg`) appears adjacent to the percent text, colored `Kirigami.Theme.neutralTextColor`

#### Scenario: Critical range shows a negative risk marker
- GIVEN a finite `usedPercent` >= 90
- WHEN the bar renders
- THEN the bundled critical-circle marker (`threshold-critical.svg`) appears adjacent to the percent text, colored `Kirigami.Theme.negativeTextColor`

#### Scenario: Fill color is threshold-independent
- GIVEN any threshold level, including no level
- WHEN the bar renders
- THEN the fill remains `ProviderIcons.accent()` or the `Kirigami.Theme.highlightColor` fallback, never threshold-colored

#### Scenario: Bar track length is threshold-independent
- GIVEN two Overview summary windows with the same label and percent-text width but different threshold levels (e.g. one `ok`, one `critical`)
- WHEN both bars render
- THEN their track widths are equal — the reserved marker slot does not shrink the bar on rows that show a marker relative to rows that don't

#### Scenario: Non-finite or absent percent shows no bar and no risk marker
- GIVEN `usedPercent` is non-finite or absent
- WHEN the row renders
- THEN no bar is rendered and no risk marker appears, preserving existing behavior

#### Scenario: Accessible description gains risk phrasing at risk levels
- GIVEN a window's level is `warn` or `critical`
- WHEN its accessible description is computed
- THEN risk phrasing is appended after the existing percent entry, with existing entries and their order otherwise unchanged

#### Scenario: Tab underline bar is excluded from the marker
- GIVEN `ProviderSelector.qml`'s tab underline usage bar
- WHEN any provider tab renders at any threshold level
- THEN the underline shows brand accent color only, with no risk marker icon or recoloring

#### Scenario: Summary and detail modes stay identical
- GIVEN the same provider and window rendered in both Overview summary mode and selected-provider detail mode
- WHEN each bar renders
- THEN risk marker presence, icon, and color match exactly between the two modes, with no mode-specific divergence
