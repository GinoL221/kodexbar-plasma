```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:74650e882540cad038784125dd64f5ab8cd0c6077a5911b2aec203a3eaa0a41e
verdict: pass_with_warnings
blockers: 0
critical_findings: 0
requirements: 2/2
scenarios: 25/25
test_command: ./scripts/run-qml-tests.sh
test_exit_code: 0
test_output_hash: sha256:a40b89b63c8649ae95188ec61a296768b6d7f206bd86ecdce0e18516917c45db
build_command: git diff --check
build_exit_code: 0
build_output_hash: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

## Verification Report

**Change**: cli-contract-fixtures  
**Version**: N/A  
**Mode**: Strict TDD  
**Artifact store**: Hybrid (OpenSpec + Engram)

### Completeness

| Metric | Value |
|---|---:|
| Requirements | 2 |
| Scenarios | 25 |
| Tasks total | 23 |
| Tasks complete | 23 |
| Tasks incomplete | 0 |

Native status reported `applyState: all_done`, `verify: ready`, and `taskProgress: 23/23`. Independent checklist inspection found 23 checked tasks and no unchecked task.

### Build & Tests Execution

| Command | Outcome | Exit | Output hash |
|---|---|---:|---|
| `./scripts/run-qml-tests.sh` | 22 UsageModel, 16 UsageControllerFixture, and 11 SettingsInteraction QtTest results passed; 19 executable QML harnesses completed | 0 | `sha256:a40b89b63c8649ae95188ec61a296768b6d7f206bd86ecdce0e18516917c45db` |
| `./scripts/lint-qml.sh` | Accepted the exact 56-warning KDE translation baseline | 0 | `sha256:163272edc0f9374237310be9fdfb5eac65ce6dd31b55d9ad56475e7a424dcd97` |
| `./scripts/validate-package.sh` | Isolated `kpackagetool6` installation and package validation passed | 0 | `sha256:c4af19f63f21138e41a1a4a37790a4953f304aedd2979d619a25764888e141de` |
| `python3 -m unittest discover -s tests` | 32 tests passed | 0 | `sha256:ac19527be99c26642f5c3bb0f53b9abf6a60fe7fe9eebba5e1df06906cb6d48d` |
| `python3 scripts/check-provider-icons.py --repo-root .` | Coverage, no-orphans, XML, color, and distinctness checks passed | 0 | `sha256:c848fbdd7a15077b18520b1602c315c65c2052b71a5cdcb397efdef95e791142` |
| Fixture value-equality gate | Printed `OK` | 0 | `sha256:a12b7cb43c9d9134b5bb1b35e9096b66775d9e92e7611d1cc92b02edd6782a87` |
| `git diff --check` | Empty output | 0 | `sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |

**Coverage**: Analysis skipped — `openspec/config.yaml` configures no coverage tool.  
**Build**: ✅ Passed.  
**Tests**: ✅ All executed suites and harnesses passed.

### Spec Compliance Matrix

