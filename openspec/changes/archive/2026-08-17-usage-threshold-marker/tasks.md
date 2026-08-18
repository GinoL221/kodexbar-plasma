# Tasks: Usage Threshold Marker

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | ~100 (U1) / ~300 (U2) / small, goldens excluded (U3) |
| 400-line budget risk | Medium (U2 highest) |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 → PR 2 → PR 3 |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: Medium

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Harness split (D13) | PR 1 → main | `run-qml-tests.sh` | `ProviderRowHarness.qml`, `SummaryBarNormalizeHarness.qml` | Both harness files only |
| 2 | Threshold marker (D1-D12, D17) | PR 2 → main after PR 1 | `run-qml-tests.sh` | `UsageThresholdHarness.qml`, `UsageWindowThresholdHarness.qml`, `ProviderSelectorHarness.qml` | JS lib, dot block, 2 harnesses, lint pin |
| 3 | Visual + docs (D16) | PR 3 → main after PR 2 | `run-visual-tests.sh` | Docker + Breeze Light/Dark smoke | Goldens + checklist only |

## Phase 1: Harness Split (PR 1)

- [x] 1.1 Baseline: run `./scripts/run-qml-tests.sh`, confirm both harnesses currently green.
- [x] 1.2 Move `weeklySummaryWindowRow`/`monthlySummaryWindowRow` fixtures + 2 D20 elide asserts verbatim (width:260) from `ProviderRowHarness.qml:460-485,732-741` into `SummaryBarNormalizeHarness.qml`; add `import org.kde.kirigami as Kirigami` (D13).
- [x] 1.3 Retarget the 2 column-floor asserts (`:720-730`) onto existing `normSession1`; delete originals from `ProviderRowHarness.qml`.
- [x] 1.4 Verify conservation: 4 asserts + 2 fixtures moved, none lost; both files green; `summaryWindowRow` and its asserts (`:718,742-744,748-757`) untouched.

## Phase 2: Threshold Marker (PR 2)

- [x] 2.1 Run `./scripts/lint-qml.sh` unmodified; record the real `Quick.layout-positioning` line (pin says 89, binding now ~121); flag if already red — pre-existing (D12).
- [x] 2.2 RED: create `tests/UsageThresholdHarness.qml` (mirrors `RelativeTimeHarness.qml`) asserting `WARN_AT===70`, `CRITICAL_AT===90`, full D2 boundary table; confirm failure.
- [x] 2.3 GREEN: create `contents/code/UsageThreshold.js` (`.pragma library`) — `WARN_AT`, `CRITICAL_AT`, `LEVEL_*`, `level()`, `isRisk()`, private `finiteNumber()` (D1-D2).
- [x] 2.4 Verify `UsageThresholdHarness.qml` passes.
- [x] 2.5 RED: create `tests/UsageWindowThresholdHarness.qml` — 8-fixture matrix (`usedPercent` ∈ {50,75,95,null} × `summary` ∈ {true,false}); assert dot existence/visibility/color/geometry/no-overhang via `row.progressBar`, cross-mode identity, fill-independence, a11y ordering (D9, D10, D15); confirm failure.
- [x] 2.6 GREEN: add `UsageThreshold.js` import + `thresholdLevel` property to `UsageWindowRow.qml` beside `hasFinitePercent`/`barRatio` (D4).
- [x] 2.7 GREEN: add shared `thresholdDotComponent` (frame `Item` + `Rectangle objectName:"thresholdDot"`, diameter=`barHeight`, right-edge clamp, color/visible bindings) at root level (D5-D9).
- [x] 2.8 GREEN: add `Loader{sourceComponent:thresholdDotComponent}` as last child of `summaryBar` (`:151-181`) and `detailBar` (`:228-252`) (D11).
- [x] 2.9 GREEN: nest `"Critical usage"`/`"Elevated usage"` push inside the `hasFinitePercent` block (`:91-94`), after the percent entry (D10).
- [x] 2.10 Verify `UsageWindowThresholdHarness.qml` passes fully.
- [x] 2.11 Add a `95` critical fixture + exclusion assert (no `"thresholdDot"` under tab strip, underline stays accent) to `ProviderSelectorHarness.qml`; confirm green, `ProviderSelector.qml` untouched (D17).
- [x] 2.12 Re-pin `LAYOUT_POSITIONING_EXCEPTIONS` in `scripts/check-qml-unqualified-baseline.py` to the post-edit line; `./scripts/lint-qml.sh` green, one exception (D12).
- [x] 2.13 Verify `python3 tests/test_run_qml_tests_discovery.py` stays green with the 2 new harnesses.
- [x] 2.14 Run full `./scripts/run-qml-tests.sh`; confirm Unit 1 + Unit 2 all green.

