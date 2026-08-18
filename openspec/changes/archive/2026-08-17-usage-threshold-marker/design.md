# Design: Usage Threshold Marker

## Technical Approach

One new pure JS library (`contents/code/UsageThreshold.js`), one modified view file
(`contents/ui/UsageWindowRow.qml`), and test-only changes. No controller, model,
normalization, config, schema or CLI surface is touched: `usedPercent` already
arrives on `windowData` and is already validated by `UsageModel.normalize`.

Classification is a `.pragma library` pure function so every boundary is unit-testable
without a scene graph, exactly like `UsageModel.js`, `ProviderIcons.js` and
`RelativeTime.js`. The marker itself is one inline `Component` declared once in
`UsageWindowRow.qml` and instantiated by a `Loader` inside each of the two existing bar
blocks (summary `UsageWindowRow.qml:151-181`, detail `:228-252`), so summary and detail
share a single geometry/color implementation and cannot drift.

The bar fill (`root.barFillColor`, `UsageWindowRow.qml:53-55`) is not touched by any
decision below — the marker is strictly additive paint on top of an unchanged track.

Strict TDD (`openspec/config.yaml: strict_tdd: true`): every unit below names its RED
anchor, and no production line is written before that anchor fails.

## Architecture Decisions

| # | Decision | Alternatives rejected | Rationale |
|---|----------|-----------------------|-----------|
| D1 | **`contents/code/UsageThreshold.js` public surface** (`.pragma library`): `WARN_AT = 70`, `CRITICAL_AT = 90`, `LEVEL_NONE = ""`, `LEVEL_OK = "ok"`, `LEVEL_WARN = "warn"`, `LEVEL_CRITICAL = "critical"`, plus `function level(usedPercent)` and `function isRisk(levelValue)`. A private `finiteNumber(value)` predicate is **duplicated** from `UsageModel.js` rather than imported via `.import` | `.import "UsageModel.js" as UsageModel` to reuse `finiteNumber`; a single `function isCritical`/`isWarn` pair with no level string; exporting only functions and keeping 70/90 inline | Top-level `var`s on a `.pragma library` resource are reachable as `UsageThreshold.WARN_AT` from QML and from the harness, which is what pins the policy in exactly one place (D3). `ProviderIcons.js` is likewise standalone and duplicates nothing-but-itself; cross-importing two libraries to share a three-line typeof/isFinite predicate couples the threshold policy to the normalization model for no benefit and makes `UsageThreshold.js` un-loadable on its own. A level *string* (not two booleans) is what the spec's `ok`/`warn`/`critical` vocabulary and the a11y branch both need |
| D2 | **`level(usedPercent)` contract**: returns `LEVEL_NONE` (`""`) for anything that is not a finite JS `number` — `null`, `undefined`, `"80"`, `NaN`, `±Infinity`, objects; otherwise `LEVEL_CRITICAL` when `usedPercent >= CRITICAL_AT`, `LEVEL_WARN` when `usedPercent >= WARN_AT`, else `LEVEL_OK`. Bounds are **inclusive-lower / exclusive-upper**: `69.9 → ok`, `70 → warn`, `89.9 → warn`, `90 → critical`. Values above 100 and below 0 are classified, never clamped (`120 → critical`, `-5 → ok`) | Coerce string input with `Number(value)`; clamp the input to `[0, 100]` first; return `"ok"` for absent input | `""` vs `"ok"` is a real distinction the spec draws ("no level for non-finite or absent"), and collapsing them would make an absent percent indistinguishable from a healthy one for any future consumer. Numeric coercion of `"80"` would accept CLI-shaped strings the normalizer already rejects (`UsageModel.js:9-11` uses the same `typeof`+`isFinite` gate), silently widening the contract. Clamping is the *renderer's* job (`barRatio`, `UsageWindowRow.qml:27-32`) and is already done there; a classifier that clamps would hide a >100% payload from any future caller |
| D3 | **QML never writes `70` or `90`.** `UsageWindowRow.qml` compares only against `UsageThreshold.LEVEL_*` constants and calls `UsageThreshold.isRisk(...)`; the numeric boundaries appear in `UsageThreshold.js` and in `tests/UsageThresholdHarness.qml`'s explicit `WARN_AT === 70` / `CRITICAL_AT === 90` assertions and nowhere else | Inline `>= 70` in the QML `visible` binding; a `readonly property int warnAt: 70` on the row root mirroring the JS constant | A mirrored QML constant is a second source of truth that can silently drift from the JS one; asserting the constants' values in the harness makes the 70/90 policy a *tested contract* rather than a comment, so a future change to the boundaries is a one-line edit with one RED test |
| D4 | **`readonly property string thresholdLevel: UsageThreshold.level(root.windowData.usedPercent)`** on the `UsageWindowRow` root, declared next to the existing `hasFinitePercent` / `barRatio` block (`:23-32`). The property is named `thresholdLevel`, not `level` | `level`; computing the level inline in each of the three consumer bindings; passing `root.hasFinitePercent ? root.windowData.usedPercent : null` | One binding, three consumers (dot `visible`, dot `color`, `Accessible.description`), so the classifier runs once per data change and the three can never disagree. `level` alone is too generic on a row that already carries percent/ratio/height/color semantics and reads ambiguously at every call site (`root.level`); `thresholdLevel` pairs with the `thresholdDot` objectName (D8). Passing `usedPercent` straight through is safe *because* of D2 — the guard lives in one place instead of being restated at the call site |
| D5 | **[Geometry/color superseded by D19-D21 — see Revision 1 below; the frame-`Item`+`Loader` shape itself is unchanged.]** One inline `Component` + two `Loader`s. `Component { id: thresholdDotComponent; Item { ... Rectangle { objectName: "thresholdDot" ... } } }` is declared once at the root level of `UsageWindowRow.qml`; each bar block gets `Loader { anchors.fill: parent; sourceComponent: thresholdDotComponent }`. The component's **root is a transparent frame `Item`**, and the dot `Rectangle` is its child | Duplicating the eight-line `Rectangle` in both bar blocks; a new `contents/ui/ThresholdDot.qml` file; making the `Rectangle` itself the component root; `thresholdDotComponent.createObject(...)` from JS | The proposal fixes "one shared implementation" and the spec makes non-divergence a requirement, so duplication is out. A separate `.qml` file would satisfy sharing but contradicts the proposal's stated approach and would need four plumbed-in properties (`level`, `barHeight`, `trackWidth`, `barRatio`) to say what `root.` already says in-file. The frame `Item` is **not** cosmetic: a `Loader` with an explicit size (here, `anchors.fill`) resizes its loaded item to the `Loader`, which would stretch a `Rectangle`-rooted component across the whole track and destroy the circle. With a frame root, the frame absorbs the stretch and the dot keeps its own `width`/`height`. `createObject` is imperative, loses declarative re-binding on `thresholdLevel` change, and is untestable by tree search |
| D6 | **[SUPERSEDED by D20 — see Revision 1 below.]** Dot geometry: `width = height = diameter`, `radius = diameter / 2`, `diameter = root.barHeight` (the existing per-mode value: `max(4, round(smallSpacing * 0.75))` summary, `max(8, round(smallSpacing * 1.1))` detail, `:49-51`), `anchors.verticalCenter: parent.verticalCenter` on the frame | A fixed px diameter; `barHeight * 1.5` overflowing the track for scannability; `Kirigami.Units.smallSpacing` directly | `diameter == barHeight` with `radius == barHeight / 2` makes the dot **exactly congruent with the fill's own rounded end cap** (the fill uses `radius: height / 2`, `:178`/`:249`), so at any percent the marker reads as "the tip of the bar is a different color" and can never produce a shape that varies with percent. It also inherits the mode-appropriate scale for free, with no second responsive rule to maintain. A larger overflowing dot is deliberately deferred (see Risks / Open Questions) |
| D7 | **[SUPERSEDED by D20 — see Revision 1 below.]** Right-edge clamp: the dot's x inside the frame is `Math.max(0, Math.min(dotFrame.width, Math.round(dotFrame.width * root.barRatio)) - diameter)`. No `clip` is enabled anywhere | Centering the dot on the fill edge (`x = fillWidth - diameter / 2`); `clip: true` on the bar `Item`; parenting the dot inside the fill `Rectangle` with `anchors.right: parent.right`; letting x go negative | `Math.round(dotFrame.width * root.barRatio)` is *byte-identical to the fill's own width expression* (`:177`, `:248`), so the dot tracks the fill by construction rather than by a parallel approximation. Right-aligning (`- diameter`) instead of centering means at `usedPercent = 100` the dot's right edge lands exactly on the track's right edge — inscribed in the end cap, zero overhang, nothing to clip. `Math.min(dotFrame.width, ...)` is defensive only (`barRatio` is already clamped to `[0,1]` at `:27-32`) but states the no-overhang invariant locally, where a future fill-width change would have to break it visibly. `Math.max(0, ...)` defines the sub-diameter case: below `diameter / trackWidth` the dot parks at the track's left edge instead of hanging off it. That branch is unreachable in practice — the dot needs `level >= warn`, i.e. `fillWidth >= 0.7 * trackWidth`, and the summary track is asserted `>= 48px` (`tests/SummaryBarNormalizeHarness.qml:66`) against a 4-6px dot — but it is *defined* rather than undefined. `clip: true` costs a render pass per bar, would truncate the marker into a half-circle exactly at the critical end of the range (a shape that varies with percent, contradicting D6), and would also clip the fill's own antialiased cap |
| D8 | **[Objectname renamed to `thresholdMarker` by D22 — see Revision 1 below; the scoping rationale is unchanged.]** `objectName: "thresholdDot"` on the dot `Rectangle` only; the frame `Item` carries no `objectName`. Tests scope their search through the existing `root.progressBar` handle (`summaryBar` in summary mode, `detailBarHost` in detail mode, `:37`), never from the row root | `objectName` on the frame too; distinct names per mode (`summaryThresholdDot` / `detailThresholdDot`); a `property alias thresholdDot` on the row root | Distinct names would re-introduce exactly the summary/detail asymmetry D5 exists to prevent, and would let a test pass in one mode while the other silently regressed. **Both** instances always exist in the tree (only one is *effectively* visible, because `summaryBar.visible` is `root.summary && root.showBar` at `:154` and `detailBarHost.visible` is `!root.summary && root.showBar` at `:218` — the same one-of-two pattern the file already uses for `summaryPercentageLabel` / `bandPercentageLabel`), so a recursive `findObject(row, "thresholdDot")` from the row root would return an arbitrary one of the two. Scoping through `row.progressBar` is unambiguous, needs no new exported handle, and reuses a handle every existing harness already holds. An alias is impossible anyway: `property alias` cannot point inside a `Loader`'s component (the same constraint recorded in the previous change's D14) |
| D9 | **[Icon source superseded by D21 — see Revision 1 below; the `visible`/fallback-arm rationale is unchanged.]** Color and visibility: `visible: UsageThreshold.isRisk(root.thresholdLevel)`; `color: root.thresholdLevel === UsageThreshold.LEVEL_CRITICAL ? Kirigami.Theme.negativeTextColor : root.thresholdLevel === UsageThreshold.LEVEL_WARN ? Kirigami.Theme.neutralTextColor : "transparent"`. `root.barFillColor` (`:53-55`) and both bars' `Accessible.name` (`:163`, `:234`) are **not** modified | Recoloring the fill at risk levels; tinting the track background; adding the risk word to the bar's `Accessible.name`; omitting the `"transparent"` fallback | The spec pins the fill as threshold-independent and the proposal names fill recoloring as the rejected alternative — the accent is provider identity, and overloading it with risk would make two orthogonal signals fight for one channel. The `"transparent"` arm is unreachable while `visible` is bound to `isRisk`, but it keeps `color` total: an invisible item with an invalid color binding still logs a QML warning, and the lint gate fails closed on warnings. The row-level `Accessible.description` (D10) is the single a11y carrier; adding risk text to the bar's own `Accessible.name` too would read the risk twice per window in a screen reader |
| D10 | **Accessible.description strings and insertion point**: inside the existing `if (root.hasFinitePercent)` block (`:91-94`), immediately after the existing `"%1% used"` push, add a nested branch pushing exactly `"Critical usage"` for `LEVEL_CRITICAL` and `"Elevated usage"` for `LEVEL_WARN`, both through `Translation.translate(..., [], typeof i18n === "function" ? i18n : null)` like every other entry | A sibling `if` after the whole percent block; appending to the percent string itself (`"94% used, critical"`); `"High usage"` / `"Very high usage"`; lowercase fragments | Nesting inside the finite-percent branch makes "appended **after** the percent entry" a structural guarantee rather than an ordering convention — a risk level cannot exist without a finite percent (D2), so the nesting adds no reachable behavior change while making mis-ordering impossible to write. Mutating the percent string would change the existing entry's text, which the spec forbids. `Elevated` / `Critical` are distinct at the first syllable (unlike `High` / `Very high`, which a screen reader user hears as a prefix collision) and match the sentence-capitalized register of the neighbouring `"Reset: %1"` entry. Exact final strings are fixed here so the harness can assert them literally |
| D11 | **Declaration order / stacking**: each bar block's `Loader` is declared **last**, after the track background `Rectangle` and the fill `Rectangle`. No `z` is set anywhere | Explicit `z: 1` on the dot; declaring the Loader first | QtQuick paints siblings in declaration order, so last-declared is already on top of the fill; an explicit `z` would be redundant and would invite a future `z` arms race between siblings that have no other reason to carry one |
| D12 | **Re-pin the qmllint exception.** `scripts/check-qml-unqualified-baseline.py`'s `LAYOUT_POSITIONING_EXCEPTIONS` matches `("Quick.layout-positioning", "root.width", <line>)` by **exact line number**. Every edit in D4 (root property), D10 (a11y branch) and the `UsageThreshold.js` import inserts lines *above* `titleRow`'s sanctioned `width: root.width` binding, so the pinned line must be recomputed from the actual `./scripts/lint-qml.sh` output after the QML edit and updated in the same work unit | Relaxing the matcher to id+span only; moving the sanctioned binding; touching `titleRow` to dodge the shift | The pin is deliberately strict (its own comment: a second unreviewed `width: root.width` must not be silently swallowed), so loosening it to id+span would delete the protection this change is merely inconveniencing. **Unverified in this phase and load-bearing:** the checked-in pin is line `89`, but the sanctioned binding currently sits at `contents/ui/UsageWindowRow.qml:121` — a 32-line delta that matches the size of the block commit `0692c43` inserted above it (`TextMetrics` + column-width properties). This design phase has no shell, so whether the gate is already red on the branch tip or whether qmllint reports a different line than the one I read is **not proven here**; the first task of the marker unit must run `./scripts/lint-qml.sh` *before* editing and record the real number. Either way the line moves again under this change and must be re-pinned |
| D13 | **Harness split content plan.** `tests/ProviderRowHarness.qml` loses exactly the `weeklySummaryWindowRow` + `monthlySummaryWindowRow` fixtures (`:460-485`, comments included), the two column-floor asserts (`:720-730`) and the two D20 elide asserts (`:732-741`) — **4 asserts, 2 fixtures**. `tests/SummaryBarNormalizeHarness.qml` gains: `import org.kde.kirigami as Kirigami`, both fixtures **moved verbatim** (same ids, same `width: 260`, same explanatory comments, `y: 120` / `y: 160` to clear the existing rows), the two elide asserts unchanged, and the two column-floor asserts **retargeted from `summaryWindowRow` to the existing `normSession1` fixture** — 4 asserts, no new fixture for the floors | Retargeting the elide asserts onto the existing `normWeekly100` / `normMonthly42` rows instead of moving fixtures; moving `summaryWindowRow` too; renaming the moved fixtures to the harness's `norm*` convention | `summaryWindowRow` must stay: `ProviderRowHarness` still asserts against it at `:718`, `:742-744` and `:748-757`. `summaryLabelColumnWidth` / `summaryPercentColumnWidth` are per-instance `readonly` properties derived only from `TextMetrics` over fixed reference strings and the row's own fonts (`:66-81`), so `normSession1` computes byte-identical values — reuse is exact, not approximate. The elide fixtures cannot be folded into `norm*` the same way: the D20 truncation was **width-sensitive** and the existing rows are `320px` wide, so reusing them would keep the assertion green while deleting the regression it was written to catch. Names are preserved verbatim so the move is diff-verifiable as a move (the proposal's "silently drops asserts" risk); cosmetic renaming would obscure exactly that |
| D14 | **`tests/UsageThresholdHarness.qml`** is pure JS with no visual fixtures: `Item { width: 1; height: 1 }` + `Component.onCompleted` + the repo's standard `assert`/`finish` pair, mirroring `tests/RelativeTimeHarness.qml` verbatim. It asserts the constants (`WARN_AT === 70`, `CRITICAL_AT === 90`) and the full boundary table of D2 | A `Timer`-driven harness like the geometry ones; folding these cases into `UsageModelTest.qml` | No scene means no settle delay, so `Component.onCompleted` is sufficient and the harness is deterministic. Keeping it out of `UsageModelTest.qml` keeps `UsageThreshold.js` independently loadable per D1 and keeps the auto-discovered harness set (`scripts/run-qml-tests.sh:157`, glob-based — no runner edit needed for either new file) one-file-per-library |
| D15 | **`tests/UsageWindowThresholdHarness.qml`** is an 8-fixture matrix: `usedPercent` ∈ {50, 75, 95, null} × `summary` ∈ {true, false}, each a real `UsageUi.UsageWindowRow`, asserted from a 100 ms `Timer` like `SummaryBarNormalizeHarness`. Per fixture it locates the dot by recursive `objectName === "thresholdDot"` search **scoped to `row.progressBar`** (D8) and asserts: existence, effective visibility, `Qt.colorEqual` against `Kirigami.Theme.neutralTextColor` / `negativeTextColor`, `width === height`, `radius === width / 2`, `width === row.barHeight`, vertical centering within the track, and the no-overhang invariant (dot right edge `<= track.width + 0.01`). A cross-mode assert compares the 75 summary/detail pair and the 95 pair for identical visibility and color (the spec's non-divergence scenario), and a fill-independence assert checks `Qt.colorEqual(fill.color, row.barFillColor)` at 50 and at 95 | Asserting only in summary mode; asserting exact x pixel values; reusing `ProviderRowHarness` | Geometry needs a layout pass, hence the `Timer` — the same 100 ms convention this repo already uses. Both modes must be asserted or D5's whole justification is untested. Comparing *relationships* (right edge within track, diameter equals `barHeight`) rather than hardcoded pixels keeps the harness stable across `Kirigami.Units` scaling, which varies with the test font/DPI. `usedPercent: null` is the spec's non-finite scenario; `50` is the ok scenario that must render the tree but no visible dot |
| D16 | **Visual goldens get a critical window.** `tests/visual/VisualCaptureHarness.qml:216-217` currently renders only `usedPercent: 42` and `13` — both `ok`, so the marker would be **invisible in every golden** and the regeneration the proposal budgets would be a no-op. Add a third window `{ label: "Monthly", usedPercent: 94 }` to that fixture, then regenerate all four goldens once | Leaving the fixture alone and asserting the goldens stay byte-identical; adding a fifth Breeze scenario dedicated to thresholds | A golden that cannot fail on the feature is not coverage for it. Keeping the existing `42`/`13` rows in the same image additionally proves the `ok` case renders no dot, so one fixture line buys both directions. A dedicated scenario would double Docker golden runtime for one dot. **Scope note:** this adds `tests/visual/VisualCaptureHarness.qml` to the proposal's Affected Areas table (which listed only `tests/visual/goldens/*.png`) — a test-fixture refinement within the proposal's stated "regenerated once" budget, not a behavior change |
| D17 | **`ProviderSelector.qml` exclusion is asserted, not merely observed.** The file gains no `UsageThreshold.js` import and no property; `tests/ProviderSelectorHarness.qml` gains one assert on the existing accent-underline fixture group (`:189-191`, which already carries an `80` = warn provider) plus a `95` critical provider: no descendant of the tab strip has `objectName === "thresholdDot"`, and the underline color still equals the provider accent | Relying on the absence of an import; a Python grep test over `ProviderSelector.qml` | The spec makes the exclusion a *requirement*, and requirements that are only true by omission regress the moment someone copies the dot block into the tab delegate. A behavioral tree assert catches that; a grep for an import string would not (an inline `>= 70` would slip past it) |
| D18 | **Three work units, in this order**: (1) harness split (D13) alone, (2) `UsageThreshold.js` + `UsageWindowRow.qml` marker + a11y + both new harnesses + D17 + D12 re-pin, (3) visual fixture + golden regeneration (D16) + `docs/ui-parity-checklist.md`. Each is independently revertible | One unit; goldens folded into unit 2; splitting the JS library from the QML consumer | Unit 1 is a pure test-file move whose correctness is "assert count conserved, both files green" — mixing it into a behavior change would make the move unreviewable, which is precisely the proposal's flagged risk. Goldens last is this repo's standing convention and keeps binary churn out of the reviewable diff. Splitting D1 from its consumer would leave unit 2a with a library nothing calls, and strict TDD already forces the JS harness RED before the QML edit within one unit |

## Revision 1: Icon-based risk marker (post-live-smoke)

Live Breeze Dark `plasmawindowed` smoke (task 3.5) found the circular dot from D6-D9 present but "casi imperceptible" at its 4-6px Overview diameter, and aesthetically unconvincing even at the 8-9px detail size — confirming D6's own flagged open question. The user chose a native Kirigami symbolic icon over a bigger dot, an outlined ring, or a rectangular flag (all offered as alternatives): it solves legibility (a fixed, HIG-sized icon rather than a size tied to a 4-9px bar) and idiom (the `plasma-kirigami-ui` skill's icon rule already requires "existing themed/vector icon; never an emoji or web icon package" — the old dot was closer to the rejected generic-blob end of that spectrum than to a themed icon).

| # | Decision | Alternatives rejected | Rationale |
|---|----------|-----------------------|-----------|
| D19 | **The Component's child swaps from a `Rectangle` dot to a `Kirigami.Icon`.** The D5 frame-`Item` + two-`Loader` shape is unchanged — only what the frame contains changes. `objectName` moves from the `Rectangle` to the `Kirigami.Icon` and is renamed `thresholdMarker` (D22) | Keeping the `Rectangle` and layering an `Icon` on top; a `Loader`-less inline `Kirigami.Icon` per bar block (reintroduces the duplication D5 exists to prevent) | A bare `Rectangle` has no way to carry iconography; replacing rather than layering keeps one child, one geometry, one color binding, matching D5's original "cannot drift" intent |
| D20 | **Icon sizing and position.** `width: height: Kirigami.Units.iconSizes.small` (16px), fixed regardless of `root.summary`/`root.barHeight` — legibility, not bar-proportional scale, is the goal now that D6's congruent-end-cap idea is retired. `anchors.verticalCenter: dotFrame.verticalCenter` unchanged from D6. Horizontal position straddles the fill/track boundary rather than being inscribed inside the fill: `x: Math.max(0, Math.min(dotFrame.width - iconSize, Math.round(dotFrame.width * root.barRatio) - iconSize / 2))` | Keeping `diameter == barHeight` and just raising the floor (e.g. `Math.max(barHeight, 16)`) while still inscribing inside the fill; anchoring the icon fully inside the filled region (old D7 formula unmodified) | A 16px icon cannot be "inscribed" in a 4-6px bar the way a same-radius dot could — the whole point of D6's congruence is gone once the marker is visibly larger than the bar. Straddling the boundary (half over fill, half over empty track) reads as a flag pinned at the current position, which is what the user's chosen preview showed. The `- iconSize` and `- iconSize / 2` clamps keep the icon fully inside `dotFrame` at both 0% (left) and 100% (right) fill, and the summary track's asserted `>= 48px` width (`tests/SummaryBarNormalizeHarness.qml:66`) comfortably fits a 16px icon at any `barRatio` |
| D21 | **Icon source and color.** `source: root.thresholdLevel === UsageThreshold.LEVEL_CRITICAL ? "emblem-important-symbolic" : "emblem-warning-symbolic"`; `color:` bound exactly as D9 (`negativeTextColor` / `neutralTextColor` / `"transparent"` fallback), which recolors the symbolic SVG per Kirigami's monochrome-icon convention. `visible` binding unchanged from D9 (`UsageThreshold.isRisk(root.thresholdLevel)`) | A single icon name recolored only; distinct icon *shapes* beyond warning/important (e.g. a third icon for a future level) | Two standard Breeze/freedesktop-naming-spec icon names, gated by the same `isRisk` visibility as before, keep the existing color-only-discriminates-warn-from-critical stance (still true — same icon-naming pattern with color is the marker, not a shape system) while giving each level a slightly different glyph (warning triangle vs. exclamation), which is a legibility bonus color alone didn't have |
| D22 | **Rename ripple.** `objectName` changes from `"thresholdDot"` to `"thresholdMarker"` everywhere it's referenced: `tests/UsageWindowThresholdHarness.qml`'s lookup and `tests/ProviderSelectorHarness.qml`'s exclusion assert. `UsageWindowThresholdHarness.qml`'s geometry assertions change from `width===height===barHeight`/`radius===width/2` to `width===height===Kirigami.Units.iconSizes.small`, plus a new assertion on `.source` containing `"warning"` for `warn` and `"important"` for `critical`. Visual goldens (D16) are regenerated a second time since the rendered marker changed shape | Keeping the `"thresholdDot"` name for a smaller diff | A `Kirigami.Icon` named `thresholdDot` misleads the next reader; the rename cost is mechanical (a handful of string literals) and paid once |

## Revision 2: Row-sibling placement, reserved slot (post-second-live-smoke)

Live smoke of Revision 1's icon confirmed the glyph itself reads fine (the warn triangle was legible and liked), but overlaying it on the bar — straddling the fill's right edge per D20 — read as "stuck on top of the bar" and didn't work visually. The user asked for the marker fully off the bar, adjacent to the percent text instead, **and** for bar track length to stay identical across all rows regardless of whether a given row shows a marker — continuing this file's established fixed-column convention (`:59-67` comment; `tests/SummaryBarNormalizeHarness.qml`'s width-equality asserts).

| # | Decision | Alternatives rejected | Rationale |
|---|----------|-----------------------|-----------|
| D23 | **Marker moves from bar-overlay to row-sibling**, positioned after the bar and immediately before the percent value, in both modes. The D19-D21 frame-`Item` + `Loader.anchors.fill` + right-edge clamp math (D20's `x` formula) is removed entirely — a plain `RowLayout` child needs no manual position math | Keeping the overlay and just moving it to the left/other edge of the fill; centering it below the bar | The user's feedback was specifically about *placement* (on-bar vs. off-bar), not the icon or its color — D21's icon/color mapping is unchanged. A row-sibling is simpler code (no clamp formula) as a direct consequence, not the goal itself |
| D24 | **The marker's layout slot is always reserved at a fixed `Kirigami.Units.iconSizes.small` width, regardless of threshold level.** The `Loader` is always `active` (no `active`/`visible` gating); only the loaded `Kirigami.Icon`'s **`opacity`** toggles between `0` (`ok`/no-level) and `1` (`warn`/`critical`) via `UsageThreshold.isRisk(root.thresholdLevel)`. `visible` is deliberately left untouched (default `true`) | Gating the `Loader` with `active: isRisk` (Revision 2's first draft) so it collapses to zero width when not at risk; gating with `visible: isRisk` | `Layout.fillWidth` items (the bar) claim whatever space siblings don't reserve — a slot that shrinks to zero when `ok` and expands to `iconSizes.small` when `warn`/`critical` would make the *bar itself* shorter on every row that shows a marker, which is exactly the width-equality invariant this file already tests for and the user just re-affirmed. `visible: false` in Qt Quick Layouts removes an item from layout participation entirely (0 size) — the opposite of "reserve the space"; only `opacity` hides pixels without touching layout size |
| D25 | **New exported handle**: `property var thresholdMarker: root.summary ? summaryThresholdMarkerLoader.item : detailThresholdMarkerLoader.item`, declared beside the existing `progressBar`/`percentageLabel` mode-switch properties (`:39,41`). Since the `Loader` is always active (D24), this is never `null` — tests assert presence via `.opacity === 1` and `.source`/`.color`, not null-checking | Keeping the old `objectName`-recursive-search-through-`progressBar` pattern from D8 | D8's scoping-through-`progressBar` assumed the marker was a descendant of the bar `Item`; it no longer is (D23), so that scoping path is gone. A direct handle is simpler than search and matches this file's own established pattern for exactly this summary/detail dichotomy |
| D26 | **Insertion points.** Summary: inside `titleRow`, after the detail-only spacer `Item`, immediately before `summaryPercentageLabel`. Detail: inside the band `RowLayout`, as the **first** child, immediately before `bandPercentageLabel`. `objectName:"thresholdMarker"` is retained on the `Kirigami.Icon` (unused by `UsageWindowThresholdHarness.qml` now that D25's handle exists, but still needed by `tests/ProviderSelectorHarness.qml`'s unrelated tab-strip exclusion search, which does a generic recursive scan) | Appending after the percent label instead of before it; a dedicated marker row | "Before the percent text" is literally the placement the user's chosen preview showed (`████ ⚠ 100% used`). Detail mirrors the same "immediately before the percent number" rule for consistency between modes, even though detail's bar and percent aren't on the same visual row |

D20 is further superseded here: its sizing half (`Kirigami.Units.iconSizes.small`) is still correct and reused as `Layout.preferredWidth`/`Layout.preferredHeight` (D24), but its positioning half (the right-edge straddle `x` formula) no longer applies — position is now RowLayout order, not manual math.

## Revision 3: Custom bundled glyphs, detail-mode placement flip (post-third-live-smoke)

Third live smoke: the row-sibling placement (Revision 2) read correctly in Overview, just needed the marker visually centered in its reserved slot. In detail mode, the placement itself needed to flip — before-percent (matching Overview) read wrong there; after-percent was requested instead, giving Overview and detail **intentionally different** marker-to-percent ordering. Separately, the user asked whether the marker was locked to Plasma's own icon set; per `plasma-kirigami-ui`'s existing rule ("existing themed/vector icon; never an emoji or web icon package"), a **bundled** custom vector icon is exactly as valid as a system-theme one — emoji are the only thing ruled out. Three rounds of icon shape/color mockups were rendered and shown to the user (`AGENTS`-side, not part of this repo) before picking: a filled warning-triangle and a filled critical-circle, each with an exclamation cut out via an SVG `<mask>` (the same "compound silhouette" technique, just hand-authored instead of a theme lookup).

| # | Decision | Alternatives rejected | Rationale |
|---|----------|-----------------------|-----------|
| D27 | **Detail-mode marker moves from before `bandPercentageLabel` to immediately after it** (`bandPercentageLabel`, marker, spacer, `resetsAtLabel`, `resetDescriptionLabel`). Summary mode is **unchanged**: marker stays before `summaryPercentageLabel`, per the second live smoke's explicit approval ("me parecen correctos"). The two modes are now intentionally asymmetric in marker-to-percent order — D26's "mirrors the same rule for consistency between modes" no longer holds and is superseded here | Flipping both modes to after-percent for symmetry; a per-mode QML property instead of literally two different insertion points | The user approved Overview's before-percent order explicitly and separately asked only detail to flip — matching that instruction exactly, not re-imposing a symmetry the user didn't ask for, is the correct read of the feedback |
| D28 | **[CORRECTED during apply — see note below.]** Centering relies on `Kirigami.Icon`'s own default behavior, not an explicit alignment property. This repo's installed Kirigami (6.28.0)'s `Icon` type has no `horizontalAlignment`/`verticalAlignment` properties at all (its full property list is `source, fallback, placeholder, active, valid, selected, isMask, color, status, paintedWidth, paintedHeight, animated, roundToIconSize`) — binding either fails QML compilation. `Icon` centers its painted content within its bounding box internally by default, matching every other `Kirigami.Icon` instance already in this codebase (`ProviderRow.qml`, `ProviderSelector.qml`, `CompactUsageButton.qml`), none of which set alignment either | Adjusting `RowLayout` spacing values instead | `RowLayout`'s `spacing` is already symmetric between siblings, so the "not centered" complaint (against Revision 2's Breeze `emblem-*-symbolic` icons) most likely came from those specific glyphs' own internal padding, not layout math — switching to the new bundled SVGs (D29), which are drawn symmetric within their viewBox, is expected to resolve it without any extra property. Re-check in the next live smoke (3.5d) since D28 as originally written wasn't literally implementable |
| D29 | **Replace icon-theme-name lookup with two bundled mask SVGs**: `contents/icons/threshold-warning.svg` (filled rounded triangle, exclamation cut via `<mask>`) and `contents/icons/threshold-critical.svg` (filled circle, same cutout technique), loaded via `source: Qt.resolvedUrl("../icons/threshold-warning.svg")` / `"../icons/threshold-critical.svg"` with `isMask: true` — this repo's exact existing convention for bundled monochrome icons (`ProviderRow.qml:56`, `ProviderSelector.qml:123`, `CompactUsageButton.qml:28-30` all follow this same `Qt.resolvedUrl(...) + isMask:true` pattern for provider glyphs). `color:` binding is unchanged from D21 — `isMask` icons recolor from the same property regardless of source | Keeping the freedesktop theme names and accepting the offscreen-harness blindness; a raster PNG asset instead of SVG; a third-party icon pack | The user explicitly asked whether custom SVGs were an option; bundled SVGs are a stronger fit than theme names even independent of that ask, because **the offscreen visual-regression harness can now actually render the marker** — Phase 5/7's `QIcon::fromTheme()` blindness (no platform-theme plugin under `QT_QPA_PLATFORM=offscreen`) does not apply to a bundled resource loaded by URL, since Qt's normal image-provider pipeline handles it without touching the system icon theme at all. This closes the "golden regen proves nothing about the glyph" gap flagged twice already, as a side effect of an aesthetic decision, not a targeted fix |
| D30 | **Shape stays two-icon (triangle=warn, circle=critical), not shape-plus-weight or a diamond/octagon pair.** Three mockup sets were shown (triangle+circle-with-cutout; diamond+octagon-with-cutout; outline-triangle+solid-circle-without-cutout); the user picked the first, unchanged from the shape already implied by D21's warning/important semantics | Diamond+octagon (road-sign metaphor); ring+solid-fill (no exclamation, pure geometry) | User's explicit choice; recorded here so a future reviewer doesn't wonder why two other fully-worked mockup sets exist only in chat history and not in this document |

## Data Flow

    UsageModel.normalize ──→ windowData.usedPercent (finite number | null)
         │
         └─→ UsageWindowRow (root)
                ├─ hasFinitePercent ──→ showBar ──→ bar visibility        (unchanged)
                ├─ barRatio ──────────→ fill.width = round(track * ratio) (unchanged)
                ├─ barFillColor ──────→ fill.color = accent | highlight   (unchanged, D9)
                └─ thresholdLevel = UsageThreshold.level(usedPercent)     (new, D4)
                        ├─→ dot.visible = isRisk(level)                   (D9)
                        ├─→ dot.color   = negative | neutral              (D9)
                        └─→ Accessible.description += risk phrase         (D10)

    UsageWindowRow marker (one Component, two Loaders — D5/D23, icon per D21):

      summary: true (titleRow)                    summary: false (band RowLayout)
      ┌────────────────────────────────┐          ┌──────────────────────────┐
      │ label  track ██████████░░  ⚠  91% used │   │ ⚠  100% used   ...reset  │
      └────────────────────────────────┘          └──────────────────────────┘
        marker slot = Kirigami.Units.iconSizes.small, ALWAYS reserved (D24)
        icon opacity = isRisk(level) ? 1 : 0   ← space stays constant either way

    ProviderSelector.qml tab underline ──→ accent only, no dot (D17)

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `contents/code/UsageThreshold.js` | Create | `.pragma library`; `WARN_AT`, `CRITICAL_AT`, `LEVEL_*`, `level()`, `isRisk()`, private `finiteNumber()` (D1-D2) |
| `contents/icons/threshold-warning.svg` | Create | Bundled mask icon, warn level (D29) |
| `contents/icons/threshold-critical.svg` | Create | Bundled mask icon, critical level (D29) |
| `contents/ui/UsageWindowRow.qml` | Modify | `import "../code/UsageThreshold.js" as UsageThreshold`; `thresholdLevel` root property (D4); one `Component` (D5-D7, D9); one `Loader` as the last child of `summaryBar` and of `detailBar` (D11); risk push in `Accessible.description` (D10). All existing properties, exported handles (`progressBar`, `windowLabel`, `percentageLabel`, `resetsAtLabel`, `resetDescriptionLabel`) and `objectName`s preserved |
| `scripts/check-qml-unqualified-baseline.py` | Modify | Re-pin `LAYOUT_POSITIONING_EXCEPTIONS` to the post-edit line (D12) |
| `tests/UsageThresholdHarness.qml` | Create | Pure-JS boundary table (D14) |
| `tests/UsageWindowThresholdHarness.qml` | Create | 8-fixture render matrix (D15) |
| `tests/SummaryBarNormalizeHarness.qml` | Modify | Receives 2 fixtures + 4 asserts + the Kirigami import (D13) |
| `tests/ProviderRowHarness.qml` | Modify | Loses exactly those 2 fixtures and 4 asserts, nothing else (D13) |
| `tests/ProviderSelectorHarness.qml` | Modify | Tab-strip exclusion assert + a critical fixture (D17) |
| `tests/visual/VisualCaptureHarness.qml` | Modify | Third window at `usedPercent: 94` (D16) |
| `tests/visual/goldens/*.png` | Modify | Regenerated once, final unit (D16, D18) |
| `docs/ui-parity-checklist.md` | Modify | Verification record |

Not touched: `UsageModel.js`, `UsageController.qml`, `CostController.qml`, `ProviderRow.qml`,
`ProviderHeader.qml`, `ProviderSelector.qml`, `main.qml`, `config/`, `scripts/run-qml-tests.sh`
(harness discovery is glob-based, `:157`).

## Interfaces / Contracts

```js
// contents/code/UsageThreshold.js  -- .pragma library
var WARN_AT = 70            // inclusive lower bound of "warn"
var CRITICAL_AT = 90        // inclusive lower bound of "critical"
var LEVEL_NONE = ""         // non-finite or absent usedPercent
var LEVEL_OK = "ok"
var LEVEL_WARN = "warn"
var LEVEL_CRITICAL = "critical"

function level(usedPercent)   // any -> "" | "ok" | "warn" | "critical"   (D2)
function isRisk(levelValue)   // string -> bool: warn or critical         (D1)
```

```qml
// contents/ui/UsageWindowRow.qml -- one added root property, no handle changes
readonly property string thresholdLevel: UsageThreshold.level(root.windowData.usedPercent)
```

```qml
// the shared marker (D5/D23-D26, D21, D27-D29) -- declared once, instantiated
// twice, as a row sibling next to the percent label, never overlaid on the bar.
Component {
    id: thresholdMarkerComponent
    Kirigami.Icon {
        objectName: "thresholdMarker"
        implicitWidth: Kirigami.Units.iconSizes.small
        implicitHeight: Kirigami.Units.iconSizes.small
        isMask: true
        // no horizontalAlignment/verticalAlignment -- Kirigami.Icon 6.28
        // has neither property; it centers its painted content by default
        // (D28 correction; matches every other Kirigami.Icon in this repo)
        opacity: UsageThreshold.isRisk(root.thresholdLevel) ? 1 : 0
        source: root.thresholdLevel === UsageThreshold.LEVEL_CRITICAL
            ? Qt.resolvedUrl("../icons/threshold-critical.svg")
            : Qt.resolvedUrl("../icons/threshold-warning.svg")
        color: root.thresholdLevel === UsageThreshold.LEVEL_CRITICAL
            ? Kirigami.Theme.negativeTextColor
            : root.thresholdLevel === UsageThreshold.LEVEL_WARN
                ? Kirigami.Theme.neutralTextColor
                : "transparent"
    }
}

// exported handle (D25), beside the existing progressBar/percentageLabel pattern:
property var thresholdMarker: root.summary ? summaryThresholdMarkerLoader.item : detailThresholdMarkerLoader.item

// in titleRow (:151-181), after the detail-only spacer, before summaryPercentageLabel
// -- UNCHANGED position from Revision 2 (D26), user approved this order (D27):
Loader {
    id: summaryThresholdMarkerLoader
    sourceComponent: thresholdMarkerComponent
    Layout.preferredWidth: Kirigami.Units.iconSizes.small
    Layout.preferredHeight: Kirigami.Units.iconSizes.small
    Layout.alignment: Qt.AlignVCenter
}

// in the detail band RowLayout, AFTER bandPercentageLabel (flipped by D27,
// was FIRST child / before bandPercentageLabel in Revision 2):
Loader {
    id: detailThresholdMarkerLoader
    sourceComponent: thresholdMarkerComponent
    Layout.preferredWidth: Kirigami.Units.iconSizes.small
    Layout.preferredHeight: Kirigami.Units.iconSizes.small
    Layout.alignment: Qt.AlignVCenter
}
```

`pragma ComponentBehavior: Bound` is already set on this file (`:1`); referencing `root`
from inside the inline `Component` is exactly what `Bound` makes safe, and every access
above is id-qualified, so no new `unqualified` qmllint diagnostic is introduced.

## Testing Strategy

| Layer | RED anchor (must fail first) | Approach |
|-------|------------------------------|----------|
| Unit (JS) | `tests/UsageThresholdHarness.qml` does not exist; the first version fails to load because `contents/code/UsageThreshold.js` does not exist. Boundary table: `WARN_AT === 70`, `CRITICAL_AT === 90`, then `level()` over `null`, `undefined`, `"80"`, `NaN`, `Infinity`, `-Infinity`, `{}` → `""`; `0`, `69`, `69.9`, `-5` → `"ok"`; `70`, `70.0`, `89.9` → `"warn"`; `90`, `100`, `120` → `"critical"`; `isRisk` true only for warn/critical (D2, D14) | `./scripts/run-qml-tests.sh` |
| Unit (QML) | `tests/UsageWindowThresholdHarness.qml`'s `row.thresholdMarker.opacity` is `0` (not `1`) for the 75 and 95 fixtures before the `UsageWindowRow.qml` edit — opacity is the first RED, then icon `.source` per level, then color, then the fixed-width reserved-slot assertion (D24, the spec's "bar track length is threshold-independent" scenario), then the cross-mode identity pair via direct `row.thresholdMarker` handle comparison (D15, D25-D26) | `./scripts/run-qml-tests.sh` |
| Unit (QML) | Fill independence: `Qt.colorEqual(fill.color, row.barFillColor)` at `usedPercent` 50 **and** 95, in both modes — green before and after, and it is the standing lock on D9 (the spec's "fill color is threshold-independent" scenario) | `./scripts/run-qml-tests.sh` |
| Unit (QML) | a11y: on a 95 fixture `row.Accessible.description` must contain `"Critical usage"` **after** the `"% used"` entry (`indexOf` ordering assert, not mere containment); on 75, `"Elevated usage"`; on 50 and on `null`, neither string appears and the description is byte-identical to today's (D10) | `./scripts/run-qml-tests.sh` |
| Unit (QML) | Exclusion: `tests/ProviderSelectorHarness.qml` finds no `"thresholdDot"` anywhere under the tab strip for warn (80) and critical (95) providers, and the underline color still equals the accent (D17). RED by construction only if someone adds the dot there — this is a standing regression lock, added in the same unit and expected green | `./scripts/run-qml-tests.sh` |
| Unit (QML) | Harness split (D13): RED-first means **moving the asserts before touching anything else** and confirming both files still run. Conservation check is mechanical — `ProviderRowHarness.qml` loses 4 `assert(` calls and 2 fixtures; `SummaryBarNormalizeHarness.qml` gains 4 `root.assert(` calls and 2 fixtures; total repo assert count unchanged. Deliberately verify the moved elide asserts still reference `width: 260` rows, not the 320 ones | `./scripts/run-qml-tests.sh` |
| Static (lint) | Run `./scripts/lint-qml.sh` **before** editing `UsageWindowRow.qml` to capture the currently reported `Quick.layout-positioning` line, and again after, re-pinning `LAYOUT_POSITIONING_EXCEPTIONS`. The gate must end green with exactly one accepted exception (D12) | `./scripts/lint-qml.sh` |
| Static (Python) | `python3 tests/test_run_qml_tests_discovery.py` must stay green with the two new harnesses (glob discovery, `>= 15` plain harnesses, alphabetical) | `python3 tests/test_run_qml_tests_discovery.py` |
| Visual | Four `breeze-{light,dark}-cost-{present,absent}` scenarios after the D16 fixture change: regenerate with `UPDATE_GOLDENS=1`, then re-run without it to prove convergence. The new 94% row must show a dot; the 42/13 rows must not | `docker build -f ci/visual-regression.Dockerfile -t kodexbar-visual-local:test .` then `./scripts/run-visual-tests.sh` in the container |
| Manual (gating) | Breeze Light **and** Dark `plasmawindowed` smoke: (a) the dot is legible against both accent fills and both track backgrounds, (b) the summary dot at its 4-6px diameter is actually noticeable at popup scale, (c) Overview summary and selected-provider detail agree for the same provider/window, (d) tabs unchanged | `docs/live-plasma-smoke.md`, recorded in `docs/ui-parity-checklist.md` |

## Threat Matrix

N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification,
or process-integration boundary. `UsageThreshold.level` is a total pure function over an
already-normalized primitive with no I/O, no allocation of external resources, and no
string interpolation into a command; every other change is view-layer paint or a test
file. The one non-QML file touched (`scripts/check-qml-unqualified-baseline.py`) has its
exception set **narrowed to a new exact line**, never widened.

## Migration / Rollout

No migration. No user-visible setting, no stored state, no CLI change. Three stacked,
independently revertible units (D18):

| Unit | Content | Revert effect |
|------|---------|---------------|
| 1 | Harness split (D13) | `ProviderRowHarness.qml` restored intact |
| 2 | `UsageThreshold.js`, marker, a11y, 2 new harnesses, D17 lock, D12 re-pin | Bars return to accent-only fill; no other surface affected |
| 3 | Visual fixture + goldens + checklist (D16) | Goldens restore from the prior commit |

Unit 2 is the only one that changes runtime behavior and stays well inside the 400-line
budget (~40 production lines across two files; the rest is test code).

## Open Questions

- [ ] **D12 line pin is unverified here and must be checked first.** The checked-in
  exception is line `89` while `titleRow`'s sanctioned `width: root.width` reads at line
  `121` of the current `contents/ui/UsageWindowRow.qml` — a 32-line delta consistent with
  the block commit `0692c43` added above it. This phase had no shell, so I did **not**
  prove whether `./scripts/lint-qml.sh` is currently red on the branch tip or whether
  qmllint reports a line I did not anticipate. Unit 2's first action is to run the lint
  gate unmodified and record the real number; if it is already red, that is a pre-existing
  defect fixed incidentally by the same re-pin, and it should be called out in the commit
  message rather than hidden inside this change.
- [x] **Summary dot size may be too subtle.** RESOLVED by Revision 1: the live Breeze
  smoke confirmed the 4-6px inscribed dot was near-imperceptible and aesthetically
  unconvincing. Superseded by D19-D22's fixed 16px `Kirigami.Icon` marker, sized
  independently of `barHeight`.
- [x] **Color-blind redundancy.** IMPROVED by Revision 1: `emblem-warning-symbolic`
  (triangle) and `emblem-important-symbolic` (exclamation) are visually distinct
  glyphs, not just distinct hues, so warn/critical no longer rely on color alone — a
  bonus of the icon switch, not something separately designed for.
