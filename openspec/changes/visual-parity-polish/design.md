# Design: Visual Parity Polish

## Technical Approach

View-layer restructure of six QML files plus one new presentational component, and one additive pure selector in `UsageModel.js` (D10). No `UsageController`, `CostController`, `ProviderDetails.js`, normalization path, or CLI surface is touched: every value rendered already exists on `providerData` / `snapshot` / `controller.phase`. Layout uses `Kirigami.Units` and `Kirigami.Theme` exclusively.

Delivered as six chained work units (see Migration / Rollout), goldens regenerated once in the final unit.

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
| D10 | New pure `UsageModel.selectOverviewWindows(windows)`: returns finite Session (`key "primary"`) then finite Weekly (`"secondary"`) — always in that order, not payload order — else finite Monthly (`"tertiary"`) alone, else `[]`. Reuses the existing `windowDefinitions`, `isUsableWindow`, `matchesDefinition` helpers exactly like `preferredFiniteWindow` | Filter windows inline in `ProviderRow`; add a "max count" argument to `selectRepresentative` | Window-selection policy already lives in one JS module covered by `UsageModelTest.qml`; matching on definitions (not array index) keeps the four-key contract untouched and makes the Monthly fallback provably exclusive |
| D11 | `ProviderRow.displayedWindows` becomes `summary ? UsageModel.selectOverviewWindows(windows) : windows`; `representativeWindow` and `preferredWindowKey` are **removed** from `ProviderRow`, and `main.qml`'s binding at the summary `Repeater` is dropped | Keep `preferredWindowKey` as an inert property | Spec forbids `preferredRepresentativeWindow` governing Overview; a live-but-ignored input invites silent re-coupling. `main.qml`'s own `preferredWindowKey` (config-backed) stays declared and is re-consumed by `ProviderSelector` in PR 4 (D6) |
| D12 | An Overview "card" is the existing `ProviderHeader` (`detailed: false`) plus 0–2 existing `UsageWindowRow`s (`summary: true`) in the existing `Repeater` — no new component; the header's right badge column AND `versionLabel` additionally gate on `detailed`, so both the plan/login badge and the CLI version string are selected-detail-only | New `ProviderOverviewCard.qml`; a `GridLayout` of cards; leave `versionLabel` ungated | The `Repeater` already renders N rows and `summary: true` already hides reset text, so D1's bar restructure lands in Overview for free. Gating the badge and version extends D5 for summary rows only (selected-detail behavior is unchanged) and matches the existing compact exclusion set (email/org/pace/credits/resets/cost) — a raw CLI version string is extra detail, not identity, and the Overview reference shows only icon+name+bars. A grid breaks the response-ordered single column and Plasma popup width |
| D13 | Tab label `All` → `Overview` with `icon.name: "view-grid"` (verified present in `breeze/actions/{16,22,24}`), plus updated `Accessible.name`/`description`; internal identifiers (`allSelected`, `_allSelected`, `_selectAll`) stay unchanged | Rename internals too; `view-grid-symbolic` | User-facing rename is a string + icon change; renaming internals inflates the diff and risks `main.qml` / `CostRequestPolicy` regressions. `view-grid-symbolic` is not a Breeze `actions` name here |

## Data Flow

    codexbar usage --json-only ──→ UsageController.committedProviders
         │
         ├─→ ProviderSelector ──(selectRepresentative + preferredWindowKey)──→ tab "name 42%"
         │                     └─ tab 0 = "Overview" (view-grid)
         ├─→ ProviderRow (summary) ──(selectOverviewWindows, NO preferredWindowKey)
         │        └─→ ProviderHeader (detailed:false → no badge) + 0–2 UsageWindowRow
         ├─→ ProviderRow (selected) ──→ ProviderHeader (identity | login badge)
         │                            └─→ UsageWindowRow (title / bar / percent | reset)
         └─→ StatusFooter (controller.phase + validUpdatedAt) — read only

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `contents/ui/UsageWindowRow.qml` | Modify | Column restructure (D1–D3); aliases `windowLabel`, `percentageLabel`, `resetsAtLabel`, `resetDescriptionLabel`, `progressBar` and `objectName: "paceSummaryLabel"` all **preserved** |
| `contents/ui/ProviderHeader.qml` | Modify | Two-column split (D4–D5); all seven `objectName`s **preserved**, only parenting changes |
| `contents/code/UsageModel.js` | Modify | PR 3: additive `selectOverviewWindows` only (D10); `normalize`, `selectRepresentative`, `selectCompact` untouched |
| `contents/ui/ProviderRow.qml` | Modify | PR 3: `displayedWindows` via `selectOverviewWindows`; removes `representativeWindow` + `preferredWindowKey` (D11) |
| `contents/ui/ProviderHeader.qml` | Modify | PR 3: badge column gains `root.detailed &&` gate (D12) |
| `contents/ui/ProviderSelector.qml` | Modify | PR 3: tab 0 label/icon/a11y rename to `Overview` + `view-grid` (D13) |
| `contents/ui/main.qml` | Modify | PR 3: drop the summary `Repeater`'s `preferredWindowKey` binding (D11) |
| `tests/UsageModelTest.qml` | Modify | PR 3: RED-first `selectOverviewWindows` unit cases |
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

`UsageModel.js` gains one pure function (D10), returning a 0-, 1-, or 2-element array of the *same* window objects (never copies, never synthesized):

