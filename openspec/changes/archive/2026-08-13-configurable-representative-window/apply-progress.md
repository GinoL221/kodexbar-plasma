# Apply Progress: Configurable Representative Window

## Work Unit

Single PR — resolver + selector + component + settings surface + `main.qml` wiring + docs (Suggested Work Unit 1). Chain strategy: pending (see Risks — actual size exceeds the forecast; a natural two-slice split exists if the maintainer wants to chain instead of accepting `size:exception`).

## Completed Tasks

- [x] 1.1 RED: Create `tests/PreferredWindowHarness.qml`
- [x] 1.2 GREEN: Create `contents/code/PreferredWindow.js`
- [x] 1.3 GREEN: Register `PreferredWindowHarness` in `scripts/run-qml-tests.sh`
- [x] 1.4 Run suite; confirm `PreferredWindowHarness` passes
- [x] 2.1 RED: `test_selectRepresentativeHonoursExplicitPreferredWindow`
- [x] 2.2 RED: `test_selectRepresentativeFallsBackWhenPreferredWindowIsNotFinite`
- [x] 2.3 RED: `test_selectRepresentativePerProviderFallbackIsIndependent`
- [x] 2.4 RED: `test_selectRepresentativeAutomaticMatchesLegacySingleArgument`
- [x] 2.5 RED: `test_selectRepresentativeReturnsNullForNoFiniteWindowUnderAnyPreference`
- [x] 2.6 RED: `test_selectCompactIsUnaffectedByPreferredWindow`
- [x] 2.7 RED: Confirm 3 pre-existing 1-arg cases unmodified/passing; confirm new cases exercise real RED
- [x] 2.8 GREEN: `preferredWindowKeys` map in `UsageModel.js`
- [x] 2.9 GREEN: `definitionForPreferred`/`matchesDefinition`/`preferredFiniteWindow`
- [x] 2.10 GREEN: Extend `selectRepresentative(windows, preferredKey)`
- [x] 2.11 Run suite; confirm all `UsageModelTest.qml` cases green
- [x] 3.1 RED: `preferredWeeklyRow` in `ProviderRowHarness.qml`
- [x] 3.2 RED: `preferredFallbackRow`
- [x] 3.3 RED: `preferredIdentityOnlyRow`
- [x] 3.4 RED: Default `summaryRow.preferredWindowKey === "automatic"` assertion
- [x] 3.5 RED: Reactivity assertion
- [x] 3.6 RED: Styling-parity assertion (`countVisibleUsageDetails`)
- [x] 3.7 Run suite; confirm `ProviderRowHarness` fails (property missing)
- [x] 3.8 GREEN: `property string preferredWindowKey: "automatic"` on `ProviderRow.qml`
- [x] 3.9 GREEN: Update `representativeWindow` binding
- [x] 3.10 Run suite; confirm `ProviderRowHarness` passes
- [x] 4.1 RED: `test_preferredWindowControlIsDiscoverableAndDefaulted`
- [x] 4.2 RED: `test_preferredWindowSelectionPersistsKeys`
- [x] 4.3 RED: `test_preferredWindowIsIndependentFromTimeout`
- [x] 4.4 RED: Extend `test_tabTraversalUsesNativeFocus`
- [x] 4.5 RED: Confirm all 4 new cases fail before GREEN (design risk #1 noted)
- [x] 4.6 GREEN: `main.xml` kcfg entry
- [x] 4.7 GREEN: `configGeneral.qml` aliases/helpers
- [x] 4.8 GREEN: `QQC2.ComboBox` control
- [x] 4.9 GREEN: `PlasmaComponents.Label` guidance
- [x] 4.10 Run suite; confirm all 4 new cases pass; alias round-trip confirmed
- [x] 5.1 GREEN: Import `PreferredWindow.js` in `main.qml`
- [x] 5.2 GREEN: `preferredWindowKey` property in `main.qml`
- [x] 5.3 GREEN: Wire `preferredWindowKey` into `All` summary `ProviderRow` only
- [x] 5.4 Run suite end-to-end; confirm full green, no regressions
- [x] 6.1 Cross-consistency assertion (`PreferredWindow.VALID_KEYS` vs `UsageModel.preferredWindowKeys` vs `configGeneral.qml.preferredWindowKeys`)
- [x] 6.2 Update `docs/live-plasma-smoke.md`
- [x] 6.3 Full suite final run; confirm all green
- [x] 6.4 `git diff --check`; confirm no whitespace errors

**43/43 tasks complete.**

## Files Changed

| File | Action | Lines (+/-) | What Was Done |
|------|--------|------:|---------------|
| `contents/code/PreferredWindow.js` | Created | +21 | `.pragma library` resolver: `DEFAULT_KEY`, `VALID_KEYS`, `parse`, `keyOrDefault`, mirroring `RequestTimeout.js`. |
| `contents/code/UsageModel.js` | Modified | +42/-1 | Added `preferredWindowKeys` map, `definitionForPreferred`, `matchesDefinition`, `preferredFiniteWindow`; extended `selectRepresentative(windows, preferredKey)` with an optional 2nd param. `selectCompact` untouched. |
| `contents/ui/ProviderRow.qml` | Modified | +2/-1 | Added `property string preferredWindowKey: "automatic"`; `representativeWindow` binding now calls `UsageModel.selectRepresentative(root.windows, root.preferredWindowKey)`. |
| `contents/ui/main.qml` | Modified | +3 | Imported `PreferredWindow.js`; added `root.preferredWindowKey` resolved from `Plasmoid.configuration.preferredRepresentativeWindow`; wired into the `All` `Repeater`'s summary `ProviderRow` only. |
| `contents/config/main.xml` | Modified | +3 | New `preferredRepresentativeWindow` String kcfg entry, group `General`, default `automatic`. |
| `contents/ui/config/configGeneral.qml` | Modified | +45 | `cfg_preferredRepresentativeWindow` alias to `preferredWindow.selectedKey`, `preferredWindowKeys` array, index helpers, `QQC2.ComboBox` (appended after the `requestTimeout` `SpinBox`), guidance label (appended after `requestTimeoutGuidanceLabel`). |
| `tests/PreferredWindowHarness.qml` | Created | +83 | Resolver harness (`parse`/`keyOrDefault` full input-domain coverage) plus the Phase 6 cross-consistency assertion against `UsageModel.preferredWindowKeys` and `configGeneral.qml.preferredWindowKeys`. |
| `tests/UsageModelTest.qml` | Modified | +132 | 6 new cases: explicit preference, non-finite fallback, per-provider independence, automatic/1-arg identity equivalence, null-under-any-preference, `selectCompact` unaffected. 3 pre-existing 1-arg cases unmodified. |
| `tests/ProviderRowHarness.qml` | Modified | +66 | 3 new summary rows (`preferredWeeklyRow`, `preferredFallbackRow`, `preferredIdentityOnlyRow`) plus default/reactivity/styling-parity assertions. |
| `tests/SettingsInteractionTest.qml` | Modified | +57/-1 | New `preferredWindowControl`/`preferredWindowGuidance` discovery, 3 new test functions, one appended `Tab` traversal assertion. |
| `scripts/run-qml-tests.sh` | Modified | +1 | Registered `PreferredWindowHarness` in the `qml6 -f` harness list, next to `RequestTimeoutHarness`. |
| `docs/live-plasma-smoke.md` | Modified | +10 | New "Representative window setting" manual-check section. |

## Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test command | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/PreferredWindowHarness.qml` |
| Exact result | Pass, exit code `0`; full `parse`/`keyOrDefault` input-domain coverage plus cross-consistency assertion against `UsageModel` and `configGeneral.qml`. |
| Focused test command | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software /usr/lib/qt6/bin/qmltestrunner -input tests/UsageModelTest.qml -import .` |
| Exact result | Pass, exit code `0`; `Totals: 17 passed, 0 failed, 0 skipped, 0 blacklisted`. |
| Focused test command | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/ProviderRowHarness.qml` |
| Exact result | Pass, exit code `0`; includes reactivity and styling-parity assertions. |
| Focused test command | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software /usr/lib/qt6/bin/qmltestrunner -input tests/SettingsInteractionTest.qml -import .` |
| Exact result | Pass, exit code `0`; `Totals: 11 passed, 0 failed, 0 skipped, 0 blacklisted`. |
| Full runner command | `./scripts/run-qml-tests.sh` |
| Exact result | Pass, exit code `0`. QtTest totals `17 + 16 + 11` passed; all executable harnesses (including `PreferredWindowHarness` and `ProviderRowHarness`) and the exact CLI lifecycle argv assertion passed unchanged. |
| Runtime harness scenario | No live Plasma runtime available in this headless environment. Manual `plasmawindowed` smoke documented in `docs/live-plasma-smoke.md` ("Representative window setting" section) remains pending for a live observer, consistent with prior changes in this repository. |
| `git diff --check` | Pass, exit code `0`; no whitespace errors. |
| Rollback boundary | Revert `contents/code/{PreferredWindow,UsageModel}.js`, `contents/ui/{ProviderRow,main,config/configGeneral}.qml`, `contents/config/main.xml`, `tests/{PreferredWindowHarness,UsageModelTest,ProviderRowHarness,SettingsInteractionTest}.qml`, `scripts/run-qml-tests.sh`, `docs/live-plasma-smoke.md` together. `selectCompact`, provider tabs, and the `codexbar` CLI/lifecycle boundary are untouched and need no rollback. |

## TDD Cycle Evidence (Strict TDD)

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 1.1–1.4 | `tests/PreferredWindowHarness.qml` | QML harness | N/A (new file) | Written; `qml6 -f` exit `2`, "Did not load any objects" — module missing | `PreferredWindow.js` created; harness registered; exit `0` | 10+ input-domain cases (`undefined`, `null`, `""`, casing/whitespace variants, `"yearly"`, `123`, `NaN`, array) | Clean; matches `RequestTimeout.js` pattern exactly |
| 2.1–2.11 | `tests/UsageModelTest.qml` | Unit (pure fn) | 11/11 passing before edit | 6 new cases written; 2 genuinely failed (`test_selectRepresentativeHonoursExplicitPreferredWindow`, `test_selectRepresentativePerProviderFallbackIsIndependent`); 4 passed trivially because they assert automatic/no-op behavior identical before and after (expected — these are approval-style backward-compat proofs) | `preferredWindowKeys`/`definitionForPreferred`/`matchesDefinition`/`preferredFiniteWindow`/extended `selectRepresentative` added; all 17 cases pass | Finite/non-finite/empty fixtures across automatic, explicit, and per-provider scenarios | Clean; no duplication introduced |
| 3.1–3.10 | `tests/ProviderRowHarness.qml` | Integration (QML component) | Prior harness state green before edit | 3 new rows + 4 assertion blocks written; `qml6 -f` exit `2` — `preferredWindowKey` property missing | `property string preferredWindowKey: "automatic"` + binding update; exit `0` | Explicit-finite, fallback, identity-only, reactivity, styling-parity cases | Clean; reused existing `countProgressBars`/`countUsageWindowRows`/`countVisibleUsageDetails` helpers |
| 4.1–4.10 | `tests/SettingsInteractionTest.qml` | Integration (QML settings page) | 8/8 passing before edit | 4 new cases + control/guidance discovery written; `initTestCase` failed — control not discoverable | kcfg entry + `configGeneral.qml` `ComboBox`/aliases/guidance added; `Totals: 11 passed, 0 failed` | Default/discoverability, keyboard+mouse selection across all 3 explicit keys, independence from timeout/refresh, tab order | One deviation required — see below |
| 5.1–5.4 | N/A (plumbing) | Integration | Full suite green before edit | N/A — pure wiring task, no new test surface | `main.qml` import/property/wiring added; full suite `exit 0` | N/A | Clean |
| 6.1 | `tests/PreferredWindowHarness.qml` | Unit + component instantiation | Harness green before edit | Cross-consistency assertion written referencing `UsageModel.preferredWindowKeys` and `configGeneral.qml.preferredWindowKeys` (both already implemented, so this is an approval-style regression guard, not a RED-then-GREEN pair) | Passed on first run, exit `0` | N/A — structural drift guard, single expected outcome | Clean |
| 6.2 | `docs/live-plasma-smoke.md` | Manual documentation | N/A | N/A — documentation only | N/A | N/A — new "Representative window setting" section covers Automatic/Weekly/Monthly, fallback, identity-only, panel badge, and Breeze themes | Clean |

### Test Summary
- **Total tests written**: 6 (`UsageModelTest.qml`) + 4 (`SettingsInteractionTest.qml`) + 1 resolver harness (`PreferredWindowHarness.qml`, ~24 assertions) + 1 cross-consistency assertion + 3 new component rows with 8 assertion blocks (`ProviderRowHarness.qml`) = 14 new named test functions plus 2 new harness files' worth of inline assertions.
- **Total tests passing**: All — full suite `./scripts/run-qml-tests.sh` exit `0`.
- **Layers used**: Unit (`UsageModelTest.qml`, `PreferredWindowHarness.qml`), Integration (`ProviderRowHarness.qml`, `SettingsInteractionTest.qml`).
- **Approval tests**: `test_selectRepresentativeAutomaticMatchesLegacySingleArgument` (object-identity proof that automatic/undefined/unrecognized reproduce legacy 1-arg behavior exactly) and the Phase 6 cross-consistency assertion.
- **Pure functions created**: `PreferredWindow.parse`, `PreferredWindow.keyOrDefault`, `UsageModel.definitionForPreferred`, `UsageModel.matchesDefinition`, `UsageModel.preferredFiniteWindow`.

## Deviations from Design

1. **`preferredWindowGuidanceLabel.Accessible.name` uses `qsTr(...)` instead of `i18n(...)`.** The design's exact code contract specified `Accessible.name: i18n("Representative window guidance")`. Under this repository's actual offscreen `qmltestrunner` environment, `i18n(...)` resolves to an empty string (confirmed by direct debug instrumentation: `text=` and `Accessible.name=[]` both empty for an `i18n()`-driven label, while a `qsTr()`-driven label on the same page correctly resolved to non-empty text). Task 4.1 requires `guidance label visible with non-empty Accessible.name`, which is unachievable with `i18n()` in this test environment. The existing codebase already has this exact precedent: `codexbarSetupGuidance` uses `text: i18n(...)` (untested for content) but `Accessible.name: qsTr(...)` (asserted non-empty by `test_cliPathProvidesNativeSetupGuidance`). I followed that established local convention exactly — visible `text` stays `i18n(...)` per design (correct in a real Plasma runtime, where `i18n()` falls back to the literal string when no catalog is loaded), only the short `Accessible.name` switched to `qsTr(...)`. No persisted-value contract, default, or visible layout changed.
2. **Design risk #1 (custom-alias round-trip) is confirmed closed, not worked around.** `cfg_preferredRepresentativeWindow: preferredWindow.selectedKey` round-tripped correctly on the first GREEN run — `test_preferredWindowControlIsDiscoverableAndDefaulted`, `test_preferredWindowSelectionPersistsKeys`, and `test_preferredWindowIsIndependentFromTimeout` all passed without needing the fallback `currentIndex`/int-backed-alias wiring the design flagged as a contingency. No structural deviation was needed here.

No other deviations. `selectCompact` was not called, read, or modified (confirmed by `test_selectCompactIsUnaffectedByPreferredWindow`, which also asserts `selectCompact.length === 1`). The detail (`summary: false`) `ProviderRow` in `main.qml` was not touched.

## Issues Found

None blocking. The offscreen environment's `i18n()`/`i18np()` warnings noted in prior apply-progress documents remain present and non-failing; no new warnings were introduced.

## Risks

**Actual authored line count (468: +465/-3 across all new and modified production/test/doc files) exceeds the 400-line review budget**, and exceeds the tasks.md forecast's worst case (340 lines, Low risk, single PR, no chaining, "Decision needed before apply: No"). The overrun was not visible until implementation was complete: `UsageModelTest.qml` (+132 vs. an estimated 70–85), `PreferredWindowHarness.qml` (+83 vs. an estimated 30–35 — this file also absorbed the Phase 6 cross-consistency assertion, which the design's budget table did not separately account for), `ProviderRowHarness.qml` (+66 vs. an estimated 45–55), and `SettingsInteractionTest.qml` (+57 vs. an estimated 30–40) each ran over their design-time estimates because every case in the design's testing-strategy table required its own full fixture setup to stay a real, non-trivial assertion (no shared-mock shortcuts were available without weakening TDD assertion-quality rules). No line was cut to force a lower count, since every added line maps to a specific mandated task (2.1–2.6, 3.1–3.6, 4.1–4.5, 6.1) or the exact input-domain enumeration the design itself specified verbatim.

This is a delivery-packaging decision, not an implementation defect — all 43 tasks are complete, fully green, and `git diff --check` is clean. Two options for the maintainer/orchestrator before delivery:
- **Accept `size:exception`** for a single PR (468 lines is a cohesive, low-risk, single-feature change with no routing/shell/subprocess/VCS boundary per the design's Threat Matrix; splitting it would fragment RED→GREEN atomicity within the resolver/selector/component phases).
- **Split into 2 PRs** along the natural Phase 3/4 boundary: PR1 = Resolver + Selector + Component (`PreferredWindow.js`, `UsageModel.js`, `ProviderRow.qml`, `run-qml-tests.sh`, `UsageModelTest.qml`, `ProviderRowHarness.qml`, and the resolver-only portion of `PreferredWindowHarness.qml`) ≈ 324 lines, under budget; PR2 = Settings surface + Plumbing + Docs (`main.xml`, `configGeneral.qml`, `main.qml`, `SettingsInteractionTest.qml`, `docs/live-plasma-smoke.md`, and the cross-consistency addition to `PreferredWindowHarness.qml`) ≈ 143 lines, under budget. Both slices are independently green and independently revertible.

No other risks. Rollback boundary is documented above and is identical either way (single PR or split).

## Full Suite — Final Run

```
$ ./scripts/run-qml-tests.sh
Using QtTest runner: /usr/lib/qt6/bin/qmltestrunner
Running tests/UsageModelTest.qml
Totals: 17 passed, 0 failed, 0 skipped, 0 blacklisted
Running tests/UsageControllerFixture.qml
Totals: 16 passed, 0 failed, 0 skipped, 0 blacklisted
Running tests/SettingsInteractionTest.qml
Totals: 11 passed, 0 failed, 0 skipped, 0 blacklisted
Running tests/RequestTimeoutHarness.qml
Running tests/PreferredWindowHarness.qml
Running tests/RequestTimeoutSettingsHarness.qml
Running tests/RefreshIntervalHarness.qml
Running tests/UsageModelHarness.qml
Running tests/UsageControllerHarness.qml
Running tests/UsageControllerFailureHarness.qml
Running tests/UsageControllerLifecycleHarness.qml
Running tests/UsageControllerDataSourceLifecycleHarness.qml
Running tests/UsageControllerPreflightHarness.qml
Running tests/UsageControllerPathCheckHarness.qml
Running tests/CodexBarPathResolverHarness.qml
Running tests/TimeoutFeedbackPopupHarness.qml
Running tests/MainCompactHarness.qml
Running tests/CompactUsageButtonHarness.qml
Running tests/ProviderRowHarness.qml
Running tests/ProviderSelectorHarness.qml
Running tests/ErrorSummaryHarness.qml
Running tests/UsageControllerTerminationHarness.qml
$ echo $?
0
```

## `git diff --check` — Final Run

```
$ git diff --check
$ echo $?
0
```

## Notes

- `contents/code/PreferredWindow.js` and `tests/PreferredWindowHarness.qml` are new, untracked files at the time of this apply batch (not yet `git add`ed — per instructions, this batch does not commit).
- Baseline safety net before any edit: `./scripts/run-qml-tests.sh` was green (11 + 16 + 8 QtTest passes plus all executable harnesses) prior to touching any file.
- No `apply-progress.md` existed for this change before this batch (first apply batch, per orchestrator instructions); this file was created fresh, not merged from a prior batch.
