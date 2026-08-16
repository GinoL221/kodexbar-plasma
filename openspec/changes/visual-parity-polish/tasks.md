# Tasks: Visual Parity Polish

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | 300-420 (goldens excluded) |
| 400-line budget risk | Medium (PR 3 highest: ~8 files touched) |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 → PR 2 → PR 3 → PR 4 → PR 5 → PR 6 |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: Medium

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | UsageWindowRow restructure (D1-D3) | PR 1 → main | `./scripts/run-qml-tests.sh` | `tests/ProviderRowHarness.qml` | `UsageWindowRow.qml` + harness only |
| 2 | ProviderHeader two-column (D4-D5) | PR 2 → main after PR 1 | `./scripts/run-qml-tests.sh` | `tests/ProviderDetailsIntegrationTest.qml` | `ProviderHeader.qml` + integration test assertions |
| 3 | Overview mode: Session+Weekly bars together (D10-D13) | PR 3 → main after PR 2 | `./scripts/run-qml-tests.sh` | `tests/ProviderRowHarness.qml`, `tests/ProviderSelectorHarness.qml` | `UsageModel.selectOverviewWindows`, `ProviderRow.qml`, `ProviderHeader.qml` detail gate, `ProviderSelector.qml` tab-0 rename, `main.qml` binding drop |
| 4 | ProviderSelector tab-percent (D6) | PR 4 → main after PR 3 | `./scripts/run-qml-tests.sh` | `tests/ProviderSelectorHarness.qml` | `ProviderSelector.qml` + `main.qml` binding |
| 5 | CostSection typography + StatusFooter (D7-D9) | PR 5 → main after PR 4 | `./scripts/run-qml-tests.sh` | `tests/ProviderDetailsIntegrationTest.qml` | `CostSection.qml`, `StatusFooter.qml`, `main.qml` mount |
| 6 | Golden regeneration + smoke | PR 6 → main after PR 5 | `./scripts/run-visual-tests.sh` | Docker `ci/visual-regression.Dockerfile`; Breeze Light/Dark smoke | Goldens + `docs/ui-parity-checklist.md` only |

## Phase 1: UsageWindowRow Restructure (PR 1)

- [x] 1.1 RED: Update `tests/ProviderRowHarness.qml` — assert bar spans full row width, `windowLabel` stays within `implicitWidth`, and band shows verbatim `resetDescription` / fallback `Reset: {resetsAt}` / percent-only per D2-D3; run `./scripts/run-qml-tests.sh`, confirm failure.
- [x] 1.2 GREEN: Restructure `contents/ui/UsageWindowRow.qml` into `ColumnLayout` (title → full-width `ProgressBar` → metrics `RowLayout`) per D1-D3; preserve all existing aliases and `objectName: "paceSummaryLabel"`.
- [x] 1.3 Verify `./scripts/run-qml-tests.sh` passes.

## Phase 2: ProviderHeader Two-Column (PR 2)

- [x] 2.1 RED: Update `tests/ProviderDetailsIntegrationTest.qml` — assert right-column badge visible/right-aligned when `validLoginMethod` passes, absent (no placeholder) when invalid/absent, left column unaffected; run tests, confirm failure.
- [x] 2.2 GREEN: Restructure `contents/ui/ProviderHeader.qml` into left `ColumnLayout` (identity/source/version/email/org/updated) + right badge `ColumnLayout` (`Qt.AlignTop | Qt.AlignRight`) per D4-D5; preserve all seven `objectName`s.
- [x] 2.3 Verify `./scripts/run-qml-tests.sh` passes.

## Phase 3: Overview Mode (PR 3)