## Phase 3: Visual + Docs (PR 3)

- [x] 3.1 Add a third window `{label:"Monthly", usedPercent:94}` to `VisualCaptureHarness.qml:216-217`, keeping existing 42/13 rows (D16).
- [x] 3.2 Build `docker build -f ci/visual-regression.Dockerfile -t kodexbar-visual-local:test .`.
- [x] 3.3 Run with `UPDATE_GOLDENS=1`; regenerate all 4 `breeze-{light,dark}-cost-{present,absent}` goldens; confirm 94% row shows a dot, 42/13 rows don't.
- [x] 3.4 Re-run without `UPDATE_GOLDENS` to prove convergence (0 mismatched pixels).
- [x] 3.5 Manual gate: Breeze Light + Dark `plasmawindowed` smoke — **done, dot found present but "casi imperceptible" and unconvincing aesthetically → triggered Phase 4 (Revision 1). Re-smoke required after Phase 4/5, see 3.5b below.**
- [x] 3.6 Update `docs/ui-parity-checklist.md` with the verification record.

## Phase 4: Icon Marker Revision (PR 2 amendment, D19-D22)

Live smoke (3.5) found the circular dot near-imperceptible in Overview and aesthetically unconvincing. User chose a native Kirigami symbolic icon over 3 other offered alternatives (bigger dot, rectangular flag, outlined ring). `openspec/changes/usage-threshold-marker/design.md` Revision 1 (D19-D22) and `specs/provider-usage-display/spec.md` already updated to match — this phase re-implements Phase 2's marker component only; classification logic (`UsageThreshold.js`), a11y phrasing (D10), harness split (Phase 1), and lint re-pin (2.12) are untouched.

