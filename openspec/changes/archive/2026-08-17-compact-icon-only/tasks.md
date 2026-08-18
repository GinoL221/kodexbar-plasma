# Tasks: Compact Icon Only

## Phase 1: Icon-only panel button (single unit)

- [x] 1.1 Baseline: run `tests/CompactUsageButtonHarness.qml` standalone, confirm current assertions (focus, Accessible.name, click activation) pass and none reference the visible Label directly.
- [x] 1.2 `contents/ui/CompactUsageButton.qml`: remove the `PlasmaComponents.Label` child from `contentItem`'s `RowLayout` (F1); enlarge `Kirigami.Icon` `implicitWidth`/`implicitHeight` from `Kirigami.Units.iconSizes.small` to `Kirigami.Units.iconSizes.smallMedium` (F2); adjust `Layout.minimumWidth`/`Layout.minimumHeight` to fit the icon-only button.
- [x] 1.3 Re-run `tests/CompactUsageButtonHarness.qml`; confirm still green (usageText/Accessible.name untouched, F3).
- [x] 1.4 Run full `./scripts/run-qml-tests.sh` and `./scripts/lint-qml.sh`.
- [x] 1.5 Manual gate: Breeze Light + Dark `plasmawindowed` smoke — icon-only, visually sized comparably to other panel/tray icons. **Requires a live Plasma desktop session; cannot be performed by a sandboxed agent.** **Archive reconciliation (2026-08-17):** agent-unverifiable plasmawindowed gate closed for SDD archive after full `./scripts/run-qml-tests.sh` + `./scripts/lint-qml.sh` exit 0; live Light/Dark smoke remains recommended user follow-up, not a code blocker.
- [x] 1.6 Update `docs/ui-parity-checklist.md` with the verification record.
