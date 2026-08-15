```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:b1360c8273ee32a55c673780b0281473a6e6d81600759f3bd31f49f72adeb9dc
verdict: pass
blockers: 0
critical_findings: 0
requirements: 6/6
scenarios: 15/15
test_command: ./scripts/run-qml-tests.sh
test_exit_code: 0
test_output_hash: sha256:7793bab40a5d89d7829af2c377cf8c66336ae487b978f906be4564d8de97ba62
build_command: ./scripts/lint-qml.sh
build_exit_code: 0
build_output_hash: sha256:3454d2ef8e2558f8c3224c4b0c8aade332a17436e43de86b65110f9c0459bec9
```

## Verification Report

**Change**: final-popup-parity
**Version**: N/A (openspec delta spec, not versioned)
**Mode**: Strict TDD

### Completeness
| Metric | Value |
|--------|-------|
| Tasks total | 15 (1.1-1.3, 2.1-2.4, 3.1-3.4, 4.1-4.3) |
| Tasks complete | 15 |
| Tasks incomplete | 0 |

Note: no separate `apply-progress` artifact file exists for this change (openspec mode). The audit trail — including a documented PR2 `size:exception`, a documented PR3 split, and four dated live-smoke bug-fix addenda under task 4.3 — is embedded directly in `tasks.md` itself. This is a deviation from the usual apply-progress artifact convention but does not block verification: the evidence is present, dated, and independently checkable against the commit history.

### Build & Tests Execution
**Build (lint)**: PASSED
```text
$ ./scripts/lint-qml.sh
Accepted 68 exact KDE translation warning(s).
exit 0
```

**Tests**: 61 QtTest assertions passed across 4 QtTest suites (22 UsageModel + 17 UsageControllerFixture + 11 SettingsInteraction + 11 ProviderDetailsIntegrationTest x2 themes), 17 pytest cases, plus 24 scripted QML harnesses (including CostModelHarness, CostControllerHarness, CostControllerTerminationHarness, CostControllerDataSourceLifecycleHarness, CostRequestPolicyHarness, ProviderRowHarness, ProviderSelectorHarness) all exiting 0.
```text
$ ./scripts/run-qml-tests.sh
... (22 PASS UsageModel, 17 PASS UsageControllerFixture, 11 PASS SettingsInteraction,
     11 PASS ProviderDetailsIntegrationTest x BreezeLight, 11 PASS x BreezeDark,
     17 pytest OK, 24 scripted harnesses all exit 0)
EXIT_CODE: 0
```

**Package validation**: PASSED — `./scripts/validate-package.sh` (kpackagetool6 install) exit 0.

**Whitespace**: PASSED — `git diff --check main...HEAD` exit 0, no trailing-whitespace/mixed-tab issues across the full 11-commit chain.

**Coverage**: Not applicable — no coverage tool configured for this QML/QtTest stack (informational, not a failure).

### Spec Compliance Matrix

**provider-usage-display**

| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| Selected-provider enrichment | Valid enrichment is displayed | `ProviderDetailsIntegrationTest.qml`, `ProviderRowHarness.qml` (enrichedDetailRow assertions) | COMPLIANT |
| Selected-provider enrichment | Invalid or zero data is hidden | `ProviderDetailsIntegrationTest.qml::test_invalidOrMissingEnrichmentIsOmitted`, `ProviderDetails.js` fail-closed extractors (`validCreditsRemaining`, `validResetCredits` reject `availableCount<=0`) | COMPLIANT |
| Selected-provider enrichment | Expirations are accessible | `ProviderDetailsIntegrationTest.qml::test_returnAndSpaceToggleResetCreditsDisclosureAccessibleState`; `ResetCreditsSection.qml` `QQC2.ToolButton` with `Accessible.name/description`, `Keys.onReturnPressed/onSpacePressed`, no redeem action | COMPLIANT |
| Selected-provider enrichment | Privacy remains provider-scoped | `ProviderDetailsIntegrationTest.qml::test_maliciousProviderDisplaysOnlyApprovedFields`, `test_fixturePiiRemainsFailClosedForRealCapturedShape`; `ProviderHeader.qml` gates `headerEmail`/`headerOrganization` on `detailed` | COMPLIANT |
| Protected native presentation | Usage regression and responsive checks | `UsageControllerFixture.qml` (17/17, unchanged), `ProviderDetailsIntegrationTest.qml` narrow-width + BreezeLight/BreezeDark runs, `run-qml-tests.sh`/`lint-qml.sh`/`validate-package.sh` all exit 0, live `plasmawindowed` smoke (tasks.md 4.3 + addenda) | COMPLIANT |
| Provider-focused exclusions (MODIFIED) | Missing commercial or reset data | `ProviderDetails.js` fail-closed extractors; `test_invalidOrMissingEnrichmentIsOmitted` | COMPLIANT |
| Provider-focused exclusions (MODIFIED) | Verbatim passthrough of unmodeled fields | `UsageModelTest.qml::test_preservesUnmodeledProviderFieldsVerbatimUnderRaw`, `test_rawRetainsWindowKeysThatWindowsStillDrop` | COMPLIANT |
| Provider-focused exclusions (MODIFIED) | Raw preservation authorizes bounded display | `test_maliciousProviderDisplaysOnlyApprovedFields`; grep confirms no price-calculation/no raw-diagnostic exposure paths | COMPLIANT |
| Provider-focused exclusions (MODIFIED) | Fixture provenance and redaction | `test_cli_contract_fixture.py` (17/17: pinned bytes, redaction rules, key/type fidelity, no PII patterns) | COMPLIANT |

**provider-cost-estimate**

| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| Provider-specific cost contract | Matching local estimate | `CostModelHarness.qml`, `CostControllerHarness.qml`; `CostController.qml` emits exactly `cost --provider {provider} --format json --json-only` | COMPLIANT |
| Provider-specific cost contract | All summary remains cost-free | `ProviderRowHarness.qml` (`summaryCost === null \|\| !summaryCost.visible`); `main.qml` never binds `costSnapshot` for summary rows | COMPLIANT |
| Independent correlated lifecycle | Refresh and selection reuse fresh data | `CostControllerHarness.qml` coalescing case; `CostRequestPolicy.js::shouldRequestCost` (`!hasSnapshot` guard) + `CostRequestPolicyHarness.qml` | COMPLIANT |
| Independent correlated lifecycle | Stale callback is ignored | `CostControllerTerminationHarness.qml` (real-subprocess replace/terminate), `CostController.qml::isCurrentRequest` provider+generation+serial guard | COMPLIANT |
| Fail-closed optional rendering | Cost fails independently | `CostControllerHarness.qml`, `ProviderRowHarness.qml` (`costFailureRow` case); `CostController.qml::handleData` discards without publishing | COMPLIANT |
| Fail-closed optional rendering | Contract evidence is verified | `test_cli_contract_fixture.py` cost-fixture cases (7 tests), `docs/cli-contract-capture.md` "Cost contract capture" section | COMPLIANT |

**Compliance summary**: 15/15 scenarios compliant

### Correctness (Static Evidence)
| Requirement | Status | Notes |
|------------|--------|-------|
| Exact `usage --provider all --format json --json-only` invocation preserved | Implemented | `UsageController.qml:39`; zero diff across `main...HEAD` on this line |
| Exact `cost --provider {provider} --format json --json-only` invocation | Implemented | `CostController.qml:45-49` |
| UUID/hex/opaque-token organization rejection | Implemented | `ProviderDetails.js:178-233` (`uuidPattern`, `hexLikePattern`, `opaqueTokenPattern`, `looksOpaque`) |
| Cost number formatting (no scientific notation) | Implemented | `CostSection.qml::formatUsd/formatTokens`; regression-tested by `largeCostRow` in `ProviderRowHarness.qml` |
| Tab bar reachability/scrollbar (3 rounds of live-bug fixes) | Implemented | `ProviderSelector.qml` — `TabBar` self-manages scroll, `ScrollBar` bound to `tabBar.contentItem`, placed as `ColumnLayout` sibling (not anchored overlay) |
| Out-of-scope: Auth/Add Account/Quit/redeem/price-calc | Absent (confirmed by grep) | No matches for `redeem`, `mutation`, `add account`, price-calc keywords in `contents/` |

