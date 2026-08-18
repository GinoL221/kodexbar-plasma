# Design: Usage Threshold Exhausted Level

## Technical Approach

Purely additive extension of the already-shipped threshold-marker architecture (archived `usage-threshold-marker` change, `openspec/changes/archive/2026-08-17-usage-threshold-marker/`). No new architectural mechanism — one more classification branch in `UsageThreshold.js`, one more bundled `isMask` SVG, one more ternary arm in the existing shared `thresholdMarkerComponent`. The icon's shape and color were resolved interactively with the user (rendered previews, several iterations) before this document was written — see Decisions below for the final, approved contract.

Strict TDD (`openspec/config.yaml: strict_tdd: true`): RED anchors named per decision below.

## Architecture Decisions

| # | Decision | Alternatives rejected | Rationale |
|---|----------|-----------------------|-----------|
| E1 | **`UsageThreshold.js` gains `EXHAUSTED_AT = 100` and `LEVEL_EXHAUSTED = "exhausted"`.** `level()`'s branch order becomes: `>= EXHAUSTED_AT` → `exhausted`, else `>= CRITICAL_AT` → `critical`, else `>= WARN_AT` → `warn`, else `ok`. Values above 100 still classify as `exhausted`, never clamped (same non-clamping stance as the original `critical` branch). `isRisk()` returns `true` for `exhausted` alongside `warn`/`critical` | A separate `isExhausted()` predicate; treating `exhausted` as a modifier flag on `critical` instead of a distinct level string | A fourth level string (not a boolean flag) is what the three consumers (icon `source`, `color`, a11y phrase) all switch on identically to how they already switch on `warn`/`critical` — adding a flag would mean two axes to check everywhere instead of one. Checking `EXHAUSTED_AT` **before** `CRITICAL_AT` is the one line that must be right, hence the dedicated RED boundary test at exactly 100 |
| E2 | **Icon: filled octagon with a diagonal "no entry" slash cut via `<mask>`** (`contents/icons/threshold-exhausted.svg`), same currentColor-mask technique as the existing two icons. Color: **same `Kirigami.Theme.negativeTextColor` as `critical`** — shape is the sole differentiator, not color | A distinct color for `exhausted`; a circle+slash (too similar in silhouette to `critical`'s circle+exclamation at 16px, user's explicit feedback: "podrias hacerma mas distintivo que el de mas de 90%"); a literal two-tone icon with a hardcoded white slash line (rejected — `isMask:true` recolors the entire non-transparent silhouette as one flat color, so a "white" shape drawn inside the SVG would render in the same red as the rest, not white; achieving a genuine two-tone icon would require `isMask:false` with hardcoded hex colors baked into the SVG, breaking the "semantic Kirigami color only, no hardcoded hex" rule this whole feature has followed since its first line — user explicitly chose to keep the transparent-cutout slash over that tradeoff) | An octagon (8-sided, "stop sign" silhouette) is maximally distinct from `warn`'s triangle (3 sides) and `critical`'s circle (0 sides/round) at small render sizes, where subtle differences (e.g. a vertical vs. diagonal mark on the same circular silhouette, the first iteration tried) don't read clearly. Same color as `critical` was explicitly requested by the user to keep the "still bad" semantic grouping (both are `negativeTextColor` = danger), differentiated by shape (silhouette), not a second danger hue |
| E3 | **`thresholdMarkerComponent`'s `source`/`color` ternaries in `UsageWindowRow.qml` become 3-way, checked in this order: `exhausted` → `critical` → `warn` (else `""`/transparent)**. No change to the component's frame, `opacity`-driven reserved-slot visibility, or placement logic (D19-D26 from the archived change) | Nesting a boolean check on top of the existing 2-way ternary instead of a clean 3-way chain | Matches `UsageThreshold.level()`'s own branch order (E1) — same "most severe first" convention in both the classifier and the consumer, so a reader checking one can predict the other |
| E4 | **A11y phrase: `"Quota exhausted"`** for `exhausted`, nested in the same `hasFinitePercent` block as the existing two phrases, same append-after-percent-entry rule (unchanged structural guarantee from the archived change's D10) | `"Fully critical usage"`; `"100% used"` (redundant with the percent entry already present) | Distinct three-word phrase, sentence-cased like its neighbors, and semantically different from `"Critical usage"` rather than a size/degree variant of it — "exhausted" signals zero-remaining, not merely a bigger number |

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `contents/code/UsageThreshold.js` | Modify | `EXHAUSTED_AT`, `LEVEL_EXHAUSTED`, `level()` branch, `isRisk()` (E1) |
| `contents/icons/threshold-exhausted.svg` | Create | Already created and user-approved (E2) |
| `contents/ui/UsageWindowRow.qml` | Modify | 3-way `source`/`color` ternary (E3), a11y phrase (E4) |
| `tests/UsageThresholdHarness.qml` | Modify | Boundary table: 99.9→critical, 100/100.0/120→exhausted |
| `tests/UsageWindowThresholdHarness.qml` | Modify | New `usedPercent:100` fixture pair (summary+detail), asserting `.source` contains `"threshold-exhausted"`, color, reserved-slot/fill-independence/cross-mode invariants hold |

## Testing Strategy

| Layer | RED anchor | Approach |
|-------|-----------|----------|
| Unit (JS) | `UsageThresholdHarness.qml`: `level(99.9)==="critical"`, `level(100)==="exhausted"` fails before `EXHAUSTED_AT`/branch reorder exists (E1) | `./scripts/run-qml-tests.sh` |
| Unit (QML) | `UsageWindowThresholdHarness.qml`: 100% fixture's `.source` check for `"threshold-exhausted"` fails before the 3-way ternary exists (E3) | `./scripts/run-qml-tests.sh` |
| Unit (QML) | Same fixture's `Qt.colorEqual(marker.color, Kirigami.Theme.negativeTextColor)` — must hold alongside the new source, proving E2's "same color as critical" decision | `./scripts/run-qml-tests.sh` |
| Unit (QML) | Reserved-slot invariant re-checked at the new level (reuse the existing width-equality assertion pattern with an `exhausted` fixture instead of/alongside `critical`) | `./scripts/run-qml-tests.sh` |
| Static (lint) | `./scripts/lint-qml.sh` — re-check/re-pin `LAYOUT_POSITIONING_EXCEPTIONS` per the standing D12 discipline (this file's line pin has drifted on every prior edit to `UsageWindowRow.qml`) | `./scripts/lint-qml.sh` |
| Manual (gating) | Breeze Light + Dark `plasmawindowed` smoke: exhausted icon reads clearly distinct from critical at Overview scale, color matches critical, a11y phrase correct | `docs/live-plasma-smoke.md` |

## Migration / Rollout

No migration, no CLI/model/schema change. Single work unit (small diff, well under the 400-line budget) — no chained-PR split needed.
