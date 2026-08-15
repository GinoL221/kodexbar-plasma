```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:5e44d5d3e603b460c7ebed52ee8ae6a66487ae6da1b9746c3de48bac0037081e
verdict: pass
blockers: 0
critical_findings: 0
requirements: 2/2
scenarios: 9/9
test_command: ./scripts/run-qml-tests.sh
test_exit_code: 0
test_output_hash: sha256:a3564fe59beb76ee9422a94eb66ddb56d2c51131362792a019c0de2423c7c88d
build_command: git diff --check
build_exit_code: 0
build_output_hash: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

## Verification Report

**Change**: `provider-header-dynamic-details`
**Mode**: Strict TDD
**Artifact store**: Hybrid (OpenSpec + Engram)
**Verification pass**: Fresh, independent re-verification after a maintainer-authorized bounded remediation of the bare-email-address filter bypass reported in the prior FAIL (evidence revision `sha256:661132b822b4fa737d9ef69b7eb362f6373569e72c39cbf3852461c44b91eca9`).
**Prior verdict**: FAIL (8/9 scenarios, 1/2 requirements) — bare email values (e.g. `help@example.com`) in a detail row bypassed the exclusion filter because `normalizeWords()` stripped `@`/`.` before word matching.
**Independence note**: This pass reruns every command itself (does not reuse the prior session's captured outputs) and adds a freshly authored, standalone runtime probe (see below) distinct from the existing regression tests, to independently confirm the fix through the real UI path rather than trusting source inspection or the remediation's own tests alone.
**Native review**: Lineage `review-bare-email-remediated-01`, 4-lens canonical review (risk/resilience/readability/reliability), state `approved`, no BLOCKER/CRITICAL findings. Independently re-examined: the only substantive note (R1, risk lens) is that `validVersion()`/`validLoginMethod()` in `ProviderDetails.js` do not run the same exclusion filter as `acceptedDetails()`/`isValidRow()`/`isValidDetail()`. Verified this is (a) unchanged by this bounded remediation — it existed identically before and after the R7 fix, (b) consistent with `design.md`'s "Interfaces / Contracts" section, which scopes inspection-only exclusion checking to detail titles/rows only, not to version/login, and (c) not contradicted by the spec text, whose "Raw preservation authorizes only approved display fields" scenario reads "only version, login method, and valid non-excluded details" — "non-excluded" grammatically modifies "details", not "version, login method". Recorded as a SUGGESTION (pre-existing design scope, out of bounds for this remediation), not a blocker.

### Completeness

| Metric | Value |
|---|---:|
| Requirements total | 2 |
| Requirements fully compliant | 2 |
| Requirements incomplete | 0 |
| Scenarios total | 9 |
| Scenarios compliant | 9 |
| Scenarios failing | 0 |
| Tasks total | 23 |
| Tasks complete | 23 |
| Tasks incomplete | 0 |

Task count increased from the previously reported 22 to 23 because `tasks.md` now records `R7` (the bare-email remediation task), which is checked complete.

### Build & Tests Execution (all commands re-run fresh in this pass)

| Command | Result | Exit | Exact output hash |
|---|---|---:|---|
| `./scripts/run-qml-tests.sh` | ✅ Full suite: 49 pre-existing QtTest totals (16+11+22 across UsageControllerFixture/SettingsInteraction/UsageModelTest), `ProviderDetailsIntegrationTest.qml` 8/8 under both BreezeLight and BreezeDark, 9 fixture tests, 20 executable QML harnesses (including `ProviderDetailsHarness.qml`) — all pass | 0 | `sha256:a3564fe59beb76ee9422a94eb66ddb56d2c51131362792a019c0de2423c7c88d` |
| `./scripts/lint-qml.sh` | ✅ 58 accepted KDE translation warnings; no structural failure | 0 | `sha256:918b705c6f9d56fd799a321584325c1f05e1d855fd1bd15dfa9312b3ee284662` |
| `./scripts/validate-package.sh` | ✅ Isolated Plasma package validation passed | 0 | `sha256:3210c43b36c3907b177abe414b8081400aacfec7730ef6ed4decf961ae8de1b2` |
| `python3 -m unittest discover -s tests` | ✅ 42 tests passed | 0 | `sha256:d827ed0ccb38964178a4ef1390e61cdad5385af6b2fec7429cd982d075a413cc` |
| `python3 tests/test_cli_contract_fixture.py` | ✅ 9 tests passed | 0 | `sha256:7c758af7411e05fc2e6c4fb89045f7a03d9a5957d5305092903a23a66373d034` |
| **Independent bare-email UI probe** (freshly authored `qmltestrunner` test, not reused from any prior file) | ✅ 3/3 passed — bare email in detail title, row label, and row value, each on a distinct synthetic detail on a real `ProviderRow` instance, all rejected end-to-end; `acceptedDetails.length === 0` for all three | 0 | `sha256:bad6058cff66c75bd2825024ba35ae7104791bcd5a6271b46e2df901e4da9acc` |
| `git diff --check` | ✅ Empty output | 0 | `sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `git diff --exit-code -- contents/code/UsageModel.js contents/ui/UsageController.qml tests/fixtures/codexbar-usage-capture.json docs/cli-contract-capture.md` | ✅ Protected boundaries unchanged | 0 | `sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `git grep -n /home/ginopc -- tests` | ✅ No matches (expected exit 1) | 1 | n/a (no local-username leakage) |

**Independent probe methodology**: A standalone QML `TestCase` was authored in the scratchpad (not committed, not derived from `tests/ProviderDetailsHarness.qml` or `tests/ProviderDetailsIntegrationTest.qml`), temporarily copied into `tests/` only to satisfy QML's relative-import resolution, run via `qmltestrunner` against the real, unmodified `contents/ui/ProviderRow.qml` → `contents/ui/ProviderDetails.qml` → `contents/code/ProviderDetails.js` chain, and removed immediately after. `git status` was confirmed clean before and after (no residual files, no product/test code touched). The probe used its own provider id (`verify-probe-provider`) and placed `help@example.com` in three different structural positions (detail title, row label, row value) across three separate detail objects — a superset of the placements covered by the existing regression tests — and asserted zero survived to `acceptedDetails` and that no substring `help@example.com` appears anywhere in the rendered `ProviderRow`/`ProviderDetails` item tree after `expanded = true`.

### Root-cause closure check (malformed-value guard)

Confirmed by source inspection AND runtime evidence: `contents/code/ProviderDetails.js` now defines `emailAddressPattern` and `containsEmailAddress(text)` (lines 40–44) and calls it as the **first** check in `isRejectedText()` (lines 68–74), evaluated against the **original, unmodified text** — independent of and prior to `normalizeWords()`'s punctuation-stripping step that was the root cause of the prior bypass (`@`/`.` characters being replaced with whitespace before word-matching, turning `help@example.com` into the unrelated tokens `help`, `example`, `com`). This closes the exact defect reported in the prior FAIL: the malformed-value guard (`isRejectedText`) is fail-closed for bare email addresses regardless of case, subdomain, or `+tag` complexity (verified with `Help@Example.COM` and `user.name+tag@sub.example.co.uk` in the unit harness, and with plain `help@example.com` in title/label/value positions in both the integration test and my independent probe).

### Spec Compliance Matrix

| Requirement | Scenario | Passing/failing runtime evidence | Result |
|---|---|---|---|
| Conditional provider header metadata and dynamic details | Header metadata is conditional | `test_conditionalMetadataAndMalformedDetailsKeepUsageVisible`, `test_invalidMetadataIsOmittedWithoutPlaceholdersInRealProviderRows` pass under both Breeze schemes. | ✅ COMPLIANT |
| Conditional provider header metadata and dynamic details | Details are collapsed and accessible | `test_returnAndSpaceToggleRealDisclosureAccessibleState` passes; disclosure begins collapsed, Return/Space toggle, accessible description changes. | ✅ COMPLIANT |
| Conditional provider header metadata and dynamic details | Invalid details are safe | Malformed `details: { invalid: true }` row omits details while header/usage remain visible; harness malformed-shape variance passes. | ✅ COMPLIANT |
| Conditional provider header metadata and dynamic details | Expanded details remain bounded | `test_expandedOverHeightDetailsAreVerticallyReachableWithoutHorizontalOverflow` requires and moves the vertical scrollbar, keeps the last row reachable, horizontal bar stays disabled. | ✅ COMPLIANT |
| Conditional provider header metadata and dynamic details | Presentation enrichment preserves runtime boundaries | Model/controller/fixture/capture-doc diffs empty; exact CLI argv unchanged; full regression suite green. | ✅ COMPLIANT |
| Provider-focused exclusions | Missing commercial or reset data | Existing model/provider-row suites pass without fabricated commercial/reset data. | ✅ COMPLIANT |
| Provider-focused exclusions | Verbatim passthrough of unmodeled provider fields | `UsageModel` raw-preservation regression and fixture evidence pass unchanged. | ✅ COMPLIANT |
| Provider-focused exclusions | Raw preservation authorizes only approved display fields | **Now closed.** `test_maliciousProviderDisplaysOnlyApprovedFields` (9-entry excluded-values list including `help@example.com`) passes end-to-end through the real component chain; my independent, freshly authored probe additionally confirms bare-email rejection when placed in a detail title and in a row label (positions not exercised by the existing malicious-provider fixture), all through the real, unmodified `ProviderRow`. | ✅ COMPLIANT |
| Provider-focused exclusions | Real capture fixture provenance and redaction | 9/9 fixture tests pass (pinned bytes, JSON shape, path/date, version/binary evidence, leaf-only redaction, sensitive-pattern gates). | ✅ COMPLIANT |

**Compliance summary**: 9/9 scenarios compliant; 0/9 failing; 2/2 requirements fully compliant.

### Correctness (Static + Runtime Evidence)

| Contract | Status | Evidence |
|---|---|---|
| Read-only presentation sanitizer | ✅ Implemented | No mutation of `raw`; sanitized arrays/objects only. |
| Deterministic version/login source | ✅ Implemented | Only non-empty `raw.version`/`raw.usage.loginMethod` accepted; identity login ignored. |
| Keyword-based detail exclusions | ✅ Implemented | Camel-case split, separator normalization, excluded-word/phrase checks remain deterministic and unchanged by the remediation. |
| Email-address exclusion (previously defective) | ✅ **Fixed and independently verified at runtime** | `containsEmailAddress()` matches against original text before normalization; unit, integration, and my independent probe all confirm zero bypass. |
| Native disclosure | ✅ Implemented | Checkable `QQC2.ToolButton`, focus, Return/Space, accessible text, theme colors. |
| Selected-provider-only enrichment | ✅ Implemented | Gated by `!compact && !summary`. |
| Bounded popup structure | ✅ Implemented | 44-grid-unit bound, `AlwaysOff` horizontal, `AsNeeded` vertical. |
| Runtime boundaries | ✅ Preserved | Model/controller/CLI-argv diffs empty. |
| Fixture/privacy boundary | ✅ Preserved | Fixture/doc unchanged; no local username in tracked tests. |
| `validVersion()`/`validLoginMethod()` lack exclusion filter | ⚠️ Pre-existing, out of scope | Present before and after this remediation; consistent with design.md's scoping of exclusion checks to detail titles/rows only; not contradicted by spec text. Recorded as SUGGESTION for a future change, not this one. |

### Coherence (Design)

| Design decision | Followed? | Notes |
|---|---|---|
| Separate `ProviderDetails.js` sanitizer | ✅ Yes | |
| Native `ProviderDetails.qml` disclosure | ✅ Yes | |
| Selected-only enrichment | ✅ Yes | |
| Single login source | ✅ Yes | |
| Provider-neutral fail-closed filtering | ✅ Yes (now fully) | Bare-email signature is now detected structurally against original text, closing the previously reported gap; word-list filtering for named exclusions is unchanged and still fail-closed. |
| Bounded scrolling | ✅ Yes | |
| Unchanged model/controller/CLI boundaries | ✅ Yes | |
| Preserve Phase 1 fixture/doc | ✅ Yes | |
| Review workload exception | ✅ Intentional | Maintainer-approved `size:exception` remains recorded; this remediation added only 11 net production lines plus targeted regression coverage. |

### Issues Found

**CRITICAL**

None.

**WARNING**

None.

**SUGGESTION**

1. `validVersion()`/`validLoginMethod()` in `contents/code/ProviderDetails.js` do not apply the same `isRejectedText()` exclusion filter as the details path. This is a pre-existing design gap (unchanged by this remediation, consistent with `design.md`'s stated scope) rather than a defect in this change. A malicious CLI provider that set `raw.version` or `raw.usage.loginMethod` to a string containing an email address or excluded word would currently still render it. Recommend tracking as a follow-up if hardening version/login against the same exclusion contract is desired — out of scope for this bounded remediation.

### Verdict

**PASS**

The bare-email-address filter bypass reported in the prior FAIL (evidence revision `sha256:661132b822b4fa737d9ef69b7eb362f6373569e72c39cbf3852461c44b91eca9`) is confirmed fixed and closed: `containsEmailAddress()` now rejects bare email addresses against the original text before word-normalization, independently verified through (a) unit-level harness assertions, (b) the existing `ProviderDetailsIntegrationTest.qml` malicious-provider integration test, and (c) a freshly authored, independent runtime probe exercising the real `ProviderRow` → `ProviderDetails` → `ProviderDetails.js` chain with bare emails in three distinct structural positions. All 23 tasks are complete, the full regression suite (qmltestrunner, lint, package validation, Python unit/fixture tests) passes with exit 0, and all 9 spec scenarios across both requirements are compliant with passing runtime coverage. 2/2 requirements fully compliant, 9/9 scenarios compliant, 0 CRITICAL, 0 WARNING, 1 SUGGESTION (pre-existing, out-of-scope design note).

### Canonical Verification Evidence Preimage

The following exact UTF-8 bytes, including the final newline, hash to the envelope `evidence_revision`:

```text
schema=gentle-ai.verification-evidence-preimage/v1
change=provider-header-dynamic-details
verification_pass=independent-fresh-verification-post-bare-email-remediation
prior_evidence_revision=sha256:661132b822b4fa737d9ef69b7eb362f6373569e72c39cbf3852461c44b91eca9
review_lineage=review-bare-email-remediated-01
review_authority_state=approved
strict_tdd=true
task_progress=23/23
requirements=2/2
scenarios=9/9
test_command=./scripts/run-qml-tests.sh
test_exit_code=0
test_output_hash=sha256:a3564fe59beb76ee9422a94eb66ddb56d2c51131362792a019c0de2423c7c88d
lint_command=./scripts/lint-qml.sh
lint_exit_code=0
lint_output_hash=sha256:918b705c6f9d56fd799a321584325c1f05e1d855fd1bd15dfa9312b3ee284662
package_command=./scripts/validate-package.sh
package_exit_code=0
package_output_hash=sha256:3210c43b36c3907b177abe414b8081400aacfec7730ef6ed4decf961ae8de1b2
unittest_command=python3 -m unittest discover -s tests
unittest_exit_code=0
unittest_output_hash=sha256:d827ed0ccb38964178a4ef1390e61cdad5385af6b2fec7429cd982d075a413cc
fixture_test_command=python3 tests/test_cli_contract_fixture.py
fixture_test_exit_code=0
fixture_test_output_hash=sha256:7c758af7411e05fc2e6c4fb89045f7a03d9a5957d5305092903a23a66373d034
independent_email_probe_command=QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qmltestrunner -input tests/__scratch_independent_email_probe.qml -import . (freshly authored probe: bare email placed independently in detail title, row label, and row value across three synthetic details on a distinct real ProviderRow instance; not reused from prior session or prior test files; removed after run, tree left clean)
independent_email_probe_exit_code=0
independent_email_probe_output_hash=sha256:bad6058cff66c75bd2825024ba35ae7104791bcd5a6271b46e2df901e4da9acc
build_command=git diff --check
build_exit_code=0
build_output_hash=sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
boundary_diff_command=git diff --exit-code -- contents/code/UsageModel.js contents/ui/UsageController.qml tests/fixtures/codexbar-usage-capture.json docs/cli-contract-capture.md
boundary_diff_exit_code=0
boundary_diff_output_hash=sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
local_username_gate_command=git grep -n /home/ginopc -- tests
local_username_gate_exit_code=1
local_username_matches=0
coverage=not-configured
verdict=pass
critical_findings=0
file_sha256=sha256:8e8d966964a1f6e35f134e69d8441b0eb59bc36a71644c75806e2e1bcdfbbe0d openspec/changes/provider-header-dynamic-details/proposal.md
file_sha256=sha256:c5226ce9411736125fbe5c6b387dcdce24c50360be3b49fdceafa038d5eb0e79 openspec/changes/provider-header-dynamic-details/specs/provider-usage-display/spec.md
file_sha256=sha256:0ba66e23180b806d78bda1af49a54dda677c05c44355a2c80428f51a4499e78a openspec/changes/provider-header-dynamic-details/design.md
file_sha256=sha256:3275bddbf08bf5a65b352f44edebd78eec3d38960b6d703f7730c07d627434ae openspec/changes/provider-header-dynamic-details/tasks.md
file_sha256=sha256:205d6779cd1909c8e720d172132654318cfa6a8686e9bf9a527b4b9dece1a6ef openspec/changes/provider-header-dynamic-details/apply-progress.md
file_sha256=sha256:74a232828f38e410ff94d5862e6b048056f85a9c7667e407a6c9e17953e7ff10 contents/code/ProviderDetails.js
file_sha256=sha256:94f2c4de7950aefa19a2c57f1aec34b4a09dabf4f9e6366dee73124328e866f2 contents/ui/ProviderDetails.qml
file_sha256=sha256:db3c84043c83cdc72bbea0d24683bce2915d26878d907e11a082ba96bb7202d6 contents/ui/ProviderRow.qml
file_sha256=sha256:18aa714b459a07f8842654e98df4866136585de17b1e6a1f2907330be4c37467 contents/ui/main.qml
file_sha256=sha256:7615f84f6dda410660533feb2fece539e67fdf8ecdd6f256cc2494624093f713 contents/code/UsageModel.js
file_sha256=sha256:d1e2f7a799aba02fa1e26f6aa76dc6c8dc862e0a40c771d93f2929c05fda78a3 contents/ui/UsageController.qml
file_sha256=sha256:69aa0c3f9bc23e47542fa5ba8fbeab83dd464987b7de06552948adf5c56f5bf6 tests/ProviderDetailsHarness.qml
file_sha256=sha256:7e42e8d1037c965a28bd84017a5f6efa44dcde052470d36fa78f7ea59a631056 tests/ProviderDetailsIntegrationTest.qml
file_sha256=sha256:cf07a663a5be5dba93ef0d6f635d5c75f5b74150614df606b4cb385dd2953aa0 tests/test_cli_contract_fixture.py
file_sha256=sha256:884e2c16ebea661bde8e7c3bf18ee76ef693df34abe98b0d28f9d2883a5f5bde tests/test_bound_qml_components.py
file_sha256=sha256:46343115c0b1c82960147e1d9a16746c0b5f915d44f4d29a209be6f0aa290c0b tests/fixtures/codexbar-usage-capture.json
file_sha256=sha256:30d6d1e416a203acec1be64340530d9523b0db4892c22b207e16e2524b029f3d docs/cli-contract-capture.md
file_sha256=sha256:115323ceefb07d3b637c50bb2b1aef6e8a389cf2215c07d2d58fb9e78d3bacbb scripts/run-qml-tests.sh
file_sha256=sha256:1059f193a6fb5e06d05bac9c011c3cb2fe6d01de918932e1ec30849a09ee95fe README.md
file_sha256=sha256:5304216b5042b566d192577968b392eb21898f551f9465666591f380f6fd0ed6 docs/live-plasma-smoke.md
```