```js
function selectOverviewWindows(windows) // [session?, weekly?] | [monthly] | []
```

## Testing Strategy

| Layer | What to test | Approach |
|-------|--------------|----------|
| Unit (QML) | `ProviderRowHarness.qml` breaks on the restructure: `progressBar.width > windowLabel.width` (bar and full-width title become equal) and `windowLabel.width <= windowLabel.implicitWidth` (title no longer elides). Rewrite RED-first to assert bar spans row width and the metrics band stays in bounds | `./scripts/run-qml-tests.sh` |
| Unit (JS) | **PR 3 RED anchor**: `UsageModelTest.qml` has no `selectOverviewWindows` case. Add five: Session+Weekly both finite → 2 windows in Session-then-Weekly order even when the payload orders them otherwise; Session-only → 1; Weekly-only → 1; Monthly-only → 1; none finite → `[]`. Existing `test_selectRepresentative*` cases must stay green (proves D10 is additive) | `./scripts/run-qml-tests.sh` |
| Unit (QML) | **PR 3 RED anchors** in `ProviderRowHarness.qml`: `:392` and `:412` (`countProgressBars(summaryRow) === 1`) and `:413`/`:411` (`representativeWindow.label`, `preferredWindowKey`) all break by construction. Rewrite RED-first to assert 2 bars / 2 `UsageWindowRow`s for a Session+Weekly fixture, 1 for the single-finite and Monthly-only fixtures, 0 for identity-only, and delete the `preferredWindowKey`/`representativeWindow` assertions (D11). Keep `:394–397` (identity-only), `:404–409` (non-expandable), `:437–442` (no email/cost) green; add "summary row must never show `loginLabel`" (D12) | `./scripts/run-qml-tests.sh` |
| Unit (QML) | **PR 3 RED anchor**: `ProviderSelectorHarness.qml:93–94` asserts tab 0 is a compact icon+label control. Extend RED-first to assert `text === "Overview"`, `icon.name === "view-grid"`, and an `Accessible.name` naming Overview (D13) | `./scripts/run-qml-tests.sh` |
| Unit (QML) | `ProviderSelectorHarness.qml`: tab text contains the representative percent; no percent when no finite window | `./scripts/run-qml-tests.sh` |
| Integration | `ProviderDetailsIntegrationTest.qml`: `loginLabel` visible and right-aligned when valid, absent when invalid/malicious; `updatedAtLabel` unchanged | `./scripts/run-qml-tests.sh` |
| Visual | 4 scenarios (`breeze-{light,dark}-cost-{present,absent}`) | Unit 5 only: `docker build -f ci/visual-regression.Dockerfile -t kodexbar-visual-local:test .` then `docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -e UPDATE_GOLDENS=1 --volume "$PWD:/workspace" --workdir /workspace kodexbar-visual-local:test ./scripts/run-visual-tests.sh`, then re-run without `UPDATE_GOLDENS` to prove convergence |
| Manual | Breeze Light/Dark smoke, `docs/ui-parity-checklist.md` | `docs/live-plasma-smoke.md` |

## Threat Matrix

N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary. Still N/A after the Overview unit: `selectOverviewWindows` is a pure array filter over already-normalized, already-validated windows, and every other unit is a QML view file.

## Migration / Rollout

No migration required. Each unit is one revertible PR; goldens restore from the prior commit.

**PR sequence (renumbered — `tasks.md` must be formally renumbered by `sdd-tasks`):**

| PR | Unit | State |
|----|------|-------|
| 1 | `UsageWindowRow` restructure (D1–D3) | Done, committed |
| 2 | `ProviderHeader` two columns (D4–D5) | Done, committed |
| 3 | **Overview mode (D10–D13) — new, inserted here** | Not started |
| 4 | `ProviderSelector` tab percent (D6) | Not started (was PR 3) |
| 5 | `CostSection` + `StatusFooter` (D7–D9) | Not started (was PR 4) |
| 6 | Goldens + checklist | Not started (was PR 5) |

PR 3 lands before PR 4 so the tab-percent work sees the final tab-0 label/icon and does not re-touch the same `ProviderSelector` lines twice.

## Open Questions

- [x] Resolved: D2 was corrected after checking `tests/fixtures/codexbar-usage-capture.json` — the band's reset side shows verbatim `resetDescription` when present (falls back to verbatim `Reset: {resetsAt}` when absent), never a literal "Resets in" prefix added by QML. `specs/provider-usage-display/spec.md`'s "Usage window row band layout" requirement reflects this.
- [ ] **Verified discrepancy**: the spec says `preferredRepresentativeWindow` "continues to govern the compact-panel effective window", but `UsageModel.selectCompact` (`contents/code/UsageModel.js:146`) takes no preference argument and picks the global maximum. The only live consumer today is the summary row that D11 removes, so between PR 3 and PR 4 the setting governs nothing. Confirm whether the spec sentence should be corrected, or whether `selectCompact` was always meant to honor the preference (a separate change).
- [x] Resolved: user confirmed `versionLabel` should also be selected-detail-only. D12 updated to gate both the login badge and `versionLabel` on `detailed`.
- [ ] `main.qml` already renders a phase label above the data. Confirm the footer status line is not read as duplicate noise during the checklist pass; if it is, the footer keeps only updated-at.
