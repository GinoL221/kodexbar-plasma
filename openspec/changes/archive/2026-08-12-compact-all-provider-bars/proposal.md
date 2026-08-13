# Proposal: Compact All-Provider Usage Bars

## Intent

Make the popup's `All` view scannable by showing one representative usage bar per provider instead of repeating every usage window. Users can compare providers at a glance while retaining complete Session, Weekly, Monthly, and reset details in the existing provider tabs.

## Scope

### In Scope
- Render one `All` row per provider with logo, name, source, and a representative bar when available.
- Select the first finite percentage in Session, then Weekly, then Monthly order.
- Preserve provider identity without a bar or invented percentage when no finite value exists.
- Add strict-TDD coverage and live-Plasma smoke checks for representative selection and compact layout.

### Out of Scope
- Expandable rows or inline full details in `All`.
- Changes to provider tabs, lifecycle, fetching, CLI arguments, or the external `codexbar` boundary.
- New status messages, fabricated percentages, or provider/auth behavior.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `provider-usage-display`: Define `All` as one representative provider summary while preserving complete detail in provider tabs and finite-value rules.

## Approach

Add a pure representative-selection helper to `UsageModel.js`, reusing the established window order and finite-value gating. Update the `All` rendering path in `main.qml` and, if needed, the existing `ProviderRow`/`UsageWindowRow` composition to display one native `QQC2.ProgressBar` per provider. Keep detailed rows unchanged. Extend QML harnesses before or alongside production changes, then update the live-Plasma smoke checklist. Use existing Plasma 6/Kirigami components, theme styling, elision, and bounded layout behavior.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/code/UsageModel.js` | Modified | Representative finite-window selection. |
| `contents/ui/main.qml`, `ProviderRow.qml`, `UsageWindowRow.qml` | Modified | Compact `All` presentation with one bar or identity-only row. |
| `tests/ProviderRowHarness.qml`, `tests/MainCompactHarness.qml` | Modified | Selection, fallback, and rendering coverage. |
| `docs/live-plasma-smoke.md` | Modified | Compact All and Breeze readability checks. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Missing/non-finite values render incorrectly | Med | Explicit null, nonnumeric, and non-finite tests; identity-only fallback. |
| Narrow or themed bar is unreadable | Med | Bounded native layout plus Light/Dark smoke validation. |

## Rollback Plan

Revert the proposal's implementation and spec delta; the prior all-windows compact rendering remains available without CLI or lifecycle migration.

## Dependencies

- Existing provider usage model, QML harnesses, and `./scripts/run-qml-tests.sh`.

## Success Criteria

- [ ] `All` shows exactly one representative row per provider using the confirmed fallback order.
- [ ] Providers without finite percentages show identity only; tabs retain all details.
- [ ] Strict-TDD tests and `./scripts/run-qml-tests.sh` pass, with no CLI/lifecycle changes.