- [ ] 3.1 RED: Add `selectOverviewWindows` cases to `tests/UsageModelTest.qml` — Session+Weekly both finite → 2 in Session-then-Weekly order regardless of payload order, Session-only → 1, Weekly-only → 1, Monthly-only → 1, none finite → `[]`; run tests, confirm failure.
- [ ] 3.2 GREEN: Implement `UsageModel.selectOverviewWindows(windows)` in `contents/code/UsageModel.js` (D10), additive only; confirm existing `test_selectRepresentative*` cases stay green.
- [ ] 3.3 RED: Rewrite `tests/ProviderRowHarness.qml` summary-mode assertions — replace `:392`/`:412` `countProgressBars(summaryRow) === 1` and `:411`/`:413` `preferredWindowKey`/`representativeWindow.label` with 2-bar (Session+Weekly), 1-bar (single-finite/Monthly-only), 0-bar (identity-only) assertions, plus a new "summary row never shows `loginLabel`" assertion (D12); confirm failure.
- [ ] 3.4 GREEN: Update `contents/ui/ProviderRow.qml` — `displayedWindows` uses `selectOverviewWindows` in summary mode (D11); remove `representativeWindow`/`preferredWindowKey` entirely.
- [ ] 3.5 GREEN: Gate `contents/ui/ProviderHeader.qml`'s badge column AND `versionLabel` on `detailed` (D12).
- [ ] 3.6 GREEN: Drop the summary `Repeater`'s `preferredWindowKey` binding in `contents/ui/main.qml` (D11).
- [ ] 3.7 RED: Extend `tests/ProviderSelectorHarness.qml:93-94` — assert tab 0 has `text === "Overview"`, `icon.name === "view-grid"`, and an `Accessible.name` naming Overview; confirm failure.
- [ ] 3.8 GREEN: Rename tab 0 in `contents/ui/ProviderSelector.qml` — label/icon/`Accessible.name` to Overview/`view-grid` (D13); internal identifiers (`allSelected` etc.) stay unchanged.
- [ ] 3.9 Verify `./scripts/run-qml-tests.sh` passes.

## Phase 4: ProviderSelector Tab-Percent (PR 4)

- [ ] 4.1 RED: Update `tests/ProviderSelectorHarness.qml` — tab text/`Accessible.name` contains representative percent when finite, omits it otherwise; run tests, confirm failure.
- [ ] 4.2 GREEN: Add `preferredWindowKey` property (default `"automatic"`), import `UsageModel.js`, compute tab percent via `selectRepresentative` in `contents/ui/ProviderSelector.qml`.
- [ ] 4.3 GREEN: Bind `preferredWindowKey` from `contents/ui/main.qml` into `ProviderSelector`.
- [ ] 4.4 Verify `./scripts/run-qml-tests.sh` passes.

## Phase 5: CostSection + StatusFooter (PR 5)

- [ ] 5.1 RED: Extend `tests/ProviderDetailsIntegrationTest.qml` with footer scenarios — status/last-updated shown, `Overview` omits updated-at, no count/Settings/About/Quit/Add-Account control; confirm failure (footer absent).
- [ ] 5.2 GREEN: Apply typography/density polish to `contents/ui/CostSection.qml`; `objectName`s unchanged.
- [ ] 5.3 GREEN: Create `contents/ui/StatusFooter.qml` — read-only phase/status + `validUpdatedAt` (omitted for `Overview`, D9); no threshold color (D7 out of scope).
- [ ] 5.4 GREEN: Mount `StatusFooter` as last item of outer `ColumnLayout` in `contents/ui/main.qml`, below `ScrollView`.
- [ ] 5.5 Verify `./scripts/run-qml-tests.sh` passes; confirm footer isn't duplicate noise against the existing phase label (Open Question).

## Phase 6: Golden Regeneration and Smoke (PR 6)

- [ ] 6.1 Build `docker build -f ci/visual-regression.Dockerfile -t kodexbar-visual-local:test .`.
- [ ] 6.2 Run `docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -e UPDATE_GOLDENS=1 --volume "$PWD:/workspace" --workdir /workspace kodexbar-visual-local:test ./scripts/run-visual-tests.sh` to regenerate `tests/visual/goldens/*.png`.
- [ ] 6.3 Re-run the same command without `UPDATE_GOLDENS` to prove convergence.
- [ ] 6.4 Perform Breeze Light/Dark manual smoke per `docs/live-plasma-smoke.md`.
- [ ] 6.5 Update `docs/ui-parity-checklist.md` with the verification record.
