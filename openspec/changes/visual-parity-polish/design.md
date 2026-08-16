# Design: Visual Parity Polish

## Technical Approach

Pure view-layer restructure of five QML files plus one new presentational component. No `UsageController`, `CostController`, `UsageModel.js`, `ProviderDetails.js` or CLI surface is touched: every value rendered already exists on `providerData` / `snapshot` / `controller.phase`. Layout uses `Kirigami.Units` and `Kirigami.Theme` exclusively.

Delivered as five chained work units in the order of the proposal, goldens regenerated once in unit 5.

## Architecture Decisions

| # | Decision | Alternatives rejected | Rationale |
|---|----------|-----------------------|-----------|
| D1 | `UsageWindowRow` becomes `ColumnLayout`: title row → full-width `ProgressBar` → metrics `RowLayout` (`percentageLabel` left, spacer, reset side right — `resetDescriptionLabel` when non-empty, else `resetsAtLabel`, per D2) | Keep single row and only re-weight columns | Only a vertical split gives the bar full width; percent/reset read as one band |
| D2 | Band's reset side prefers the verbatim CLI `resetDescription` when non-empty; falls back to the existing verbatim `"Reset: %1"` (`resetsAt`) text only when `resetDescription` is absent; no wording is ever prepended by QML | Always render raw `resetsAt`; render literal `"Resets in {resetDescription}"` | Raw `resetsAt` is a legibility regression (an ISO timestamp) when a friendlier CLI string already exists; prepending literal "Resets in " duplicates wording for providers whose `resetDescription` already starts with "Resets" (confirmed in `tests/fixtures/codexbar-usage-capture.json`: claude's `"Resets7:50pm(Redacted/Timezone)"`, gemini's `"Resets in 23h 59m"`) — both values are used verbatim, so no time computation occurs either way |
| D3 | Empty-`resetsAt` band shows `percentageLabel` only; the spacer absorbs the width | Placeholder dash / reserved column | Proposal requires no placeholder; existing `visible` binding already fails closed |
| D4 | `ProviderHeader` becomes icon + left `ColumnLayout` (provider/source/version/email/org/updated) + right badge `ColumnLayout` (`loginLabel`), `Layout.alignment: Qt.AlignTop \| Qt.AlignRight` | Separate `PlanBadge.qml` component | Badge is one existing label re-parented; a new file would duplicate `validLoginMethod` gating |
| D5 | Badge visibility stays `ProviderDetailsLogic.validLoginMethod(...).length > 0`; invalid/absent omits the whole right column | New `plan` field lookup | No CLI-backed `plan` field exists; reusing the validator keeps the fail-closed contract |
| D6 | Tab percent from `UsageModel.selectRepresentative(provider.windows, preferredWindowKey)`, with a new `preferredWindowKey` property on `ProviderSelector` bound from `main.qml` | Hardcode `"automatic"`; compute a per-provider max in QML | Reuses existing model logic and makes the tab percent identical to the All-row percent for the same provider |
| D7 | Threshold color is **not** implemented (bar keeps default theme paint) | Semantic `Kirigami.Theme` color ramp | Explicitly out of scope; deferred to a future change |
| D8 | New `contents/ui/StatusFooter.qml`, read-only, placed as the last item of the **outer** `ColumnLayout` in `main.qml` (below the `ScrollView`) | Inside the scroll column; extending `ErrorSummary` | Footer must stay pinned and visibly non-scrolling chrome; a new file keeps `main.qml` from growing |
| D9 | Footer timestamp is the selected provider's CLI `validUpdatedAt`; absent for `All` | Add `lastUpdatedAt` to `UsageController` | Controller changes are out of scope and a QML clock would fabricate a metric |