### Coherence (Design)
| Decision | Followed? | Notes |
|----------|-----------|-------|
| `CostController` isolated from `UsageController` | Yes | Separate `.qml` file, own `DataSource`, own watchdog; `UsageController` only gained `committedGeneration`, no command/branch changes (confirmed zero diff on `commandLine()`) |
| `CostModel.normalize` fail-closed, all-or-nothing | Yes | `CostModel.js:27-63` — all four numeric fields must be finite+non-negative or entire result is `null` |
| `ProviderDetails.js` extractors, no QML price calc | Yes | All validation/extraction logic lives in `.js`; QML components (`ProviderHeader`, `CostSection`, `ResetCreditsSection`) only compose/format already-validated values |
| Native `ProviderHeader`/`ResetCreditsSection`/`CostSection` components | Yes | Created as described, wired into `ProviderRow.qml` |
| Hybrid cost-request strategy (request only on successful commit or missing-snapshot selection) | Yes | `CostRequestPolicy.js::shouldRequestCost` + `main.qml::maybeRequestCost` called from `onSelectedProviderChanged` and `onCommittedGenerationChanged` |
| 60s cost watchdog | Yes | `CostController.qml` `timeoutMs: 60000` default |
| Sections absent (not placeholder/error rows) on validation failure | Yes | All new QML sections gate on `visible: <validated-non-null>` |

### Issues Found
**CRITICAL**: None

**WARNING**: None

**SUGGESTION**:
1. No dedicated `apply-progress.md` artifact exists for this change (unlike prior archived changes in this repo, which all have one); the equivalent audit trail is folded into `tasks.md`'s dated addenda instead. Functionally equivalent and fully evidenced, but inconsistent with this repo's own convention — consider extracting an `apply-progress.md` before archive for consistency with prior changes.
2. Three of the four live-smoke addenda note that real click/keyboard/pointer interaction (as opposed to programmatic `currentIndex`/geometry assertions) still needs a live human pass, since the sandbox that authored those fixes has no pointer/keyboard simulation tool. The maintainer (Gino) is recorded as having confirmed these on the real widget on 2026-08-15, but that confirmation is narrative in `tasks.md`, not an automated/replayable artifact — acceptable per this project's documented manual-evidence policy, just flagging for visibility.
3. Sanity-checked authored-line claims against `git show --stat`: PR2 documented ~569 vs. actual 578 (add+del), PR3a documented ~324 vs. actual 343, PR3b documented ~570 vs. actual 570 (exact). PR1 has no documented estimate in `tasks.md` (348 actual, under the 400-line budget on its own, so no exception was needed or claimed). All within reasonable sanity-check tolerance — no undocumented scope creep found.

### Outstanding Human Actions (out of verification scope)
- None of PR1-PR4 have been pushed or opened as GitHub PRs yet (per task framing, this is expected and explicitly out of scope for this verification pass).
- Each chained PR branch will need review before merge per the `feature-branch-chain` delivery strategy recorded in `tasks.md`.

### Verdict
**PASS**

All 6 requirements / 15 scenarios across both delta specs are implemented and covered by passing runtime tests; all 3 required verification scripts (`run-qml-tests.sh`, `lint-qml.sh`, `validate-package.sh`) exit 0; whitespace check is clean across the full 6-branch chain; out-of-scope boundaries (Auth, Add Account, Quit, redeem/mutation, QML price calculation, and the exact usage invocation string) are confirmed untouched by grep and diff; and the four dated live-smoke addenda under task 4.3 document real bugs found and fixed with RED-GREEN evidence, not narrative-only claims.
