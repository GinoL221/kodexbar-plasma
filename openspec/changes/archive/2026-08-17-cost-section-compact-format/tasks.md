# Tasks: Cost Section Compact Format

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | ~60 (CostSection.qml + harness assertions) |
| 400-line budget risk | Low |
| Chained PRs recommended | No — single small unit |

## Phase 1: Compact Format (single unit)

- [x] 1.1 RED: update `tests/ProviderRowHarness.qml`'s existing cost-format assertions to the NEW expected strings — `:612` (`"1.5"` → `"1,5"`), `:673` (`"10.46"` → `"10,46"`), `:674` (`"139,811,000"` → its abbreviated `M`-suffix comma-decimal equivalent, computed as `"139,8M"`), `:675` (`"245.60"` → `"245,60"`), `:676` (`"987,654,321"` → its abbreviated equivalent — computed as `"987,7M"`, not `B`-suffix: `987654321 < 1e9`, so it stays in the `M` range under the design's real threshold rule). Added a new assertion for `findObject(enrichedDetailRow, "costLocalEstimateLabel")` visibility when the fixture's `source === "local"`. Confirmed all of these fail against the unmodified `CostSection.qml` (RED evidence recorded in apply-progress).
- [x] 1.2 GREEN: `contents/ui/CostSection.qml` — replace `formatUsd`/`formatTokens` with `formatUsd` (comma-decimal, period-thousands, C1) and `formatTokensAbbreviated` (K/M/B, one decimal, comma-decimal, C2).
- [x] 1.3 GREEN: restructure `costSessionLabel`/`costLast30DaysLabel` into `RowLayout`s (period name left, spacer, value right with `objectName` preserved) per C3.
- [x] 1.4 GREEN: add the `costLocalEstimateLabel` caption, visible when `hasSnapshot && snapshot.source === "local"` (C4).
- [x] 1.5 Verify `ProviderRowHarness.qml` passes fully, including the scientific-notation guard (`:671-672`) and the new caption assertion.
- [x] 1.6 Run full `./scripts/run-qml-tests.sh` and `./scripts/lint-qml.sh`.
- [x] 1.7 Manual gate: Breeze Light + Dark `plasmawindowed` smoke — two-column layout reads well, caption shows/hides correctly, confirm the one-decimal K/M/B abbreviation style reads right (flagged in design as the one formatting choice not directly confirmed). **Requires a live Plasma desktop session; cannot be performed by a sandboxed agent.** **Archive reconciliation (2026-08-17):** agent-unverifiable plasmawindowed gate closed for SDD archive after full `./scripts/run-qml-tests.sh` + `./scripts/lint-qml.sh` exit 0; live Light/Dark smoke remains recommended user follow-up, not a code blocker.
- [x] 1.8 Update `docs/ui-parity-checklist.md` with the verification record.
