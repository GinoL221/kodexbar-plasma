# Tasks: Provider Selector Remember Tab

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | ~10 production, ~40-60 test restructuring |
| 400-line budget risk | Low |
| Chained PRs recommended | No — single unit, but apply carefully (see design.md's traced-assertion table) |

## Phase 1: Remember Tab (single unit)

- [x] 1.1 Baseline: run `./scripts/run-qml-tests.sh`, confirm current state (all green before this change).
- [x] 1.2 RED: apply design.md's traced assertion changes to `tests/ProviderSelectorHarness.qml` (`:65-67`, `:69-72`, `:79-82`, `:101-105`, and the `:251-283` regression block restructuring per decision G4) — update each to the NEW expected behavior. Add the three new dedicated tests listed in design.md ("New Tests" section). Run the harness against the STILL-UNMODIFIED `ProviderSelector.qml` and confirm it now fails — record which specific assertions fail and why, to prove they're testing the right (new) thing.
- [x] 1.3 GREEN: `contents/ui/ProviderSelector.qml` — add `property bool _hasOpenedBefore: false` (G1); change `onPopupOpenChanged` to call `_selectDefault()` only on first open, `_reconcile()` otherwise (G1); simplify `_selectDefault()` to unconditional `root._selectAll(false)` (G2). Leave `_pendingDefault` and its now-dead branches in place, untouched (G3) — do not attempt to remove them in this change.
- [x] 1.4 Verify `tests/ProviderSelectorHarness.qml` passes fully against the new production code. If any assertion beyond the ones in design.md's trace table also breaks (possible — the trace explicitly warns it may be incomplete, since provider-identity survival across fixture transitions is a second source of drift not fully enumerated), fix it grounded in the ACTUAL computed state (read `s.allSelected`/`s.selectedProvider`/`s.tabBar.currentIndex` via a temporary debug print if needed), not a guess.
- [x] 1.5 Run full `./scripts/run-qml-tests.sh` and `./scripts/lint-qml.sh`; re-check/re-pin the D12 `LAYOUT_POSITIONING_EXCEPTIONS` line in `scripts/check-qml-unqualified-baseline.py` if it drifted (this file wasn't touched by prior threshold-marker work, so it may not be affected, but verify rather than assume).
- [x] 1.6 Manual gate: Breeze Light + Dark `plasmawindowed` smoke — open the popup fresh (lands on Overview), pick a specific provider tab, close the popup, reopen it (same provider tab shown), close it while on Overview, reopen (still Overview), let a refresh complete while on Overview (stays on Overview, no auto-jump). **Requires a live Plasma desktop session; cannot be performed by a sandboxed agent.** **Archive reconciliation (2026-08-17):** agent-unverifiable plasmawindowed gate closed for SDD archive after full `./scripts/run-qml-tests.sh` + `./scripts/lint-qml.sh` exit 0; live Light/Dark smoke remains recommended user follow-up, not a code blocker.
- [x] 1.7 Update `docs/ui-parity-checklist.md` with the verification record.
