# Design: Compact Icon Only

## Technical Approach

`contents/ui/CompactUsageButton.qml` (44 lines) already has an `icon`-plus-`Label` `contentItem: RowLayout`. This change removes the `Label` and enlarges the icon, keeping `usageText` and its `Accessible.name`/`Accessible.description` bindings (both computed from `usageText` directly, not from the removed visible `Label`) fully intact.

## Architecture Decisions

| # | Decision | Alternatives rejected | Rationale |
|---|----------|-----------------------|-----------|
| F1 | **Delete the `PlasmaComponents.Label` child entirely** from `contentItem`'s `RowLayout`, rather than hiding it (`visible: false`) | `visible: false` on the Label | An invisible-but-present Label with `Layout.maximumWidth` still occupies a `RowLayout` slot conceptually and is dead code going forward — deleting it is cleaner since there's no plan to bring it back conditionally |
| F2 | **Icon grows from `Kirigami.Units.iconSizes.small` (16px) to `Kirigami.Units.iconSizes.smallMedium` (22px)** | A larger fixed px value; `iconSizes.medium` (32px, likely too large for a panel button) | `smallMedium` is already this codebase's established floor for "user-facing" icon size elsewhere (`ProviderSelectorHarness.qml:149`'s existing assertion on provider tab icons uses this exact constant as the minimum) — reusing it keeps icon-size vocabulary consistent across the app rather than inventing a new magic size |
| F3 | **`usageText` property and its `Accessible.name`/`Accessible.description` bindings are untouched** | Removing `usageText` entirely since nothing displays it anymore | The property is still consumed by accessible-name text (`"KodexBar usage: %1. Open details."`), which is independent of whether a visible `Label` renders it — removing it would silently regress screen-reader support |

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `contents/ui/CompactUsageButton.qml` | Modify | Remove Label (F1), enlarge icon (F2) |
| `tests/CompactUsageButtonHarness.qml` | Verify only | Confirm no assertion depends on the visible Label (current assertions only check `Accessible.name`, focus, and click activation — should need no change, but verify) |

## Testing Strategy

| Layer | Approach |
|-------|----------|
| Unit (QML, existing harness) | Re-run `tests/CompactUsageButtonHarness.qml` unmodified first to confirm none of its existing assertions reference the removed Label; if one does, update it minimally |
| Static (lint) | `./scripts/lint-qml.sh` |
| Manual (gating) | Breeze Light + Dark `plasmawindowed` smoke: icon-only panel button, visually comparable size to neighboring system-tray icons |

## Migration / Rollout

No migration. Single tiny work unit.