| Requirement | Scenario | Passing test or gate | Result |
|---|---|---|---|
| Provider-focused exclusions | Missing commercial or reset data | `UsageModelTest::test_normalizesSingletonAndPreservesNullableRawValues`; `ProviderRowHarness.qml` | ✅ COMPLIANT |
| Provider-focused exclusions | Verbatim passthrough of unmodeled provider fields | `UsageModelTest::test_preservesUnmodeledProviderFieldsVerbatimUnderRaw`; `test_rawIsTheLiveParsedEntryNotACopy` | ✅ COMPLIANT |
| Provider-focused exclusions | Raw preservation does not authorize display | `MainCompactHarness.qml` and `ProviderRowHarness.qml`; fresh source scan found no UI `.raw` consumer | ✅ COMPLIANT |
| Provider-focused exclusions | Real capture fixture provenance and redaction | Fresh JSON/value-equality, entry-count, PII, provenance, and document gates | ✅ COMPLIANT ⚠️ |
| Provider presentation | Heterogeneous providers | `UsageModelTest::test_normalizesArrayInCliOrderAndOmitsMissingWindows`; `ProviderSelectorHarness.qml` | ✅ COMPLIANT |
| Provider presentation | Session is representative | `UsageModelTest::test_selectRepresentativeReturnsSessionWhenAllFinite` | ✅ COMPLIANT |
| Provider presentation | Representative fallback order | `UsageModelTest::test_selectRepresentativeFallsBackToWeeklyOrMonthly` | ✅ COMPLIANT |
| Provider presentation | Monthly is the only finite window | `UsageModelTest::test_selectRepresentativeFallsBackToWeeklyOrMonthly` | ✅ COMPLIANT |
| Provider presentation | Provider has no finite percentage | `UsageModelTest::test_selectRepresentativeReturnsNullForNoFiniteWindowUnderAnyPreference`; `ProviderRowHarness.qml` | ✅ COMPLIANT |
| Provider presentation | Full detail remains in provider tab | `ProviderRowHarness.qml` exact-window/reset assertions | ✅ COMPLIANT |
| Provider presentation | All summaries are not expandable | `ProviderRowHarness.qml` activation assertions | ✅ COMPLIANT |
| Provider presentation | Explicit preferred window with a finite value | `UsageModelTest::test_selectRepresentativeHonoursExplicitPreferredWindow`; `ProviderRowHarness.qml` | ✅ COMPLIANT |
| Provider presentation | Per-provider fallback under an explicit preference | `UsageModelTest::test_selectRepresentativePerProviderFallbackIsIndependent` | ✅ COMPLIANT |
| Provider presentation | Automatic preserves current default behavior | `UsageModelTest::test_selectRepresentativeAutomaticMatchesLegacySingleArgument` | ✅ COMPLIANT |
| Provider presentation | Preference is global, not per-provider | `SettingsInteractionTest::test_preferredWindowSelectionPersistsKeys`; `ProviderRowHarness.qml` | ✅ COMPLIANT |
| Provider presentation | Fallback bar has no special visual treatment | `ProviderRowHarness.qml` equal visible-detail assertions | ✅ COMPLIANT |
| Provider presentation | Every known provider renders a distinct, visible icon | Fresh provider-icon checker plus the archived accepted full-list live smoke evidence; icon assets are byte-unchanged in this change | ✅ COMPLIANT |
| Provider presentation | No hardcoded literal color defeats theme adaptation | `RealTreeBannedColorIntegrationTest`; fresh provider-icon checker | ✅ COMPLIANT |
| Provider presentation | Codex and Azure OpenAI show their own brand mark | `RealTreeIntegrationTest`; fresh distinctness checker | ✅ COMPLIANT |
| Provider presentation | Documented literal-color fallback remains legible | Provider-icon allowlist tests and accepted manual smoke evidence; fallback precondition remains untriggered | ✅ COMPLIANT |
| Provider presentation | Manual Breeze Light and Dark smoke check gates acceptance | Archived provider-icon verification addendum and live-smoke record; fresh diff proves no icon/UI change | ✅ COMPLIANT |
| Provider presentation | Icon-only fix preserves unrelated runtime boundaries | Full QML/Python suites, exact CLI argv harness, and unchanged protected paths | ✅ COMPLIANT |
| Provider presentation | Four-key contract values are unregressed by raw addition | `UsageModelTest::test_fourKeyContractIsUnregressedByRawAddition` | ✅ COMPLIANT |
| Provider presentation | Window-level unknown-key dropping remains unchanged | `UsageModelTest::test_rawRetainsWindowKeysThatWindowsStillDrop`; pre-existing `test_ignoresExtraAndNonFiniteUsageValues` | ✅ COMPLIANT |
| Provider presentation | Error entries remain unaffected by raw addition | `UsageModelTest::test_errorEntriesGainNoRawSibling` | ✅ COMPLIANT |

**Compliance summary**: 25/25 scenarios compliant. The fixture scenario carries the intentional masked-email warning described below; it is not a failing secret scan or value drift.

### Correctness (Static Evidence)

| Requirement | Status | Notes |
|---|---|---|
| Provider-focused exclusions | ✅ Implemented | `raw: entry` preserves CLI fields without computation; no UI reads `raw`; fixture and capture procedure exist. |
| Provider presentation | ✅ Implemented | Existing provider/window/error semantics remain stable; additive `raw` is provider-only. |

### Coherence (Design)

| Decision | Followed? | Notes |
|---|---|---|
| `raw` is a live parsed-entry reference | ✅ Yes | Source uses exact `raw: entry`; identity and nested-identity tests passed. |
| `normalizeWindow` remains unchanged | ✅ Yes | The only `UsageModel.js` diff is the comment and additive provider-level key. |
| Stable four-key semantics | ✅ Yes | Value, type, order, null, selector, and exact five-key window assertions passed. |
| Tests are append-only | ✅ Yes | Git diff adds five functions after the prior final function and removes no prior test bytes. |
| Exact CLI invocation | ✅ Yes | `UsageController.qml:38` still emits `usage --provider all --format json --json-only`; lifecycle argv harness passed. |
| No UI rendering or typed promotion | ✅ Yes | Protected UI/config paths are unchanged; no UI `.raw` use or first-class rich-field promotion exists. |
| Compact fixture equality | ✅ Yes | 67 entries, 6 usable providers, 61 errors, 69 lines; parsed value equality with the already-redacted source printed `OK`. |
| Capture document contract correction | ✅ Yes | Current bytes contain the required `## Why this exists` heading. |
| README scope | ✅ Yes | Only the exact exclusions paragraph was replaced; it says preserved but not displayed. |

### TDD Compliance

