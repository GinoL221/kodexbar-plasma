# Tasks: Usage Threshold Exhausted Level

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | ~40 (production) + test additions |
| 400-line budget risk | Low |
| Chained PRs recommended | No — single small unit |
| Delivery strategy | ask-on-risk |

## Phase 1: Exhausted Level (single unit)

- [x] 1.1 RED: extend `tests/UsageThresholdHarness.qml`'s boundary table — `level(99.9)==="critical"`, `level(100)==="exhausted"`, `level(100.0)==="exhausted"`, `level(120)==="exhausted"`, `EXHAUSTED_AT===100`, `isRisk(LEVEL_EXHAUSTED)===true`; confirm failure.
- [x] 1.2 GREEN: `contents/code/UsageThreshold.js` — add `EXHAUSTED_AT = 100`, `LEVEL_EXHAUSTED = "exhausted"`; reorder `level()`'s branches so `>= EXHAUSTED_AT` is checked before `>= CRITICAL_AT`; `isRisk()` includes `LEVEL_EXHAUSTED` (E1).
- [x] 1.3 Verify `UsageThresholdHarness.qml` passes.
- [x] 1.4 RED: add a `usedPercent:100` fixture pair (summary + detail) to `tests/UsageWindowThresholdHarness.qml`; assert `.source` contains `"threshold-exhausted"`, `Qt.colorEqual(color, Kirigami.Theme.negativeTextColor)`, reserved-slot width-equality holds against this fixture too, cross-mode identity; confirm failure.
- [x] 1.5 GREEN: `contents/ui/UsageWindowRow.qml`'s `thresholdMarkerComponent` — 3-way `source` ternary (`exhausted`→`threshold-exhausted.svg`, `critical`→`threshold-critical.svg`, else `threshold-warning.svg`), 3-way `color` ternary (`exhausted`/`critical`→`negativeTextColor`, `warn`→`neutralTextColor`, else transparent) (E2-E3).
- [x] 1.6 GREEN: add `"Quota exhausted"` a11y branch in the same `hasFinitePercent` block, alongside the existing `"Critical usage"`/`"Elevated usage"` branches (E4).
- [x] 1.7 Verify `UsageWindowThresholdHarness.qml` passes fully.
- [x] 1.8 Run full `./scripts/run-qml-tests.sh` and `./scripts/lint-qml.sh`; re-check/re-pin the D12 `LAYOUT_POSITIONING_EXCEPTIONS` line if it drifted (has drifted on every prior edit to this file).
- [x] 1.9 Manual gate: Breeze Light + Dark `plasmawindowed` smoke — exhausted icon reads distinct from critical, color matches critical, tabs unchanged. **Requires a live Plasma desktop session; cannot be performed by a sandboxed agent.** **Archive reconciliation (2026-08-17):** agent-unverifiable plasmawindowed gate closed for SDD archive after full `./scripts/run-qml-tests.sh` + `./scripts/lint-qml.sh` exit 0; live Light/Dark smoke remains recommended user follow-up, not a code blocker.
- [x] 1.10 Update `docs/ui-parity-checklist.md` with the verification record.