- [x] 4.1 RED: update `tests/UsageWindowThresholdHarness.qml` — rename all `"thresholdDot"` lookups to `"thresholdMarker"`; replace geometry asserts (`width===height===barHeight`, `radius===width/2`) with `width===height===Kirigami.Units.iconSizes.small`; add `.source` assertions (`"warning"` for warn fixtures, `"important"` for critical fixtures); confirm failure against current `Rectangle`-based production code.
- [x] 4.2 RED: update `tests/ProviderSelectorHarness.qml`'s exclusion assert to search for `"thresholdMarker"` instead of `"thresholdDot"`; confirm it still passes trivially (exclusion is true either way) — not a real RED, just a rename-conservation check.
- [x] 4.3 GREEN: in `contents/ui/UsageWindowRow.qml`, replace `thresholdDotComponent`'s child `Rectangle` with a `Kirigami.Icon` per D19-D21 — `objectName:"thresholdMarker"`, `width:height:Kirigami.Units.iconSizes.small`, `x` formula per D20, `source` per D21, same `color`/`visible` bindings as before.
- [x] 4.4 Verify `UsageWindowThresholdHarness.qml` and `ProviderSelectorHarness.qml` pass fully.
- [x] 4.5 Run full `./scripts/run-qml-tests.sh` and `./scripts/lint-qml.sh`; confirm both exit 0 (no new lint line drift expected — edit is same line count region, but re-check per D12's standing discipline).

## Phase 5: Golden Re-regen (PR 3 amendment)

- [ ] 5.1 (mechanical steps done, visual confirmation FAILED — **left unchecked permanently, not pending**: Revision 1's on-bar overlay marker was superseded by Revision 2/3 before a retry could run; its intended target no longer exists in production code) Re-ran `UPDATE_GOLDENS=1 ./scripts/run-visual-tests.sh` in the existing Docker image (reused `kodexbar-visual-local:test`, no rebuild needed). All 4 goldens regenerated, script exited 0. **Visual confirmation FAILED its stated criterion**: pixel-level inspection of the regenerated goldens shows the 94% Monthly row no longer has the old dot, but it also shows **no icon glyph at all** — the marker is fully absent (100% background-color pixels at the marker's expected position; isolated reproduction below). Root cause: `Kirigami.Icon.source: "emblem-important-symbolic"` is a freedesktop icon-theme name resolved via `QIcon::fromTheme()`; the harness's `QT_QPA_PLATFORM=offscreen` run has no platform-theme plugin loaded (deliberately, per `docs/visual-regression.md`'s note that `QT_QPA_PLATFORMTHEME=kde` previously broke palette classification headless), so `QIcon::themeName()` stays empty and the theme lookup silently returns nothing to draw. Confirmed by an isolated repro: the exact same `Kirigami.Icon{source:"emblem-important-symbolic"; color:"red"}` fragment renders 0 colored pixels under this harness's env vars, and renders correctly (180px of `#da4453`) only when `QT_QPA_PLATFORMTHEME=kde` is added. See risk note in apply-progress / final report — **this needs a maintainer decision, not a silent fix**, since re-adding that env var is the exact thing this harness's design deliberately avoided for palette reasons.
- [x] 5.2 Re-run without `UPDATE_GOLDENS` to prove convergence: 0/180000 mismatched pixels on all 4 `breeze-{light,dark}-cost-{present,absent}` scenarios (deterministic regardless of the 5.1 finding — the goldens are self-consistent, just visually blind to the icon glyph).
- [x] 5.3 Ownership: this run's own goldens/artifacts stayed host-owned (`docker run --user "$(id -u):$(id -g)"` per `docs/visual-regression.md`) — no chown needed. Found and removed one **stray root-owned leftover from an earlier root-run**: `tests/visual/__pycache__/*.pyc` (gitignored, harmless to git, but cleaned via a root container `rm -rf` since no passwordless sudo was available). Removed the entire gitignored `tests/visual/artifacts/` scratch tree (per-run captures/diffs; not meant to persist). Full-repo `find -user root` swept clean afterward.
- [ ] 3.5b Manual gate (re-run): Breeze Light + Dark `plasmawindowed` smoke with the icon marker — legibility, Overview/detail agreement, tabs unchanged, warn vs critical glyph distinguishable. **Requires a live Plasma desktop session and human visual judgment; cannot be performed by a sandboxed agent.** Given the 5.1 finding, this manual gate is now the **only** verification path that can confirm the icon actually renders anywhere — the automated visual suite currently provides zero signal for this glyph. **Left unchecked permanently, not pending**: Revision 1's on-bar overlay marker was superseded by Revision 2 (row-sibling placement) before this specific gate could run — its intended target no longer exists in production code. Superseded by `3.5c` (Phase 7, checked) and `3.5d` (Phase 9, checked, user-approved).
- [x] 5.4 Updated `docs/ui-parity-checklist.md` Notes to record the Revision 1 regeneration and the 5.1 icon-rendering finding honestly (not a false "verified").

## Phase 6: Row-Sibling Placement Revision (PR 2 amendment, D23-D26)

Live smoke (3.5b) confirmed the icon glyph itself works and reads fine (warn triangle legible/liked) but overlaying it on the bar read as "stuck on top of it" — user wants it fully off the bar, adjacent to the percent text, **and** wants bar track length to stay identical across all rows regardless of marker presence (existing fixed-column convention). `design.md` Revision 2 (D23-D26) and `specs/provider-usage-display/spec.md` already updated to match.

