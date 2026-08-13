# Tasks: Compact All-Provider Usage Bars

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 180–260 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | single PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Representative selector + summary-mode components + All wiring + smoke docs | PR 1 | `./scripts/run-qml-tests.sh` | Manual live-Plasma smoke per `docs/live-plasma-smoke.md` (plasmawindowed6 / `QT_QUICK_BACKEND=software`) | `contents/code/UsageModel.js`, `contents/ui/{main,ProviderRow,UsageWindowRow}.qml`, modified test harnesses, `docs/live-plasma-smoke.md` — revert together; CLI/lifecycle/provider tabs unaffected |

## Phase 1: Representative Selector (RED → GREEN → REFACTOR)

- [x] 1.1 RED: Add failing `tests/UsageModelTest.qml` cases asserting `UsageModel.selectRepresentate(windows)` returns the Session window when Session/Weekly/Monthly are all finite (spec: "Session is representative")
- [x] 1.2 RED: Add failing cases for Weekly fallback (Session non-finite), Monthly-only finite, and no-finite → `null`; cover missing, string, `NaN`, `Infinity` ignored (spec: "Representative fallback order", "Monthly is the only finite window", "Provider has no finite percentage")
- [x] 1.3 GREEN: Implement `selectRepresentative(windows)` in `contents/code/UsageModel.js` iterating `windowDefinitions` (primary→secondary→tertiary) with `finiteNumber` gate; return original window or `null`, clone/fabricate nothing
- [x] 1.4 REFACTOR: Share the finite-iterate guard with `selectCompact`; run `./scripts/run-qml-tests.sh` and confirm all green

## Phase 2: Summary-mode QML Components (RED → GREEN → REFACTOR)

- [x] 2.1 RED: Extend `tests/ProviderRowHarness.qml` — `summary` renders exactly one bar+percentage when a finite window exists, identity-only (no bar) when none, no disclosure/expansion control, detail rows unchanged, narrow-panel elision (spec: heterogeneous, identity-only, not expandable)
- [x] 2.2 RED: Extend harness assertions for `UsageWindowRow.summary` — summary shows label+percentage+native `QQC2.ProgressBar`, hides reset fields; `summary:false` keeps reset lines visible
- [x] 2.3 GREEN: Add `property bool summary: false` to `contents/ui/ProviderRow.qml`; when `summary`, render identity and a zero-or-one Repeater over `UsageModel.selectRepresentative(root.windows)`; preserve icon, source, accessibility, non-interactive structure
- [x] 2.4 GREEN: Add `property bool summary: false` to `contents/ui/UsageWindowRow.qml`; summary keeps progress component active (label+percentage+`QQC2.ProgressBar`) and hides `resetsAtLabel`/`resetDescriptionLabel`; keep existing `compact` bar-hiding semantics intact for `CompactUsageButton`
- [x] 2.5 REFACTOR: Remove bar-hiding `compact:true` overload from the `All` path; run `./scripts/run-qml-tests.sh`

## Phase 3: Integration & Wiring

- [x] 3.1 RED: Extend `tests/MainCompactHarness.qml` — per-provider representative summaries coexist with unchanged global `selectCompact()` panel selection and retained snapshots
- [x] 3.2 GREEN: In `contents/ui/main.qml`, set `summary: true` (not legacy `compact:true`) on the `All` Repeater delegate; keep selected-provider tab `summary: false`; `CompactUsageButton` and `compactSelection` unchanged
- [x] 3.3 Run `./scripts/run-qml-tests.sh` end-to-end; confirm green and no CLI/lifecycle/provider-tab regressions

## Phase 4: Docs & Cleanup

- [x] 4.1 Update `docs/live-plasma-smoke.md`: replace the obsolete no-bar compact check with one-bar-per-provider, identity-only, non-expansion, narrow-elision, and Breeze Light/Dark readability checks
- [x] 4.2 Run `git diff --check`; verify provider tabs still show every Session/Weekly/Monthly window with exact raw resets (spec: "Full detail remains in provider tab")