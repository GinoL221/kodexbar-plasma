# Design: Provider Selector Remember Tab

## Technical Approach

`contents/ui/ProviderSelector.qml`'s existing selection state (`_allSelected`, `_selectedIndex`, `_selectedIdentity`, `_hasSelectedIdentity`) already persists correctly in memory across popup close/reopen — nothing clears it on close. The only reason reopening ever appeared to "reset" is that `onPopupOpenChanged` unconditionally calls `_selectDefault()` on every open, which unconditionally overwrites that state. Removing the unconditional call (past the first open) is the fix; `_reconcile()` already does the right thing with whatever state survives.

Strict TDD (`openspec/config.yaml: strict_tdd: true`).

## Architecture Decisions

| # | Decision | Alternatives rejected | Rationale |
|---|----------|-----------------------|-----------|
| G1 | **`property bool _hasOpenedBefore: false`.** `onPopupOpenChanged` becomes: `if (root.popupOpen) { if (!root._hasOpenedBefore) { root._hasOpenedBefore = true; root._selectDefault() } else { root._reconcile() } }` | A `Set`/timestamp-based "was this the first open" check; persisting the flag to `Plasmoid.configuration` | A plain boolean is sufficient — "first open of this widget instance" is exactly what needs distinguishing, and persisting it further would silently expand scope into cross-restart persistence, explicitly out of scope |
| G2 | **`_selectDefault()` becomes unconditional**: `function _selectDefault() { root._selectAll(false) }`, replacing both its former branches (`_selectAll(true)` while loading, `_selectFirstOrAll(usable)` otherwise) | Keeping the loading-phase branch's `pending=true` and only changing the non-loading branch | Confirmed via explicit user decision: `All` must be a *stable* default that never silently switches away once data arrives — keeping any `pending=true` path would preserve exactly the "auto-jump away from All" behavior the user rejected. Since `_selectDefault()` now only ever runs once (G1), there's no longer a "wait for load, then auto-pick" moment to protect — the very first open simply shows `All`, stably, whether or not data has loaded yet |
| G3 | **`_pendingDefault` becomes permanently `false` after this change** (nothing sets it `true` anymore, since `_selectAll(true)` is never called by the new `_selectDefault()`). The property, `_isAllSelected()`'s and `_resolveSelectedProvider()`'s `if (root._pendingDefault)` branches, and `_reconcile()`'s `if (root._pendingDefault)` branch become dead code | Deleting `_pendingDefault` and all its branches outright | Keeping the property and branches (now permanently inert) is the **lower-risk** choice for this change: `_selectAll(pending)` still takes a `pending` parameter used elsewhere structurally, and fully excising a threaded-through boolean from four functions risks introducing an unrelated bug in code this change doesn't need to touch. If a future cleanup pass wants to delete the now-dead `_pendingDefault` machinery entirely, that's a separate, low-risk mechanical simplification — not bundled here |
| G4 | **Test harness restructuring, not just assertion updates.** `tests/ProviderSelectorHarness.qml`'s "Regression: selecting a provider while phase is loading" block (existing lines ~251-283) currently *depends* on reopening resetting to a pending-Overview state as its setup precondition — that precondition no longer exists. The block's actual regression intent (an explicit provider pick must survive subsequent refresh/phase churn without reverting) is still valid and must be preserved, but its setup needs an explicit `s.tabBar.currentIndex = 0; s._activateIndex(0)` (or equivalent) before the loading-churn assertions, rather than relying on reopen-while-loading to produce a known starting state | Deleting the block; leaving it broken and skipping it | The regression it guards (explicit picks surviving churn) is real and worth keeping; only its setup assumption is stale |

## Traced Assertion Changes (verify each empirically, do not trust this trace blindly)

This harness is one long sequential script mutating a single `ProviderSelector` instance — state at each point depends on everything before it. The trace below identifies the specific points known to change; **run the harness after the production fix and use real output to catch anything this trace missed**, especially any reopen where the previously-selected provider identity happens to still exist in the next fixture's list (under the new behavior, `_reconcile()` will find and keep that identity instead of jumping to the fixture's first provider, which is a second, more subtle source of assertion drift beyond the "was `All` before close" cases called out below).

