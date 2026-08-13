```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:505e06038d00cf555b66025ce45960211066a10a1fa06ece8679b7fca8e418a7
verdict: pass
blockers: 0
critical_findings: 0
requirements: 1/1
scenarios: 12/12
test_command: ./scripts/run-qml-tests.sh
test_exit_code: 0
test_output_hash: sha256:e8178c84d71181907ef5485b8f2ac7211566d6af4f0881da85e9b915c48cdb3e
build_command: git diff --check
build_exit_code: 0
build_output_hash: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

## Verification Report

**Change**: `configurable-representative-window`
**Version**: N/A
**Mode**: Strict TDD
**Artifact store**: Hybrid (OpenSpec + Engram) — Engram `mem_*` tools were unavailable in this session (known gap noted for all prior phases); OpenSpec files were treated as authoritative and read directly.
**Independence note**: This is a fresh, independent verification. All findings below were re-derived from current code and live test execution, not copied from `apply-progress.md` claims.

### Completeness

| Metric | Value |
|---|---:|
| Requirements total | 1 |
| Requirements fully compliant | 1 |
| Scenarios total | 12 |
| Scenarios compliant | 12 |
| Tasks total | 43 |
| Tasks complete | 43 |
| Tasks incomplete | 0 |

### Build & Tests Execution

**Configured test command**: ✅ exit 0
**Command**: `./scripts/run-qml-tests.sh`
**Output hash**: `sha256:e8178c84d71181907ef5485b8f2ac7211566d6af4f0881da85e9b915c48cdb3e`

```text
Running tests/UsageModelTest.qml       → Totals: 17 passed, 0 failed, 0 skipped, 0 blacklisted
Running tests/UsageControllerFixture.qml → Totals: 16 passed, 0 failed, 0 skipped, 0 blacklisted
Running tests/SettingsInteractionTest.qml → Totals: 11 passed, 0 failed, 0 skipped, 0 blacklisted
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
(exit 0 — all 18 standalone qml6 harnesses exited 0)
```

**Build/quality command**: ✅ exit 0
**Command**: `git diff --check`
**Output hash**: `sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
**Output**: empty (no whitespace errors)

**Coverage**: ➖ Coverage analysis skipped — no QML coverage tool is configured.

### Spec Compliance Matrix

| Requirement | Scenario | Passing runtime evidence | Result |
|---|---|---|---|
| Provider presentation | Heterogeneous providers | `ProviderRowHarness.qml:210-215` (`row` fixture) asserts raw provider/source preserved, missing-window omission, exact reset text, and themed fallback icon. Re-run: exit 0. | ✅ COMPLIANT |
| Provider presentation | Session is representative | `UsageModelTest::test_selectRepresentativeReturnsSessionWhenAllFinite`; `ProviderRowHarness` `summaryRow` (`representativeWindow.label === "Session"`). Re-run: exit 0. | ✅ COMPLIANT |
| Provider presentation | Representative fallback order | `UsageModelTest::test_selectRepresentativeFallsBackToWeeklyOrMonthly` (Weekly branch). Re-run: exit 0. | ✅ COMPLIANT |
| Provider presentation | Monthly is the only finite window | `UsageModelTest::test_selectRepresentativeFallsBackToWeeklyOrMonthly` (Monthly branch). Re-run: exit 0. | ✅ COMPLIANT |
| Provider presentation | Provider has no finite percentage | `UsageModelTest::test_selectRepresentativeReturnsNullForNoFiniteWindow`; `ProviderRowHarness` `identityOnlyRow` (zero bars, zero window rows, identity preserved). Re-run: exit 0. | ✅ COMPLIANT |
| Provider presentation | Full detail remains in provider tab | `ProviderRowHarness` `detailRow` fixture renders every supplied window (Session/Monthly/Weekly/Daily/Hourly), `countProgressBars(detailRow) === 1` for the one finite value, exact raw reset text preserved. `main.qml:120-126` confirms the detail `ProviderRow` never receives `preferredWindowKey` or `summary: true`. Re-run: exit 0. | ✅ COMPLIANT |
| Provider presentation | All summaries are not expandable | `ProviderRowHarness.qml:231-240` (`activeSummaryRow`) records bar/row counts before `forceActiveFocus()`, then re-asserts identical counts and hidden reset labels after. Re-run: exit 0. | ✅ COMPLIANT |
| Provider presentation | Explicit preferred window with a finite value | `UsageModelTest::test_selectRepresentativeHonoursExplicitPreferredWindow` (`"weekly"` key → Weekly, `usedPercent: 20`); `ProviderRowHarness` `preferredWeeklyRow` (`representativeWindow.label === "Weekly"`, exactly one bar). Re-run: exit 0. | ✅ COMPLIANT |
| Provider presentation | Per-provider fallback under an explicit preference | `UsageModelTest::test_selectRepresentativePerProviderFallbackIsIndependent` — same `"monthly"` call key, one provider (`tertiary: null`) falls back to Session, another (`tertiary: 45`) keeps Monthly, in the same test invocation. Re-run: exit 0. | ✅ COMPLIANT |
| Provider presentation | Automatic preserves current default behavior | `UsageModelTest::test_selectRepresentativeAutomaticMatchesLegacySingleArgument` — for finite/non-finite/empty fixtures, `selectRepresentative(w) === selectRepresentative(w, "automatic") === selectRepresentative(w, undefined) === selectRepresentative(w, "yearly")`; two of three fixtures compare non-null representative window objects returned via the identical `firstFiniteWindow` code path (real object-identity proof, not a vacuous null-only check — see Assertion Quality below). `ProviderRowHarness` `summaryRow.preferredWindowKey === "automatic"` default assertion. Re-run: exit 0. | ✅ COMPLIANT |
| Provider presentation | Preference is global, not per-provider | Same evidence as "Per-provider fallback": one `preferredKey` argument (`"monthly"`) is passed identically to both provider fixtures with no per-provider override parameter in `selectRepresentative`'s signature; `main.qml` passes one `root.preferredWindowKey` into every `All` `Repeater` delegate uniformly (`main.qml:106-118`). Re-run: exit 0. | ✅ COMPLIANT |
| Provider presentation | Fallback bar has no special visual treatment | `ProviderRowHarness.qml:256` — `countVisibleUsageDetails(preferredFallbackRow) === countVisibleUsageDetails(preferredWeeklyRow)`, proving the fallback-selected bar and the explicit-preference bar expose an identical visible-detail count (percentage/reset label visibility), differing only by the window's own `label`. Re-run: exit 0. | ✅ COMPLIANT |

