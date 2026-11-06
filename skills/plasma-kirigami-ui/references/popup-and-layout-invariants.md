# Popup and Layout Invariants

Reference guide for Plasma 6 QML popup information hierarchy, `UsageWindowRow` anatomy, standardized reset countdowns, and QML/test invariants.

## 1. Popup Information Order

When extending the full representation, preserve this selected-provider order unless an SDD change explicitly revises it:

1. Provider tabs (`All` + usable providers)
2. Header (name, updated, plan/login, account email, human-readable org only)
3. Usage windows with optional pace lines
4. Credits remaining (when valid)
5. Reset-credit inventory only when `availableCount` > 0 (count + expandable expirations; no redeem)
6. Cost section only for selected supported providers with a valid CLI cost snapshot
7. Collapsed-by-default `usage.details[]`
8. Global error summary
9. Plasma-native chrome (refresh / configure) — no Auth, Add Account, or Quit

`All` stays a compact summary: no email, org, pace, credits, reset inventory, or cost.

## 2. UsageWindowRow Anatomy

`UsageWindowRow` renders either an overview summary or a detailed window view based on `root.summary`:

### Overview (`summary: true`)
Single-line layout:
`windowLabel | summaryBar | % used` (the percentage color reflects the usage threshold; there is no separate marker).

### Detail (`summary: false`)
Header row above full-width progress bar:
- **Header row**:
  - `windowLabel` on the left with `Layout.fillWidth: true` and `Layout.minimumWidth: root.summary ? 0 : Kirigami.Units.gridUnit`.
  - `detailResetContainer` (`visible: !root.summary`) holds `resetsAtLabel` and `resetDescriptionLabel`, while `bandPercentageLabel` is a direct child of `titleRow`.
- **Progress bar**:
  - Full-width `detailBarHost` positioned below the header row.
- **Pace line**:
  - Optional `paceSummaryLabel` below the progress bar.

## 3. Standardized Reset Countdowns (`ResetTimeFormatter.js`)

A future parseable `resetsAt` takes precedence over English descriptions such as `Resets in 4h 56m`, `2 hours, 20 minutes`, `tomorrow, 12:45 AM`, `Nov 10 at 5:24 PM`, or `Dec 3`. Parseable descriptions are used when the timestamp is missing, past, or invalid. The detail row refreshes its clock every minute while visible. Countdown formats include:
- **English**: `Resets in Xd Yh` or `Resets in Xh Ym`
- **Spanish**: `Se reinicia en X d Y h` or `Se reinicia en X h Y min`
- **Fallback**: An unparseable description goes through reset translation; without a description, a past or invalid timestamp is displayed as `Reset: <value>`.

## 4. QML & Test Invariants

- **`pragma ComponentBehavior: Bound`**:
  `contents/ui/UsageWindowRow.qml` uses bound component behavior.
- **`LAYOUT_POSITIONING_EXCEPTIONS`**:
  `UsageWindowRow.qml` binds the title row's `width: root.width` for synchronous resize behavior; the layout-positioning exception is tracked in `scripts/check-qml-unqualified-baseline.py`.
- **`tests/ProviderRowHarness.qml` Invariants**:
  - `summaryWindowRow.resetsAtLabel.parent.visible === false` in summary mode.
  - `constrainedWindowRow` (`width: 120`): Requires `Layout.minimumWidth: 0` on `windowLabel` and bounded trailing labels so `percentageLabel.paintedWidth <= percentageLabel.width` and `percentageLabel.x + percentageLabel.width <= row.width`.
  - Detail percentage sits above `progressBar` (`percentPos.y < barPos.y`).
- **Offscreen Visual Regression Goldens**:
  Regenerate `tests/visual/goldens/*.png` via `UPDATE_GOLDENS=1 ./scripts/run-visual-tests.sh` in the canonical visual environment when captured output intentionally changes, then run `./scripts/run-visual-tests.sh` without the update flag. Cost-present captures include daily bars and the primary model; cost-absent captures omit the section.