| Location (current file) | Current assertion | Why it changes | New expected value |
|---|---|---|---|
| `:65-67` | `s.allSelected && ...` after first-ever open, empty providers | First open still calls `_selectDefault()` (G1) → unconditional `_selectAll(false)` (G2) | Unchanged — still `allSelected === true` |
| `:69-72` | `!s.allSelected && selectedProvider.provider === "second"` ("first usable") after the SECOND open (real providers now available) | This is no longer the first open → `_reconcile()` runs, not `_selectDefault()`. State before this close was `_allSelected=true` (from the first open) → `_reconcile()`'s `if (_allSelected) { setIndex(0); return }` keeps `All` | Becomes `s.allSelected === true && s.selectedProvider === null` |
| `:79-82` | `"pending loading All"` then `"settle first usable"` (asserts an auto-switch to `"later"` once `phase` leaves `"loading"`) | `_pendingDefault` is never engaged past the first open (G2/G3) — there is no pending state to "settle". Line 79's reopen keeps whatever was selected before (by this point, `All`, from the explicit pick at `:75-77`) | `:80`'s `s.allSelected` stays `true` (same boolean, different mechanism — no longer "pending", just "still All"). `:81-82`'s auto-switch-to-`"later"` assertion must be REMOVED or replaced with an assertion that `All` remains selected after the phase change (no auto-switch) — this is precisely the new "Overview never auto-switches away on its own" spec scenario |
| `:101-105` ("reopen default") | `!s.allSelected && selectedProvider.provider === "delta"` after explicitly picking `All` (`:102-103`) then closing/reopening | State before close was `_allSelected=true` (index 0 explicitly activated) → `_reconcile()` keeps `All` | Becomes `s.allSelected === true && s.selectedProvider === null` — rename the assertion label from `"reopen default"` to something like `"reopen preserves Overview"` |
| `:251-283` ("Regression: selecting a provider while phase is loading") | Opens expecting to land on pending-`All` (`:261-262`), then picks a provider | Not the first open → `_reconcile()` runs; whatever was selected before this block's `popupOpen=false` carries over directly, not necessarily `All` | Per G4: before the loading-churn assertions, add an explicit `s.tabBar.currentIndex = 0; s._activateIndex(0)` to force a known `All` starting point, THEN proceed with the existing "pick a provider, simulate churn, confirm it survives" assertions (`:263` onward) — those should still pass largely as-is once the precondition is restored explicitly rather than assumed from reopen |

## New Tests (RED-first, per strict TDD)

1. **First open defaults to `All` even when providers are already loaded, not `"loading"` phase** — this is effectively what `:69-72` becomes (see trace above), but write it explicitly as a dedicated assertion with a clear label rather than relying on the pre-existing narrative flow.
2. **Reopen preserves a specific provider tab** (not just `All`) — new scenario, e.g.: pick a specific provider, close, reopen with the SAME provider still present in the list, assert the same provider (and tab index) is selected again without needing to re-pick it.
3. **Overview never auto-switches once loading finishes** — replaces the removed `:81-82` assertion; open on `All` (first open), set `phase = "loading"`, add providers, transition `phase` away from `"loading"` — assert `All` is still selected throughout.

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `contents/ui/ProviderSelector.qml` | Modify | `_hasOpenedBefore` (G1), unconditional `_selectDefault()` (G2), `_pendingDefault` left inert (G3) |
| `tests/ProviderSelectorHarness.qml` | Modify | Trace-derived assertion updates + new dedicated tests (see tables above) |

## Testing Strategy

| Layer | RED anchor | Approach |
|-------|-----------|----------|
| Unit (QML, existing harness, restructured) | Each traced assertion above fails against the still-unmodified `ProviderSelector.qml` before G1-G2 land, for the OLD reason (still resets on every reopen) | `./scripts/run-qml-tests.sh` |
| Unit (QML, new) | New reopen-preserves-specific-provider test fails (RED) before G1 lands — currently the identity would be lost on reopen | `./scripts/run-qml-tests.sh` |
| Unit (QML, new) | New Overview-never-auto-switches test fails (RED) before G2 lands — currently `pending=true` auto-switches once loading finishes | `./scripts/run-qml-tests.sh` |
| Static (lint) | `./scripts/lint-qml.sh` | `./scripts/lint-qml.sh` |
| Manual (gating) | Breeze Light + Dark `plasmawindowed` smoke: first open lands on Overview, picking a provider then closing/reopening the popup returns to that same provider, Overview never silently swaps away once data loads | `docs/live-plasma-smoke.md` |

## Migration / Rollout

No migration, no CLI/model/schema change. Single work unit — the production fix is two small edits; the bulk of the diff is test restructuring, which carries no runtime risk.