## Data Flow

    codexbar usage --json-only ──→ UsageController.committedProviders
         │
         ├─→ ProviderSelector ──(selectRepresentative)──→ tab label "name 42%"
         ├─→ ProviderRow ──→ ProviderHeader (left identity | right login badge)
         │                └─→ UsageWindowRow (title / bar / percent | reset)
         └─→ StatusFooter (controller.phase + validUpdatedAt) — read only

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `contents/ui/UsageWindowRow.qml` | Modify | Column restructure (D1–D3); aliases `windowLabel`, `percentageLabel`, `resetsAtLabel`, `resetDescriptionLabel`, `progressBar` and `objectName: "paceSummaryLabel"` all **preserved** |
| `contents/ui/ProviderHeader.qml` | Modify | Two-column split (D4–D5); all seven `objectName`s **preserved**, only parenting changes |
| `contents/ui/ProviderSelector.qml` | Modify | Tab text gains percent (D6); new `preferredWindowKey` property; `UsageModel.js` import added; `Accessible.name` gains percent |
| `contents/ui/CostSection.qml` | Modify | Typography/density only; `objectName`s unchanged |
| `contents/ui/StatusFooter.qml` | Create | Informational status + updated-at line (D8–D9) |
| `contents/ui/main.qml` | Modify | Bind `preferredWindowKey` into `ProviderSelector`; mount `StatusFooter` |
| `tests/ProviderRowHarness.qml` | Modify | RED-first geometry updates (see Testing) |
| `tests/ProviderSelectorHarness.qml` | Modify | RED-first tab-percent assertions |
| `tests/ProviderDetailsIntegrationTest.qml` | Modify | RED-first badge placement assertions |
| `tests/visual/goldens/*.png` | Modify | Regenerated once, unit 5 |
| `docs/ui-parity-checklist.md` | Modify | Verification record |

`ProviderDetailsIntegrationTest` and `VisualCaptureHarness` locate nodes by recursive `objectName` search, so re-parenting alone is assertion-safe; only value/visibility assertions change.

## Interfaces / Contracts

`ProviderSelector` gains one input, mirroring `ProviderRow`:

```qml
property string preferredWindowKey: "automatic"
```

## Testing Strategy

| Layer | What to test | Approach |
|-------|--------------|----------|
| Unit (QML) | `ProviderRowHarness.qml` breaks on the restructure: `progressBar.width > windowLabel.width` (bar and full-width title become equal) and `windowLabel.width <= windowLabel.implicitWidth` (title no longer elides). Rewrite RED-first to assert bar spans row width and the metrics band stays in bounds | `./scripts/run-qml-tests.sh` |
| Unit (QML) | `ProviderSelectorHarness.qml`: tab text contains the representative percent; no percent when no finite window | `./scripts/run-qml-tests.sh` |
| Integration | `ProviderDetailsIntegrationTest.qml`: `loginLabel` visible and right-aligned when valid, absent when invalid/malicious; `updatedAtLabel` unchanged | `./scripts/run-qml-tests.sh` |
| Visual | 4 scenarios (`breeze-{light,dark}-cost-{present,absent}`) | Unit 5 only: `docker build -f ci/visual-regression.Dockerfile -t kodexbar-visual-local:test .` then `docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -e UPDATE_GOLDENS=1 --volume "$PWD:/workspace" --workdir /workspace kodexbar-visual-local:test ./scripts/run-visual-tests.sh`, then re-run without `UPDATE_GOLDENS` to prove convergence |
| Manual | Breeze Light/Dark smoke, `docs/ui-parity-checklist.md` | `docs/live-plasma-smoke.md` |

## Threat Matrix

N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary. All five units are QML view files reading already-validated model output.

## Migration / Rollout

No migration required. Each unit is one revertible PR; goldens restore from the prior commit.

## Open Questions

- [x] Resolved: D2 was corrected after checking `tests/fixtures/codexbar-usage-capture.json` — the band's reset side shows verbatim `resetDescription` when present (falls back to verbatim `Reset: {resetsAt}` when absent), never a literal "Resets in" prefix added by QML. `specs/provider-usage-display/spec.md`'s "Usage window row band layout" requirement reflects this.
- [ ] `main.qml` already renders a phase label above the data. Confirm the footer status line is not read as duplicate noise during the checklist pass; if it is, the footer keeps only updated-at.