**Compliance summary**: 12/12 scenarios compliant; 1/1 modified requirement fully compliant.

### Correctness (Static Evidence)

| Requirement facet | Status | Evidence |
|---|---|---|
| Global `preferredRepresentativeWindow` kcfg entry, default `automatic` | ✅ Implemented | `contents/config/main.xml:21-23`, inside `<group name="General">`. |
| Resolver rejects everything but the 4 valid keys | ✅ Implemented | `contents/code/PreferredWindow.js` — `parse`/`keyOrDefault`, `.pragma library`, strict case-sensitive match. |
| Explicit preference honored when finite | ✅ Implemented | `UsageModel.selectRepresentative(windows, preferredKey)` → `definitionForPreferred` → `preferredFiniteWindow`. |
| Per-provider fallback when explicit preference is non-finite | ✅ Implemented | `preferredFiniteWindow` returns `null` when no match; `selectRepresentative` falls through to unmodified `firstFiniteWindow`. |
| Automatic/absent/unrecognized reproduces legacy order exactly | ✅ Implemented | `"automatic"` is deliberately not a `preferredWindowKeys` map key, so it takes the same `null`-definition path as `undefined`/`"yearly"`, by construction. |
| No finite window → identity only, any preference | ✅ Implemented | `firstFiniteWindow` returns `null` when no window is usable; `ProviderRow.displayedWindows` becomes `[]`. |
| `selectCompact` untouched | ✅ Implemented | `selectCompact(providers)` body is byte-identical to the pre-existing implementation from the archived `compact-all-provider-bars` change (verified against `openspec/changes/archive/2026-08-12-compact-all-provider-bars/verify-report.md`); this change adds no parameter and no call site touches it. `UsageModel.selectCompact.length === 1` is runtime-asserted. | 
| Settings surface: discoverable, labeled, keyboard-reachable | ✅ Implemented | `configGeneral.qml` `QQC2.ComboBox id: preferredWindow`, `objectName: "preferredRepresentativeWindow"`, tab order extended after the custom timeout `SpinBox`. |
| Persisted-default-unchanged guarantee | ✅ Implemented and runtime-proven | See "Automatic preserves current default behavior" row above. |

### Coherence (Design)

