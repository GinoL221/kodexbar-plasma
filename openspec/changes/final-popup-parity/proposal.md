# Proposal: Final Popup Parity

## Intent

Bring the selected-provider popup closer to CodexBar's final product experience without weakening the existing usage lifecycle or external CLI boundary. Users should see useful provider context—pace, credits, reset availability, identity, organization, and optional cost—while `All` remains a compact, fast summary.

## Scope

### In Scope
- Show approved enrichment only in selected-provider detail: pace, credits, positive reset inventory, supplied email, human-readable organization, and conditional cost.
- Keep tabs compact (icon plus short provider name) and keep cost out of `All` rows.
- Add an isolated provider-keyed cost lifecycle using the exact `codexbar cost` contract, with refresh/selection staleness protection.
- Update contract fixtures, focused QML tests, documentation, and native Plasma/Kirigami presentation.

### Out of Scope
- Auth, Add Account, Quit, redeem/mutation actions, provider implementation, CLI changes, price calculation, or cost diagnostics.
- Any change to the exact all-provider usage invocation, usage ownership, or protected lifecycle semantics.

## Capabilities

### New Capabilities
- `provider-cost-estimate`: Optional, local token-cost estimate for the selected provider, hidden when unavailable or failed.

### Modified Capabilities
- `provider-usage-display`: Authorize narrowly scoped selected-provider identity, organization, pace, credits, reset inventory, and compact-tab presentation while preserving All-summary and runtime boundaries.

## Approach

Keep `UsageController` authoritative for usage. Add a separate `CostController` keyed by provider and usage generation; coalesce duplicate requests and discard stale callbacks. Extend validated presentation extractors without exposing opaque organization IDs or invalid fields. Render reset credits only when `availableCount > 0`, with an expandable expiry list and no mutation. Preserve native Kirigami/Plasma components, keyboard access, theme adaptation, and popup-bounded scrolling.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/ui/main.qml`, `ProviderSelector.qml`, `ProviderRow.qml` | Modified | Popup detail, tabs, cost wiring, and conditional sections |
| `contents/ui/CostController.qml` | New | Optional cost lifecycle |
| `contents/code/ProviderDetails.js` | Modified | Narrow validated extractors |
| `tests/`, `tests/fixtures/`, `docs/cli-contract-capture.md` | Modified/New | RED-first contracts and cost evidence |
| `openspec/specs/provider-usage-display/spec.md` | Modified | Display authorization and boundaries |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Stale or failed cost callback affects usage | Med | Separate controller, provider/generation correlation, stale guards |
| PII or opaque IDs appear | Med | CLI-supplied email only; reject UUID/hex organization values |
| Review scope exceeds 400 lines | Med | Four independently reviewable delivery slices; split on risk |

## Rollback Plan

Revert the proposal's implementation slices and delta spec. Removing the optional cost controller restores the prior usage-only behavior; no persisted usage contract or CLI command migration is required.

## Dependencies

- Verified `codexbar cost` JSON contract and redacted fixture; strict TDD via `./scripts/run-qml-tests.sh`.

## Success Criteria

- [ ] Selected detail shows only valid approved enrichment; unavailable sections disappear safely.
- [ ] Cost never changes usage state and is labeled a local token-cost estimate.
- [ ] Exact usage invocation and lifecycle tests remain green; lint, package validation, and live Plasma smoke pass.
- [ ] Four review slices remain independently understandable within the 400-line budget.