- [x] 6.1 RED: rewrite `tests/UsageWindowThresholdHarness.qml`'s lookup from recursive `objectName` search scoped through `row.progressBar` to the new `row.thresholdMarker` handle; assert `.opacity` (1 for warn/critical, 0 for ok/null — never absent, since the Loader is always active per D24) instead of `.visible`; keep `.source`/color asserts; add a NEW assertion pair proving the reserved-slot invariant: two summary fixtures with equal label/percent-text width but different levels (one `ok`, one `critical`) must have equal `row.progressBar.width` (the bar track, not the marker) — confirm this fails against current bar-overlay code (marker won't exist at `row.thresholdMarker` yet, or old geometry won't satisfy the new asserts).
- [x] 6.2 RED: update `tests/ProviderSelectorHarness.qml`'s exclusion assert if its scoping assumption changed (it does a generic recursive scan under the tab strip, independent of `UsageWindowRow`'s internal structure — likely needs no change, verify and note if truly unaffected).
- [x] 6.3 GREEN: in `contents/ui/UsageWindowRow.qml` — replace `thresholdDotComponent`'s frame-`Item`+`Kirigami.Icon`+clamp-`x` with the simplified `thresholdMarkerComponent` (bare `Kirigami.Icon`, `opacity` instead of `visible`, no `x`/frame) per D23-D24's exact contract in `design.md`'s Interfaces/Contracts block.
- [x] 6.4 GREEN: remove the two `Loader{anchors.fill:parent; sourceComponent:thresholdDotComponent}` instances from inside `summaryBar` and `detailBar`'s `Item`s (bar Items go back to just track+fill Rectangles).
- [x] 6.5 GREEN: add `summaryThresholdMarkerLoader` to `titleRow`, after the detail-only spacer `Item`, before `summaryPercentageLabel`; add `detailThresholdMarkerLoader` as the FIRST child of the detail band `RowLayout`, before `bandPercentageLabel`; both with fixed `Layout.preferredWidth/Height: Kirigami.Units.iconSizes.small` (D26).
- [x] 6.6 GREEN: add `property var thresholdMarker: root.summary ? summaryThresholdMarkerLoader.item : detailThresholdMarkerLoader.item` beside the existing `progressBar`/`percentageLabel` handles (D25).
- [x] 6.7 Verify `UsageWindowThresholdHarness.qml` and `ProviderSelectorHarness.qml` pass fully, including the new reserved-slot width-equality assertion.
- [x] 6.8 Run full `./scripts/run-qml-tests.sh` and `./scripts/lint-qml.sh`; re-check the D12 exception line (layout edits shift line numbers again) and re-pin `scripts/check-qml-unqualified-baseline.py` if needed; confirm both exit 0.

## Phase 7: Golden Re-regen (PR 3 amendment, round 2)

- [x] 7.1 Re-run `UPDATE_GOLDENS=1 ./scripts/run-visual-tests.sh`; visually confirm the marker now renders beside the percent text (not on the bar) — note Phase 5's finding that icon-theme glyphs may render blank under this offscreen harness regardless of position; if still blank, that's the same pre-existing harness limitation, not a new regression, and doesn't block this task. **Result: same pre-existing limitation confirmed (glyph still blank), NOT a new regression.** Structural placement change confirmed via pixel-level run-length scan: all 3 bar tracks (Session/Weekly/Monthly, including the 94% critical row) span the identical `x≈0-445` pixel range in the regenerated golden, proving the reserved-slot invariant (bar length unaffected by marker presence).
- [x] 7.2 Re-run without `UPDATE_GOLDENS` to prove convergence (0 mismatched pixels). **Result: 0/180000 mismatched pixels on all 4 `breeze-{light,dark}-cost-{present,absent}` scenarios.**
- [x] 7.3 Fix golden/artifact file ownership back to host user if needed; clean stray scratch trees. **Result: ownership was already host-owned (`docker run --user "$(id -u):$(id -g)"` used throughout), no chown needed; removed the gitignored `tests/visual/artifacts/` scratch tree.**
- [x] 3.5c Manual gate (re-run): **done** — row-sibling placement confirmed correct in Overview (just needed centering) and in detail mode's "before percent" position → triggered Phase 8 (Revision 3: detail flips to after-percent, custom bundled SVG icons). Re-smoke required after Phase 8/9, see 3.5d below.
- [x] 7.4 Update `docs/ui-parity-checklist.md` Notes to record the Revision 2 row-sibling verification.

