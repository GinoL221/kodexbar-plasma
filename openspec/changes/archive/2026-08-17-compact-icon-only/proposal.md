# Proposal: Compact Icon Only

## Intent

The system-tray/panel button currently shows a small (16px) monochrome logo beside a percentage text label. Next to other tray icons it reads visually smaller and busier than its neighbors. Drop the text, show only the logo, and size it up so it matches the visual weight of surrounding tray icons.

## Scope

### In Scope

1. `contents/ui/CompactUsageButton.qml`: remove the visible `PlasmaComponents.Label` (percentage text) from `contentItem`. Enlarge the `Kirigami.Icon` from `Kirigami.Units.iconSizes.small` (16px) to `Kirigami.Units.iconSizes.smallMedium` (22px, already used elsewhere in this codebase as the "user-facing" icon floor — see `ProviderSelectorHarness.qml:149`'s existing assertion on tab icons).
2. Keep the `usageText` property and its `Accessible.name`/`Accessible.description` bindings unchanged — the percentage stays available to screen readers and any other consumer of the property, only the VISIBLE text disappears.
3. `Layout.minimumWidth`/`Layout.minimumHeight` adjust to fit the larger icon-only button (no text to reserve width for).

### Out of Scope

- Changing what drives `usageText` (`root.panelText()` in `main.qml`) — untouched, still computed the same way, just not rendered visually here.
- Any change to the popup content, tabs, or usage windows.
- Panel icon theming beyond size (still `isMask: true` + `Kirigami.Theme.textColor`, unchanged).

## Capabilities

### Modified Capabilities
- `provider-usage-display`: adds a requirement for the compact panel button's visual presentation (icon-only, minimum size), a concern not previously governed by a formal requirement — only informally noted in `docs/ui-parity-checklist.md`'s checklist.

## Approach

Single-file, mechanical layout change. `usageText` stays a real property (screen readers still announce it); only the `contentItem`'s child `Label` is removed, and the icon's `implicitWidth`/`implicitHeight` bump from `iconSizes.small` to `iconSizes.smallMedium`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/ui/CompactUsageButton.qml` | Modified | Remove visible Label, enlarge icon |
| `tests/CompactUsageButtonHarness.qml` | Modified (if needed) | Confirm no assertion depends on the removed visible Label |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Removing the visible percentage loses at-a-glance panel info some users relied on | Low | Explicit user request; `Accessible.name` still carries the percentage for assistive tech, and the full popup is one click away |
| Larger icon doesn't fit some panel heights | Low | `smallMedium` (22px) is already this codebase's established "user-facing" icon floor elsewhere (tab icons) |

## Rollback Plan

Revert the single file — no model/controller/data change.

## Success Criteria

- [ ] Panel button shows only the logo, no percentage text.
- [ ] Icon renders visibly larger than before, matching neighboring tray icons.
- [ ] `usageText`/`Accessible.name` still report the percentage for assistive tech.
- [ ] `run-qml-tests.sh` and `lint-qml.sh` pass; live smoke confirms panel sizing looks right next to other tray icons.
