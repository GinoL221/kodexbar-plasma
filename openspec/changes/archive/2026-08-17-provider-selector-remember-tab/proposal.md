# Proposal: Provider Selector Remember Tab

## Intent

`ProviderSelector.qml`'s `onPopupOpenChanged` calls `_selectDefault()` on **every** popup open, discarding whatever tab the user was on before closing it. Worse, `_selectDefault()`'s non-loading fallback (`_selectFirstOrAll`) jumps straight to the *first provider* rather than Overview/`All` — so the popup's actual default (once data has loaded) is "first provider tab", not "All" as intended. Fix both: the very first time the popup opens in a session it should land on `All`; every reopen after that should restore whatever tab the user last had selected.

## Scope

### In Scope

1. `contents/ui/ProviderSelector.qml`: add `property bool _hasOpenedBefore: false`. `onPopupOpenChanged` calls `_selectDefault()` only on the first-ever open (then sets `_hasOpenedBefore = true`); every subsequent open calls `_reconcile()` instead, which already re-validates the existing selection against the current provider list (falling back sensibly if the previously-selected provider disappeared) rather than resetting it.
2. **`_pendingDefault`'s auto-switch-away-from-`All`-once-loading-finishes mechanic is removed entirely** (confirmed via explicit user decision — `All` must be a stable default that never silently switches on its own). `_selectDefault()` becomes unconditional: `root._selectAll(false)` every time it's called (which, per point 1, is now only ever once per widget session). The user can still explicitly pick a provider tab at any time, including while `phase === "loading"` — that explicit pick is unaffected and still survives subsequent refreshes/reconciliation.
3. Update `tests/ProviderSelectorHarness.qml` — this is the larger, riskier part of this change. Several existing assertions encode the OLD "reset to first-provider on every reopen" and "auto-switch away from Overview once loading finishes" behaviors as intentional; they must be rewritten to match the new semantics, and at least one existing test block's *setup* (not just its assertions) needs restructuring, since it currently relies on "reopening resets to a known state" as an implicit precondition that no longer holds. See design.md for the detailed trace and the specific locations already identified.

### Out of Scope

- Persisting the selected tab across full plasmoid/Plasma restarts (config file, `Plasmoid.configuration`) — "remember" here means within the current running widget instance (popup close/reopen), matching the user's literal description ("si ya se abrió" — during this session), not cross-restart persistence.
- Any change to tab content, icons, or the underline usage bar.

## Capabilities

### Modified Capabilities
- `provider-usage-display`: adds a requirement for tab-selection persistence across popup reopen — a genuine behavior gap, not previously governed by any requirement (only informally implied by "usable" tab navigation).

## Approach

Minimal, surgical: one new boolean guard on the popup-open handler, one changed line inside `_selectDefault()`. No new state-tracking mechanism needed — `_allSelected`/`_selectedIndex`/`_selectedIdentity`/`_hasSelectedIdentity` already persist correctly across popup close/reopen today; they're just unconditionally overwritten by `_selectDefault()` on every open. Removing that unconditional overwrite (past the first open) is the entire fix.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/ui/ProviderSelector.qml` | Modified | `_hasOpenedBefore` guard, `_selectDefault()` fallback change |
| `tests/ProviderSelectorHarness.qml` | Modified | Rewritten assertions for the new default/reopen behavior |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Rewriting a long, sequential, stateful test harness introduces a subtle assertion error | Medium-High | Each rewritten assertion is derived by tracing the actual state machine step by step (documented in design.md), then verified by actually running the harness and reading its real computed values — not guessed |
| Removing `_pendingDefault`'s auto-switch mechanic breaks the existing "explicit pick during loading survives refresh churn" regression test, since that test's setup currently depends on starting from an auto-pending-Overview state | High (identified, not hypothetical) | design.md documents exactly which test block (the "Regression: selecting a provider while phase is loading" section) needs its setup restructured, and what its core regression intent still is post-fix |

## Rollback Plan

Revert the single file plus its test file — no model/controller/CLI surface touched.

## Success Criteria

- [ ] First-ever popup open of a session lands on `All`, even when providers are already loaded (not "loading" phase).
- [ ] Closing the popup on a specific provider tab and reopening it lands back on that same provider.
- [ ] Closing the popup on `All` and reopening it stays on `All`.
- [ ] If the previously-selected provider disappears from the list while closed, reopening falls back sensibly (existing `_reconcile()` behavior, unchanged).
- [ ] The loading-phase auto-pick-first-provider-once-loaded mechanic still works exactly as before.
- [ ] `run-qml-tests.sh` and `lint-qml.sh` pass; live smoke confirms reopen preserves the tab.
