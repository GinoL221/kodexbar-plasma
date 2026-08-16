# Tasks: Visual Parity Polish

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | 300-420 (goldens excluded) |
| 400-line budget risk | Medium |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 → PR 2 → PR 3 → PR 4 → PR 5 |
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
| 3 | ProviderSelector tab-percent (D6) | PR 3 → main after PR 2 | `./scripts/run-qml-tests.sh` | `tests/ProviderSelectorHarness.qml` | `ProviderSelector.qml` + `main.qml` binding |
| 4 | CostSection typography + StatusFooter (D7-D9) | PR 4 → main after PR 3 | `./scripts/run-qml-tests.sh` | `tests/ProviderDetailsIntegrationTest.qml` | `CostSection.qml`, `StatusFooter.qml`, `main.qml` mount |
| 5 | Golden regeneration + smoke | PR 5 → main after PR 4 | `./scripts/run-visual-tests.sh` | Docker `ci/visual-regression.Dockerfile`; Breeze Light/Dark smoke | Goldens + `docs/ui-parity-checklist.md` only |

## Phase 1: UsageWindowRow Restructure (PR 1)

- [x] 1.1 RED: Update `tests/ProviderRowHarness.qml` — assert bar spans full row width, `windowLabel` stays within `implicitWidth`, and band shows verbatim `resetDescription` / fallback `Reset: {resetsAt}` / percent-only per D2-D3; run `./scripts/run-qml-tests.sh`, confirm failure.
- [x] 1.2 GREEN: Restructure `contents/ui/UsageWindowRow.qml` into `ColumnLayout` (title → full-width `ProgressBar` → metrics `RowLayout`) per D1-D3; preserve all existing aliases and `objectName: "paceSummaryLabel"`.
- [x] 1.3 Verify `./scripts/run-qml-tests.sh` passes.

## Phase 2: ProviderHeader Two-Column (PR 2)

- [x] 2.1 RED: Update `tests/ProviderDetailsIntegrationTest.qml` — assert right-column badge visible/right-aligned when `validLoginMethod` passes, absent (no placeholder) when invalid/absent, left column unaffected; run tests, confirm failure.
- [x] 2.2 GREEN: Restructure `contents/ui/ProviderHeader.qml` into left `ColumnLayout` (identity/source/version/email/org/updated) + right badge `ColumnLayout` (`Qt.AlignTop | Qt.AlignRight`) per D4-D5; preserve all seven `objectName`s.
- [x] 2.3 Verify `./scripts/run-qml-tests.sh` passes.

## Phase 3: ProviderSelector Tab-Percent (PR 3)

- [ ] 3.1 RED: Update `tests/ProviderSelectorHarness.qml` — tab text/`Accessible.name` contains representative percent when finite, omits it otherwise; run tests, confirm failure.
- [ ] 3.2 GREEN: Add `preferredWindowKey` property (default `"automatic"`), import `UsageModel.js`, compute tab percent via `selectRepresentative` in `contents/ui/ProviderSelector.qml`.
- [ ] 3.3 GREEN: Bind `preferredWindowKey` from `contents/ui/main.qml` into `ProviderSelector`.
- [ ] 3.4 Verify `./scripts/run-qml-tests.sh` passes.

## Phase 4: CostSection + StatusFooter (PR 4)

- [ ] 4.1 RED: Extend `tests/ProviderDetailsIntegrationTest.qml` with footer scenarios — status/last-updated shown, `All` omits updated-at, no count/Settings/About/Quit/Add-Account control; confirm failure (footer absent).
- [ ] 4.2 GREEN: Apply typography/density polish to `contents/ui/CostSection.qml`; `objectName`s unchanged.
- [ ] 4.3 GREEN: Create `contents/ui/StatusFooter.qml` — read-only phase/status + `validUpdatedAt` (omitted for `All`, D9); no threshold color (D7 out of scope).
- [ ] 4.4 GREEN: Mount `StatusFooter` as last item of outer `ColumnLayout` in `contents/ui/main.qml`, below `ScrollView`.
- [ ] 4.5 Verify `./scripts/run-qml-tests.sh` passes; confirm footer isn't duplicate noise against the existing phase label (Open Question).

## Phase 5: Golden Regeneration and Smoke (PR 5)

- [ ] 5.1 Build `docker build -f ci/visual-regression.Dockerfile -t kodexbar-visual-local:test .`.
- [ ] 5.2 Run `docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -e UPDATE_GOLDENS=1 --volume "$PWD:/workspace" --workdir /workspace kodexbar-visual-local:test ./scripts/run-visual-tests.sh` to regenerate `tests/visual/goldens/*.png`.
- [ ] 5.3 Re-run the same command without `UPDATE_GOLDENS` to prove convergence.
- [ ] 5.4 Perform Breeze Light/Dark manual smoke per `docs/live-plasma-smoke.md`.
- [ ] 5.5 Update `docs/ui-parity-checklist.md` with the verification record.