## Phase 8: Custom Icons + Detail Placement Flip (PR 2 amendment, D27-D30)

Third live smoke: Overview placement/order approved as-is (just needs the marker centered in its slot); detail mode should flip to AFTER the percent text instead of before. User also asked whether custom SVGs were possible instead of Plasma's `emblem-*-symbolic` icons — confirmed yes per `plasma-kirigami-ui`'s "existing themed/vector icon, never emoji" rule, and chose (after reviewing 3 rendered mockup sets) a filled warning-triangle + filled critical-circle, each with an exclamation cut via SVG `<mask>`. Both SVGs already created at `contents/icons/threshold-warning.svg` / `contents/icons/threshold-critical.svg` (orchestrator-authored, user-approved against a rendered preview) — do not redesign the shapes, only wire them in. `design.md` Revision 3 (D27-D30) and `specs/provider-usage-display/spec.md` already updated to match.

- [x] 8.1 RED: update `tests/UsageWindowThresholdHarness.qml` — change `.source` assertions from checking for `"warning"`/`"important"` substrings to `"threshold-warning"`/`"threshold-critical"` (matching the new bundled filenames — note the critical icon file is named `threshold-critical.svg`, not `threshold-important.svg`); if any assertion checks `row.thresholdMarker` position relative to `bandPercentageLabel` in detail mode, flip the expected order (marker now AFTER the percent label, not before); confirm failure against current production code. **No position/order assertion exists in this harness** (verified — only `.source`/`.opacity`/`.color` checks), so only the `.source` fragment changed. Confirmed RED: `qml6` run failed with `thresholdMarker source must contain "threshold-warning" (level=warn, summary=true)`.
- [x] 8.2 GREEN: in `contents/ui/UsageWindowRow.qml`'s `thresholdMarkerComponent` — add `isMask: true`, change `source` from the `emblem-*-symbolic` ternary to `Qt.resolvedUrl("../icons/threshold-critical.svg")` / `Qt.resolvedUrl("../icons/threshold-warning.svg")` per D29 — mirror the exact `Qt.resolvedUrl(...) + isMask:true` pattern already used at `ProviderRow.qml:56,125-128` / `ProviderSelector.qml:123,386-388`. **Deviation from D28/design.md contract**: `horizontalAlignment`/`verticalAlignment` were NOT added — the installed Kirigami 6.28.0 `Icon` QML type (`KirigamiPrimitives.qmltypes`, `icon.h`) exposes no such properties (confirmed via qmllint: `Cannot assign to non-existent property "verticalAlignment"`); no other `Kirigami.Icon` usage in this codebase (`ProviderRow.qml`, `ProviderSelector.qml`, `CompactUsageButton.qml`) sets alignment either, and those icons already render centered in prior live smokes, so `Icon` centers its content internally by default on this Kirigami version. D28's stated properties are incompatible with the actual runtime and were omitted rather than silently faked.
- [x] 8.3 GREEN: moved `detailThresholdMarkerLoader` from its previous position (first child of the detail band `RowLayout`, before `bandPercentageLabel`) to immediately AFTER `bandPercentageLabel` (D27). Summary's `summaryThresholdMarkerLoader` position is UNCHANGED.
- [x] 8.4 Verified `UsageWindowThresholdHarness.qml` and `ProviderSelectorHarness.qml` pass fully (both exit 0 standalone via `qml6 --software -f`).
- [x] 8.5 Ran full `./scripts/run-qml-tests.sh` (exit 0, all suites pass) and `./scripts/lint-qml.sh`. The D12 exception line DID drift again (159 → 160, net +1 line from removing 2 alignment lines and adding 1 `isMask` line above the `titleRow` binding); re-pinned `LAYOUT_POSITIONING_EXCEPTIONS` in `scripts/check-qml-unqualified-baseline.py` to 160. `./scripts/lint-qml.sh` now exits 0 ("Accepted 83 exact KDE translation warning(s). Accepted 1 documented layout-positioning exception(s).").
- [x] 8.6 Confirmed: no `metadata.json` or packaging manifest exists that lists individual `contents/icons/*.svg` files — this repo's packaging (`kpackagetool6 -t Plasma/Applet -i/-u .` per `README.md`) installs the whole `contents/` tree as-is, and `metadata.json`'s only `Icon` field is the plasmoid's own top-level icon (`"codex"`), unrelated to bundled UI glyphs. `contents/icons/providers/*.svg` (49 files) already ship this way with zero registration, confirming the new `threshold-warning.svg`/`threshold-critical.svg` need none either.