| Decision | Followed? | Notes |
|---|---|---|
| Optional 2nd param on `selectRepresentative`, 1-arg callers unaffected | ✅ Yes | Confirmed by 3 unmodified pre-existing 1-arg test cases still passing, plus the explicit automatic-equivalence proof. |
| Persisted values `"automatic"/"session"/"weekly"/"monthly"` (not raw `primary/secondary/tertiary`) | ✅ Yes | `contents/config/main.xml`, `PreferredWindow.VALID_KEYS`. |
| Match a window by `key` or `label` | ✅ Yes | `matchesDefinition(window, definition)` checks both. |
| Dedicated `PreferredWindow.js` resolver mirroring `RequestTimeout.js` | ✅ Yes | `.pragma library`, `DEFAULT_KEY`, `VALID_KEYS`, `parse`, `keyOrDefault` — structurally identical pattern. |
| ComboBox appended after the custom-timeout SpinBox (not inserted mid-form) | ✅ Yes | `configGeneral.qml:149-166`, confirmed by extended `test_tabTraversalUsesNativeFocus`. |
| Detail (`summary: false`) `ProviderRow` untouched | ✅ Yes | `main.qml:120-126` receives no `preferredWindowKey` binding. |
| `Accessible.name` uses `qsTr(...)` instead of design's literal `i18n(...)` for the guidance label | ⚠️ Documented deviation | `configGeneral.qml:196`. Apply-progress documents this explicitly (Deviations #1): `i18n()` resolves empty under the offscreen `qmltestrunner` environment; the existing `codexbarSetupGuidance` label already uses this exact `text: i18n / Accessible.name: qsTr` split as local precedent. Visible `text` remains `i18n(...)` per design. No persisted-value or layout contract changed. Non-blocking. |
| Design risk #1 (custom-alias `selectedKey` round-trip) | ✅ Confirmed closed | All 3 discoverability/persistence/independence settings tests passed without needing the fallback `currentIndex`/int-backed-alias contingency the design flagged. |

### Task Completion

All 43 task checkboxes in `tasks.md` are complete. Cross-referenced against actual code for every phase:
- Phase 1 (1.1–1.4, resolver): `contents/code/PreferredWindow.js` exists with the exact contract; `PreferredWindowHarness` registered in `scripts/run-qml-tests.sh:31`.
- Phase 2 (2.1–2.11, selector): all 6 new `UsageModelTest.qml` cases plus the 3 pre-existing 1-arg cases exist and pass (17 total in that suite, up from 11 pre-change per the archived baseline).
- Phase 3 (3.1–3.10, component): 3 new `ProviderRowHarness.qml` rows (`preferredWeeklyRow`, `preferredFallbackRow`, `preferredIdentityOnlyRow`) plus default/reactivity/styling-parity assertions all present and passing.
- Phase 4 (4.1–4.10, settings): `main.xml` kcfg entry, `configGeneral.qml` ComboBox/aliases/guidance, and 4 new `SettingsInteractionTest.qml` cases (11 total, up from 8 pre-change) all present and passing.
- Phase 5 (5.1–5.4, plumbing): `main.qml` import/property/wiring present exactly as specified; full suite green.
- Phase 6 (6.1–6.4, REFACTOR): cross-consistency assertion present in `PreferredWindowHarness.qml:53-78` and passing; `docs/live-plasma-smoke.md` updated with the new "Representative window setting" section; full suite and `git diff --check` both re-confirmed green by this independent verification.

No task is checked without corresponding, currently-passing code.

### TDD Compliance

| Check | Result | Details |
|---|---|---|
| TDD Evidence reported | ✅ | `apply-progress.md` contains a full "TDD Cycle Evidence" table for every phase. |
| All tasks have tests | ✅ | 43/43 tasks map to a test file or documented plumbing/docs-only task. |
| RED confirmed (tests exist) | ✅ | `PreferredWindowHarness.qml`, `UsageModelTest.qml`, `ProviderRowHarness.qml`, `SettingsInteractionTest.qml` all exist with the described new cases. |
| GREEN confirmed (tests pass) | ✅ | Fresh execution: `UsageModelTest` 17/17, `SettingsInteractionTest` 11/11, all 18 standalone `qml6` harnesses exit 0, full runner exit 0. |
| Triangulation adequate | ✅ | Explicit-finite, non-finite fallback, per-provider independence, automatic-equivalence, null-under-any-preference, and `selectCompact`-unaffected are 6 behaviorally distinct selector cases; not single-case coverage. |
| Safety Net for modified files | ✅ | Apply-progress records pre-edit baselines (11/11, 8/8, harness-green) for every modified file; this verification's fresh full-suite run confirms no regression. |

**TDD Compliance**: 6/6 checks passed.

---

### Test Layer Distribution