| Check | Result | Details |
|---|---|---|
| TDD evidence reported | ✅ | `apply-progress.md` contains the required TDD Cycle Evidence tables and exact RED/GREEN history. |
| Behavior-bearing tasks have tests | ✅ | Five new QtTest functions cover the production edit; documentation/data/check tasks are explicitly N/A. |
| RED confirmed | ✅ | Four new behaviors failed before `raw: entry`; the four-key regression pin was honestly reported green from the start. |
| GREEN confirmed | ✅ | All five new functions and all 17 prior UsageModel results pass in the current run. |
| Triangulation adequate | ✅ | Five distinct cases cover passthrough, identity, stable shape, unknown-window/non-finite handling, and errors. |
| Safety net for modified files | ✅ | The reported 17/17 pre-edit baseline exists; current suite is 22/22. |

**TDD Compliance**: 6/6 checks passed.

### Test Layer Distribution

| Layer | Tests | Files | Tools |
|---|---:|---:|---|
| Unit | 5 changed tests | 1 | QtTest / `qmltestrunner` |
| Integration | 0 changed tests | 0 | Existing executable QML harnesses re-ran successfully |
| E2E | 0 changed tests | 0 | Manual Plasma smoke is project-configured and inherited evidence remains valid |
| **Total** | **5** | **1** | |

### Changed File Coverage

Coverage analysis skipped — no coverage tool is configured.

### Assertion Quality

**Assertion quality**: ✅ All changed assertions invoke production normalization/selection behavior and assert concrete values, object identity, exact key counts, ordering, null handling, or error routing. No tautology, ghost loop, smoke-only, type-only-only, or mock-heavy pattern was found.

### Quality Metrics

**Linter**: ✅ No errors; exact 56-warning translation baseline accepted.  
**Type Checker**: ➖ Not available.  
**Package validator**: ✅ Passed.

### Canonical Verification Evidence

The following exact UTF-8 preimage, including its final LF, hashes to the envelope `evidence_revision`:

```text
change=cli-contract-fixtures
strict_tdd=true
task_progress=23/23
requirements=2/2
scenarios=25/25
test_command=./scripts/run-qml-tests.sh
test_exit_code=0
test_output_hash=sha256:a40b89b63c8649ae95188ec61a296768b6d7f206bd86ecdce0e18516917c45db
lint_command=./scripts/lint-qml.sh
lint_exit_code=0
lint_output_hash=sha256:163272edc0f9374237310be9fdfb5eac65ce6dd31b55d9ad56475e7a424dcd97
package_command=./scripts/validate-package.sh
package_exit_code=0
package_output_hash=sha256:c4af19f63f21138e41a1a4a37790a4953f304aedd2979d619a25764888e141de
unittest_command=python3 -m unittest discover -s tests
unittest_exit_code=0
unittest_output_hash=sha256:ac19527be99c26642f5c3bb0f53b9abf6a60fe7fe9eebba5e1df06906cb6d48d
icon_checker_command=python3 scripts/check-provider-icons.py --repo-root .
icon_checker_exit_code=0
icon_checker_output_hash=sha256:c848fbdd7a15077b18520b1602c315c65c2052b71a5cdcb397efdef95e791142
fixture_value_equality=OK
fixture_value_equality_hash=sha256:a12b7cb43c9d9134b5bb1b35e9096b66775d9e92e7611d1cc92b02edd6782a87
fixture_shape=67 entries; 6 usable; 61 error-shaped; 69 lines
privacy_email_scan=3 fixture lines contain the preserved masked value gxxxxxxxxxxxx@gmail.com
privacy_home_scan=0 unexpected matches
privacy_secret_scan=5 matches, all CLI error-message vocabulary rather than secret values
build_command=git diff --check
build_exit_code=0
build_output_hash=sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
scope=README.md, contents/code/UsageModel.js, docs/cli-contract-capture.md, tests/UsageModelTest.qml, tests/fixtures/codexbar-usage-capture.json, plus change planning artifacts
verdict=pass_with_warnings
warnings=fixture intentionally preserves already-redacted masked Gmail values; no newly introduced secret was found
```

### Issues Found

**CRITICAL**: None.

**WARNING**:
1. The compact fixture intentionally preserves the already-redacted `gxxxxxxxxxxxx@gmail.com` values from the user-supplied source. This differs from the capture document's generic `redacted@example.com` example and leaves a masked Gmail domain visible, but fresh value equality proves no verification/apply-time rewrite occurred, and no newly introduced credential or unredacted secret was found.

**SUGGESTION**: None.

### Verdict

**PASS WITH WARNINGS**

All 23 tasks are complete, all 2 requirements and 25 actual scenarios have passing evidence, all required commands exited 0, Strict TDD evidence is coherent, and implementation matches the design. The only finding is the intentional masked-email privacy caveat.
