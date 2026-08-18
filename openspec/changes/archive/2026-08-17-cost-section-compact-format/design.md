# Design: Cost Section Compact Format

## Technical Approach

`contents/ui/CostSection.qml` is 81 lines, self-contained (no external format helper module exists yet — `formatUsd`/`formatTokens` are local functions on the root `ColumnLayout`). This change replaces those two functions and restructures the two value `Label`s into `RowLayout`s, without touching `CostModel.js`, `CostController.qml`, or any CLI/data-validation code. Strict TDD (`openspec/config.yaml: strict_tdd: true`).

## Architecture Decisions

| # | Decision | Alternatives rejected | Rationale |
|---|----------|-----------------------|-----------|
| C1 | **`formatUsd(value)` produces comma-decimal, period-thousands-grouped strings** (`36.27` → `"36,27"`, `1210.98` → `"1.210,98"`), always — not `Qt.locale()`/`Intl`-driven | System-locale-aware formatting via `Number.toLocaleString`/`i18n()` substitution | Explicit user decision (confirmed via question before implementation): fixed format everywhere, not locale-adaptive, matching the exact digit-grouping/decimal-separator style the user specified. The file's existing comment already documents *why* `i18n()`'s raw `%1` substitution was rejected for large numbers (scientific notation) — the new function keeps that same defensive stance, just changes which separators the fixed format uses |
| C2 | **`formatTokensAbbreviated(value)` abbreviates at K/M/B with exactly one decimal place**, comma as the decimal separator (`108218539` → `"108,2M"`, `4030235465` → `"4,0B"`, `1200` → `"1,2K"`); values `< 1000` render as a plain integer, no suffix | Zero decimals for M and one for B (what the user's own hand-mocked screenshot showed, inconsistently); a locale-aware `Intl.NumberFormat` compact notation | One decimal *consistently* across K/M/B is a cleaner, more standard convention than a magnitude-dependent precision rule, and avoids inventing an arbitrary "0 decimals below 1B, 1 decimal at 1B+" special case the user's mockup didn't actually specify as a rule (the mockup's exact digits were placeholders, not real CLI output — flagged explicitly here since it's the one formatting choice not confirmed by a direct answer, unlike C1) |
| C3 | **Layout**: each of the two value rows becomes `RowLayout { PlasmaComponents.Label (period name, left) ; Item (Layout.fillWidth: true, spacer) ; PlasmaComponents.Label (value, right, objectName preserved) }`. `objectName costSessionLabel`/`costLast30DaysLabel` move from the old single dense label onto the new right-side value label, so `tests/ProviderRowHarness.qml`'s existing `findObject(row, "costSessionLabel")` handles keep resolving without renaming | A `GridLayout` with two columns for both rows at once; keeping one dense label and right-aligning the whole string | Two independent `RowLayout`s mirror the label-left/value-right pattern this codebase already uses elsewhere (`UsageWindowRow.qml`'s detail band row: `bandPercentageLabel` left, spacer, reset text right) — reusing an established pattern instead of introducing a `GridLayout` for two rows. Keeping the `objectName` on the value label (not inventing a new name) means the existing `ProviderRowHarness.qml` assertions at `:612` and `:669-676` only need their *expected string content* updated, not their lookup calls |
| C4 | **New caption**: `PlasmaComponents.Label { objectName: "costLocalEstimateLabel"; text: "Local token-cost estimate"; color: Kirigami.Theme.disabledTextColor; visible: root.hasSnapshot && root.snapshot.source === "local" }`, placed as the last child of the root `ColumnLayout`, after both value rows | Always showing the caption whenever `hasSnapshot` is true, without checking `source` | The existing `provider-cost-estimate` spec's "Provider-specific cost contract" requirement already says the section must "label `source: local` as a local token-cost estimate" — gating on the actual `source` field (already parsed and validated by `CostModel.normalize()`, just never read by `CostSection.qml` before this change) is the literal, most faithful implementation of that existing requirement, not a new invented condition |

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `contents/ui/CostSection.qml` | Modify | New `formatUsd`/`formatTokensAbbreviated` (C1-C2), two `RowLayout`s (C3), new caption (C4) |
| `tests/ProviderRowHarness.qml` | Modify | `:612` updates the substring check to the new format; `:669-676` updates all four format-specific assertions to the new comma-decimal/period-thousands/abbreviated strings, keeping the scientific-notation guard |

## Testing Strategy

| Layer | RED anchor | Approach |
|-------|-----------|----------|
| Unit (QML, existing harness) | `ProviderRowHarness.qml:612` (`"1.5"` substring — becomes `"1,5"` under the new comma-decimal format) and `:673-676` (old `"10.46"`/`"139,811,000"`/`"245.60"`/`"987,654,321"` strings — become their comma-decimal/period-thousands/abbreviated equivalents) fail against the still-old `CostSection.qml` before the format functions change | `./scripts/run-qml-tests.sh` |
| Unit (QML) | New assertion: `findObject(enrichedDetailRow, "costLocalEstimateLabel")` visible when the fixture's `snapshot.source === "local"` | `./scripts/run-qml-tests.sh` |
| Regression guard | `:671-672`'s "never `e+`" scientific-notation check must still pass against the new functions at the same large fixture values | `./scripts/run-qml-tests.sh` |
| Static (lint) | `./scripts/lint-qml.sh` | `./scripts/lint-qml.sh` |
| Manual (gating) | Breeze Light + Dark `plasmawindowed` smoke: two-column layout reads well at popup width, caption appears/disappears correctly, abbreviation precision looks right (C2 is the one unconfirmed formatting choice) | `docs/live-plasma-smoke.md` |

## Migration / Rollout

No migration, no CLI/model/schema change. Single small work unit.