| Layer | Tests | Files | Tools |
|-------|-------|-------|-------|
| Unit | 17 (`UsageModelTest.qml`) + ~24 assertions (`PreferredWindowHarness.qml`, pure resolver + cross-consistency) | 2 | `qmltestrunner`, `qml6` |
| Integration | 11 (`SettingsInteractionTest.qml`) + `ProviderRowHarness.qml` (8 assertion blocks incl. 3 new rows) + 16 (`UsageControllerFixture.qml`, unaffected regression) | 3 | `qmltestrunner`, `qml6` |
| E2E | 0 automated (manual checklist only, `docs/live-plasma-smoke.md`) | 0 | Manual |
| **Total** | **28 QtTest cases directly exercising this change + 2 harness files' worth of inline assertions, plus 16 unaffected regression cases confirmed still green** | | |

---

### Changed File Coverage

Coverage analysis skipped — no QML coverage tool is configured in this project.

---

### Assertion Quality

Scanned `tests/PreferredWindowHarness.qml`, `tests/UsageModelTest.qml` (new cases), `tests/ProviderRowHarness.qml` (new rows/assertions), and `tests/SettingsInteractionTest.qml` (new cases) for banned patterns (tautologies, orphan empty-only checks without a companion non-empty test, type-only-only assertions, ghost loops, assertion-free production-code paths, smoke-test-only patterns, implementation-detail coupling, mock-heavy ratios).

| File | Line | Assertion | Issue | Severity |
|------|------|-----------|-------|----------|
| `tests/UsageModelTest.qml` | 236-243 | `test_selectRepresentativeAutomaticMatchesLegacySingleArgument` loop iterates 3 fixtures; the third (`emptyProvider`) yields `compare(null, null)` for all 4 calls | One of three loop iterations is a vacuous null-comparison; however the other two iterations (finite, non-finite) compare real non-null window objects across all 4 call variants, so the loop as a whole is not a ghost loop (it cannot pass on an empty collection — `fixtures.length === 3`, fixed and non-empty) | SUGGESTION |

No CRITICAL or WARNING assertion-quality issues found. `test_selectRepresentativeAutomaticMatchesLegacySingleArgument` and `test_selectCompactIsUnaffectedByPreferredWindow` both call production code with concrete fixtures and assert distinct, non-trivial expected values (`usedPercent`, `label`, `.length` arity) rather than tautologies. `test_selectRepresentativePerProviderFallbackIsIndependent` asserts two different label/percentage outcomes from a single shared preference argument, which is the core proof for "Preference is global, not per-provider" and is not reducible to a single always-true check.

**Assertion quality**: 0 CRITICAL, 0 WARNING, 1 SUGGESTION.

### Quality Metrics

**Linter**: ➖ Not configured
**Type Checker**: ➖ Not configured
**Whitespace/build check**: ✅ `git diff --check` exit 0

### Issues Found

**CRITICAL**: None.

**WARNING**: None.

**SUGGESTION**:
1. `test_selectRepresentativeAutomaticMatchesLegacySingleArgument`'s third fixture (`emptyProvider`) contributes only vacuous `compare(null, null)` assertions to an otherwise-strong triangulated test; the two other fixtures already carry the real proof weight, so this is not blocking, but a future maintainer extending this test should be aware the empty-fixture iteration adds no discriminating power on its own.
2. Live Breeze Light/Dark, keyboard-only delivery, and narrow-panel-layout checks for the new settings control were not independently executed in a real Plasma session in this headless verification environment; `docs/live-plasma-smoke.md` documents the manual checklist and this remains consistent with every prior change in this repository.
3. Coverage and QML linting/type-checking remain unconfigured for this project (pre-existing condition, not introduced by this change).
4. **Documented, pre-accepted, non-blocking**: actual authored line count for this change is 468 (+465/-3), exceeding both the 400-line review budget and the tasks.md forecast (290–340). This was already explicitly flagged by `apply-progress.md` under "Risks" and granted `size:exception` by the user per this phase's launch context. Not re-litigated as a new finding; recorded here only for completeness of the delivery record.

### Verdict

**PASS**

All 1 requirement and all 12 normative scenarios (7 preserved + 5 new) have passing runtime coverage, independently re-derived and re-executed in this verification. All 43 tasks are genuinely complete and match current code. `selectCompact` and the detail `ProviderRow` are confirmed untouched. The persisted-default-unchanged guarantee is proven by a real (non-tautological) object-identity/value test. `./scripts/run-qml-tests.sh` and `git diff --check` both exit 0 on independent re-execution. The only findings are non-blocking SUGGESTIONs and one already-accepted, factually-recorded size exception.