## Phase 9: Golden Re-regen (PR 3 amendment, round 3)

- [x] 9.1 Re-ran `UPDATE_GOLDENS=1 ./scripts/run-visual-tests.sh` (reused existing `kodexbar-visual-local:test` image, no rebuild needed — Dockerfile unchanged). All 4 goldens regenerated, script exited 0. **Visual confirmation FAILED its stated criterion again, but for a NEW and more specific reason than Phase 5/7's `QIcon::fromTheme()` finding.** Pixel-level inspection of `breeze-dark-cost-present.png` and `breeze-light-cost-present.png` around the 94% Monthly row's `bandPercentageLabel` shows literally zero pixels differing from the pure-black background in the marker's expected slot — same "invisible" symptom as before. This time it is NOT a loading/theme-plugin failure: an isolated same-size (16×16), same-`isMask:true`, same-`Qt.resolvedUrl(...)` reproduction of `threshold-critical.svg` outside the app confirms the SVG loads (`status===Ready`, correct `sourceSize`) and DOES paint — the exact circle-with-exclamation-cutout silhouette renders at the right alpha shape and position. The bug is narrower: **the `color:` property override on an `isMask:true` `Kirigami.Icon` is not applied when its source is a local resolved-URL SVG, under this Docker image's Qt 6.11.1/Kirigami 6.28.0 in the `QT_QPA_PLATFORM=offscreen`+`QT_QUICK_BACKEND=software` combination** — the icon paints using the SVG's own intrinsic `fill="currentColor"` (defaults to black) instead of the bound `Kirigami.Theme.negativeTextColor`/`neutralTextColor`. Because this harness's captured content-area background is itself solid opaque black in both theme scenarios (pre-existing, unrelated to Light/Dark theming — see `docs/visual-regression.md`'s scope-boundary note), a solid-black-on-solid-black icon is pixel-identical to background (0 delta), hence still invisible. This means Phase 5/7's "harness limitation" theory was **incomplete, not fully resolved**: the bundled-SVG switch genuinely fixed the *loading* half (no more theme-plugin blindness) but exposed a second, previously-hidden *recoloring* gap specific to this offscreen/software path. See risk note in apply-progress / final report — this is a maintainer-relevant observation, not silently accepted.
- [x] 9.2 Re-run without `UPDATE_GOLDENS` to prove convergence: 0/180000 mismatched pixels on all 4 `breeze-{light,dark}-cost-{present,absent}` scenarios (deterministic regardless of the 9.1 finding — goldens are self-consistent, just visually blind to the icon's color).
- [x] 9.3 Ownership: this run's goldens/artifacts stayed host-owned (`docker run --user "$(id -u):$(id -g)"` per `docs/visual-regression.md`) — no chown needed. No stray root-owned files found repo-wide. Removed the gitignored `tests/visual/artifacts/` scratch tree (per-run captures/diffs; not meant to persist).
- [x] 3.5d Manual gate (re-run): **done — user confirmed "ahora si me gusta como quedo".** Breeze Light + Dark `plasmawindowed` smoke with the custom icons + flipped detail placement: shape (triangle/circle with exclamation cutout), color (orange warn / red critical, correctly recolored on real hardware-accelerated rendering, unaffected by the 9.1 offscreen-software-only recolor gap), Overview centering, and detail-mode after-percent placement all confirmed correct. Change is now functionally closed pending only archive.
- [x] 9.4 Updated `docs/ui-parity-checklist.md` Notes to record the Revision 3 regeneration and the 9.1 color-recolor finding honestly (not a false "verified").
