# Proposal: Cost Section Compact Format

## Intent

`CostSection.qml` renders "Today: $36.46 · 108,218,539 tokens" as one dense line per period. The existing `provider-cost-estimate` spec already requires the section to be labeled as a local token-cost estimate ("label `source: local` as a local token-cost estimate"), but `CostSection.qml` never actually renders that label as visible text — it's only true in documentation and the archived spec's intent. Reformat into a scannable two-column layout (period label left, value right-aligned), abbreviate large token counts, and finally surface the "Local token-cost estimate" caption the spec has required all along.

## Scope

### In Scope

1. `contents/ui/CostSection.qml`: replace the two single-line `costSessionLabel`/`costLast30DaysLabel` `PlasmaComponents.Label`s with `RowLayout`s — period name ("Today" / "Last 30 days") left, value right-aligned. `objectName`s `costSessionLabel`/`costLast30DaysLabel` move to the value `Label` (right side), preserving existing test/harness handles.
2. New `formatUsd()`: fixed comma-decimal, period-thousands-grouped (e.g. `36,27`; `1.210,98`) — **not** locale-dependent (explicit user decision: same format on every machine regardless of system locale). Replaces the current `.toFixed(2)`-only (period-decimal) formatting.
3. New `formatTokensAbbreviated()`: K/M/B suffix abbreviation with one decimal place, comma as the decimal separator (e.g. `108,2M`, `4,0B`, `1,2K`), replacing the current full comma-grouped digit string (`108,218,539`). Values under 1000 render as plain integers, no suffix.
4. New caption `PlasmaComponents.Label` — text `"Local token-cost estimate"`, `Kirigami.Theme.disabledTextColor`, small font — visible only when `root.hasSnapshot && root.snapshot.source === "local"` (closes the existing spec's "label as a local token-cost estimate" requirement, which has never had a visible implementation).
5. Update `tests/ProviderRowHarness.qml`'s existing cost-format assertions (`:612`, `:669-676`) to match the new comma-decimal/period-thousands/abbreviated-token format; the "never scientific notation" guard (`:671-672`) stays and must still pass.

### Out of Scope

- Gating the WHOLE Cost section's visibility on `source === "local"` — only the new caption is gated; the rest keeps its current `hasSnapshot`-only visibility (existing, validated, unrelated behavior).
- System-locale-aware formatting (`Intl`/`Qt.locale()`) — explicit user decision: fixed format everywhere, not locale-adaptive.
- Any change to `CostModel.js`, `CostController.qml`, the `cost` CLI invocation, or cost data validation — display formatting only.
- Any change to the `costLabel` ("Cost") section title.

## Capabilities

### Modified Capabilities
- `provider-cost-estimate`: "Provider-specific cost contract" requirement's existing "local-estimate labeling" language gets a concrete visible-caption scenario; this is closing a documented-but-unimplemented requirement, not adding new product surface.

## Approach

Two pure formatting functions replace the existing ones in `CostSection.qml` (same file, same `.pragma`-free local-function pattern the file already uses — this file's comment already explains why raw `i18n()` substitution of large numbers was rejected before, for scientific-notation reasons; the new functions inherit that same defensive stance). Layout changes from single dense `Label`s to `RowLayout`s mirroring the label-left/value-right pattern already established elsewhere in this codebase (e.g. `UsageWindowRow.qml`'s detail band row).

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/ui/CostSection.qml` | Modified | Row layout, new format functions, new caption |
| `tests/ProviderRowHarness.qml` | Modified | Format assertions updated to new strings (`:612`, `:669-676`) |
| `openspec/specs/provider-cost-estimate/spec.md` | Modified | "Provider-specific cost contract" requirement delta |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| New abbreviation/format functions reintroduce scientific notation for edge values | Low | Existing `:671-672` guard assertion is preserved and re-run against the new functions |
| Existing `ProviderRowHarness.qml` assertions break silently if not updated in the same unit | Medium | Task list requires updating them in the same RED→GREEN cycle, not after |
| Token abbreviation precision (1 decimal always) doesn't match what the user pictured | Low | Flagged explicitly in design; easy to adjust after a live look, same iteration pattern already used successfully in this session |

## Rollback Plan

Revert `CostSection.qml` and the `ProviderRowHarness.qml` assertion updates together (one unit) — no model/controller/CLI surface touched, so rollback is total.

## Success Criteria

- [ ] "Today"/"Last 30 days" labels sit left; values (`$X,XX - YM tokens`) sit right-aligned.
- [ ] USD values use comma-decimal, period-thousands grouping.
- [ ] Token counts abbreviate at K/M/B with one decimal.
- [ ] "Local token-cost estimate" caption appears exactly when `source === "local"` and a snapshot is present.
- [ ] No scientific notation anywhere, at any magnitude.
- [ ] `run-qml-tests.sh` and `lint-qml.sh` pass; live Breeze smoke confirms the layout reads well at popup width.
