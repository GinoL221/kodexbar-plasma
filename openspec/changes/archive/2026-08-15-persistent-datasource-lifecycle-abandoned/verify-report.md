```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:1824a3ae91ddeb013338a6fcd7ffbe1ea8696b3c3d3b7ce2e1bcc2b59629581d
verdict: fail
blockers: 5
critical_findings: 5
requirements: 0/4
scenarios: 10/14
test_command: ./scripts/run-qml-tests.sh
test_exit_code: 0
test_output_hash: sha256:07b7a2e994810d59476722a87a9018afc0522127ee45fe6b08e0873f3e375034
build_command: git diff --check
build_exit_code: 0
build_output_hash: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

## Verification Report

**Change**: `persistent-datasource-lifecycle`  
**Version**: N/A  
**Mode**: Strict TDD  
**Artifact store**: Hybrid (OpenSpec + Engram)  
**Runtime attempt**: Authenticated continuation of native token `sha256:65475d142f6efa58243c6964d6ddb5c4999b0f97b6c979ae3b3900191c40b00b`; no new attempt or reset was acquired. Failed settlement bound this evidence revision and returned `blocked(maintainer_decision)`. Native `nextRecommended` is now `resolve-blockers`.  
**Source mutation**: None. Verification did not modify production source, tests, documentation, configuration, commits, branches, or PRs. Only this admitted report is persisted.

### Completeness

| Metric | Value |
|---|---:|
| Requirements total | 4 |
| Requirements fully compliant | 0 |
| Requirements incomplete | 4 |
| Scenarios total | 14 |
| Scenarios compliant | 10 |
| Scenarios partial | 2 |
| Scenarios failing | 2 |
| Tasks total | 11 |
| Tasks complete | 11 |
| Tasks incomplete | 0 |

All task checkboxes are `[x]`, and native status independently reported 11/11 complete before execution. Task completion does not override the substantive spec and test-quality failures below.

### Build & Tests Execution

**Configured test command**: ✅ exit 0  
**Command**: `./scripts/run-qml-tests.sh`  
**Output hash**: `sha256:07b7a2e994810d59476722a87a9018afc0522127ee45fe6b08e0873f3e375034`

```text
UsageModel: 8 passed, 0 failed, 0 skipped
UsageControllerFixture: 11 passed, 0 failed, 0 skipped
SettingsInteraction: 7 passed, 0 failed, 0 skipped
Total QtTest outcomes: 26 passed, 0 failed, 0 skipped
All 16 launched QML harnesses returned success, including lifecycle argv and PID-termination checks.
```

The current runner has **26**, not 25, QtTest outcomes and launches **16**, not 15, QML harnesses. The apply-progress counts are stale after the mixed-provider test was added. The settings suite emits the pre-existing offscreen `i18n`/`i18np` `ReferenceError` warnings while still passing.

**Configured build command**: ✅ exit 0  
**Command**: `git diff --check`  
**Output hash**: `sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` (exact empty output)

**Coverage**: ➖ Not available; no coverage tool is configured.

### TDD Compliance

| Check | Result | Details |
|---|---|---|
| TDD evidence reported | ✅ | `apply-progress.md` contains RED, GREEN, triangulation, safety-net, and refactor evidence. |
| All behavioral tasks have tests | ✅ | Named QtTest files and executable harnesses exist. |
| RED confirmed | ⚠️ | Files exist, but repository history cannot independently prove RED ordering and the standalone assertion helper can mask failures. |
| GREEN confirmed | ❌ | The runner exits 0, but a passing harness contradicts its own current nonzero-exit assertion because `Qt.exit(1)` does not abort the callback before a later `Qt.exit(0)`. |
| Triangulation adequate | ❌ | Real callback wiring never receives a captured older generation; helper-only stale-generation tests do not exercise the live wiring defect. |
| Safety net for modified files | ✅ | Apply evidence records baseline runner coverage for modified files and N/A for the new lifecycle harness. |

**TDD Compliance**: 3/6 checks passed.

### Test Layer Distribution

| Layer | Tests/flows | Files | Tools |
|---|---:|---:|---|
| Unit/QtTest functional cases | 20 | 3 | `qmltestrunner` |
| Integration harness flows | 16 | 16 | `qml6` + executable DataSource engine |
| Automated live Plasma E2E | 0 | 0 | Not present |
| Manual live observation | 1 | N/A | User-provided `plasmawindowed` evidence |

The manual evidence reports populated Codex, Claude, OpenCode Go, Gemini, and Copilot rows plus a compact `100%` summary. It is recorded as user-provided corroboration, not as a test executed by this verifier and not as the fixture-backed `plasmawindowed` scenario required by the delta spec.

### Changed File Coverage

Coverage analysis skipped — no coverage tool is configured.

### Assertion Quality

| File | Assertion | Issue | Severity |
|---|---|---|---|
| `tests/UsageControllerFailureHarness.qml` | `assert(controller.phase === "error", ...)` after `complete(..., "[]", 7)` | Current production produces `noData`, yet the full runner exits 0 because the helper calls `Qt.exit(1)` without aborting and execution reaches final `Qt.exit(0)`. | CRITICAL |
| Standalone `*Harness.qml` files | custom `assert()` helpers | The common helper pattern schedules failure but does not throw/return; later success exits can mask earlier assertions. | CRITICAL |
| `tests/UsageControllerFixture.qml` | old-generation helper delivery | Exercises an explicitly supplied generation, while live `onNewData` passes mutable `root.activeGeneration`; it does not prove stale same-source callback rejection. | CRITICAL |

**Assertion quality**: 3 CRITICAL patterns, 0 WARNING.

### Quality Metrics

**Linter**: ➖ Not configured  
**Type Checker**: ➖ Not configured  
**Whitespace/build check**: ✅ `git diff --check` passed

### Spec Compliance Matrix

| Requirement | Scenario | Runtime/static evidence | Result |
|---|---|---|---|
| Live Plasma lifecycle acceptance | Live successful lifecycle | Offscreen fixture lifecycle passed and user-provided live real-provider evidence shows Ready data, but no verifier-run fixture-backed `plasmawindowed` test covers the exact scenario. | ⚠️ PARTIAL |
| Authoritative all-provider request | Valid request | Lifecycle harness and shell argv assertion passed exactly one `usage --provider all --format json --json-only` invocation after exact preflight. | ✅ COMPLIANT |
| Authoritative all-provider request | Invalid path | QtTest plus real executable preflight harnesses passed missing, relative, and non-executable rejection. | ✅ COMPLIANT |
| Authoritative all-provider request | Successful command completion | QtTest/failure harness evidence accepts numeric and string zero, commits Ready, and releases. | ✅ COMPLIANT |
| Authoritative all-provider request | Nonzero command completion | Production parses and commits usable non-empty stdout even when exit is nonzero; the current QtTest explicitly expects that behavior, contradicting the required no-commit Error outcome. | ❌ FAILING |
| Global states and CLI failures | Request lifecycle | Passing fixture/lifecycle/runtime harnesses cover continuous Loading and terminal release with no partial commit. | ✅ COMPLIANT |
| Global states and CLI failures | Watchdog timeout | QtTest and lifecycle harnesses pass frozen 120-second semantics, exact message, release, and retained snapshot. | ✅ COMPLIANT |
| Global states and CLI failures | Empty stdout | QtTest passes the exact `CodexBar CLI returned no output.` error without timeout text. | ✅ COMPLIANT |
| Global states and CLI failures | Empty response | QtTest passes valid `[]` to No data and atomic snapshot replacement. | ✅ COMPLIANT |
| Global states and CLI failures | Failure retains snapshot | Runtime tests cover command, malformed, empty, and timeout retention, but no passing runtime test starts from a snapshot and then proves path-failure retention. | ⚠️ PARTIAL |
| Refresh and concurrency | Invalid interval | Refresh helper and settings QtTests pass integer 1–3600 acceptance and invalid-value correction. | ✅ COMPLIANT |
| Refresh and concurrency | Overlapping triggers | QtTest/lifecycle harnesses pass one active request and one post-release coalesced follow-up. | ✅ COMPLIANT |
| Refresh and concurrency | Retry after timeout | QtTest passes one new Loading generation with the previous snapshot retained. | ✅ COMPLIANT |
| Refresh and concurrency | Stale callback invalidation | Helper tests pass supplied stale metadata, but live DataSource callbacks substitute current `activeGeneration`, so an old same-source callback can be misclassified as current after reconnect. | ❌ FAILING |

**Compliance summary**: 10/14 scenarios compliant; 2 partial; 2 failing. No requirement is fully compliant because each of the four requirements contains at least one noncompliant or partial scenario.

### Correctness (Static Evidence)

| Requirement/contract | Status | Notes |
|---|---|---|
| Persistent stage-specific DataSources | ✅ Implemented | Two declared executable DataSources replace request-scoped dynamic objects. |
| Exact CLI/preflight boundary | ✅ Preserved | Exact quoted `test -x` and exact all-provider argv remain unchanged; no provider/auth/fetch implementation was introduced. |
| Timeout and snapshot semantics | ⚠️ Partial | Timeout is frozen per generation and snapshots survive tested failures; path-after-snapshot lacks covering runtime evidence. |
| Coalescing and release ordering | ✅ Implemented | One active generation and one post-release follow-up remain; preflight-to-command is deferred with `Qt.callLater`. |
| Mixed provider failures | ❌ Spec contradiction | Non-empty stdout with nonzero status is normalized and can commit usable providers, while the current delta spec requires no commit and a nonzero-command Error. |
| Stale generation guard | ❌ Incorrect wiring | `onNewData` passes mutable `root.activeGeneration` rather than the generation captured when the source was connected. |
| Standalone lifecycle fixture | ✅ Implemented | The fixture accepts exact argv, emits valid JSON directly, and supports blocking PID mode for termination proof. |

### Coherence (Design)

| Decision | Followed? | Notes |
|---|---|---|
| Persistent preflight and command DataSources | ✅ Yes | Declared stage-specific children are present. |
| Deferred guarded preflight-to-command transition | ✅ Yes | `Qt.callLater` rechecks activity/generation before command start. |
| Record DataSource, stage, source, and generation per connection | ❌ No | Generation is not captured by the signal callback; it is read from mutable current state. |
| Commit only fully successful command output | ❌ No | Nonzero commands with usable stdout now commit providers. |
| Release metadata before disconnect and preserve coalescing | ✅ Yes | Stage metadata/watchdog are cleared before disconnect; queued follow-up starts after release. |
| Preserve external CLI/provider/UI scope | ⚠️ Mostly | Command/provider/UI boundaries are preserved, but nonzero command semantics changed without a matching spec/design update. |

### Issues Found

**CRITICAL**:

1. `UsageController.qml:172-200` accepts and commits usable non-empty stdout for a nonzero exit code, directly contradicting the normative Nonzero command completion scenario and design statement that only complete success commits.
2. `UsageController.qml:262-272` supplies mutable `root.activeGeneration` to callbacks instead of a connection-captured generation. After reconnecting the same persistent DataSource/source, an older callback can pass every current guard.
3. The exact fixture-backed live `plasmawindowed` scenario has no covering test executed by this verifier. User-provided real-provider screenshots are honest manual evidence, but they are not an automated covering test and do not use the specified fixture.
4. Failure-retains-snapshot is only partially runtime-covered; path failure after a committed snapshot has no passing covering test.
5. Standalone harness assertion helpers can mask failures. The full runner exits 0 even though `UsageControllerFailureHarness.qml` expects Error for `"[]"` plus exit 7 while current production yields No data.

**WARNING**:

1. Apply-progress reports 25 QtTest outcomes and 15 harnesses; the current runner produces 26 QtTest outcomes and launches 16 harnesses.
2. Pre-existing offscreen `i18n`/`i18np` `ReferenceError` warnings remain in `SettingsInteractionTest.qml`; they did not fail the suite.
3. The repository contains broad pre-existing staged/untracked work, so Git cannot isolate this change as a clean standalone diff; source inspection found no provider, authentication, fetching, command-argv, timeout-policy, or UI redesign beyond the identified nonzero semantic deviation.

**SUGGESTION**: None. Independent verification does not fix source, start another review, reset/acquire another attempt, archive, commit, or open a PR.

### Gentle AI Operations Resolution

Gentle AI CLI `2.3.0` matches the `Verification envelope parsing` and `SDD attempt/runtime authority` rows in `references/version-matrix.md`. `references/verification-envelope.md` and `references/review-lifecycle.md` were applied. Native status, attempt token, settlement result, and `nextRecommended: resolve-blockers` were preserved unmodified; no model/provider/profile/effort setting was changed.

### Canonical Verification Evidence Preimage

The following exact bytes, including the final newline, hash to the envelope `evidence_revision`:

```text
schema=gentle-ai.verification-evidence-preimage/v1
change=persistent-datasource-lifecycle
runtime_attempt_token=sha256:65475d142f6efa58243c6964d6ddb5c4999b0f97b6c979ae3b3900191c40b00b
runtime_attempt_work_unit=persistent-datasource-lifecycle-verify
candidate_identity=sha256:789563e33e5bd2624338db569013959c70f9e3635843fecb207e50d9c7289d76
candidate_tree=3b391157c7b08ab2ecd05b3f829eb2983f093d0a
requirements_total=4
scenarios_total=14
tasks_complete=11/11
test_output_hash=sha256:07b7a2e994810d59476722a87a9018afc0522127ee45fe6b08e0873f3e375034
build_output_hash=sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
manual_live_plasma_smoke=user_provided_populated_real-provider-rows_and_compact-100-percent
verdict=fail
critical_findings=live-plasma-scenario-not-runtime-covered,nonzero-output-spec-contradiction,path-snapshot-runtime-gap,stale-generation-not-captured,harness-exit-masking
file_sha256=edc81bb7c996c37f384b745fb050e9f9e75635cbf761a1d044e7a3fbe463a359 openspec/changes/persistent-datasource-lifecycle/proposal.md
file_sha256=7d2f9b95920ef0d9319826e6fb6e5d3b464d11f009955b3c8210d7e62f2cc958 openspec/changes/persistent-datasource-lifecycle/specs/provider-usage-display/spec.md
file_sha256=6e89987339dd96e4c534c8b618bd6ca6792d470850a3b77f9eff3d6b376a22dd openspec/changes/persistent-datasource-lifecycle/design.md
file_sha256=a946d71eff75de236f4ebb51db910437ba748c80c8a56f851c101ea83f3f5de1 openspec/changes/persistent-datasource-lifecycle/tasks.md
file_sha256=72d7ee0f1a523ec7d9aa38499bb7cf42b0996461bdf29abf5b9ec1c9c412fa49 openspec/changes/persistent-datasource-lifecycle/apply-progress.md
file_sha256=bf0735451470d79e175503f4a33efb97e1756cdc4fe9740e210a2dd5a5bbf4d4 openspec/config.yaml
file_sha256=f830feeb34234845d945c81817158057644e6fbc311a08cb3be15a1aa3e81d14 contents/ui/UsageController.qml
file_sha256=f0727022b1b80af9e9cbdf4098a1c27d9aea0d295d122ed911b65803a36fc459 contents/code/UsageModel.js
file_sha256=e0a46d57a6ce95783b25b10c5c717d2c5b0776da6d4e043905fb8e5d5f6ebb3b tests/UsageModelTest.qml
file_sha256=81b77434db34c6d35add02e6d755e9d4076eb3a8320a4367244d83cbfd8e7466 tests/UsageControllerFixture.qml
file_sha256=e9a92f434a217dfb962b766c2019eb9a3f40714002f305226382517570a9b1bd tests/UsageControllerFailureHarness.qml
file_sha256=b759ad63161068105ec3d8a515382a069e048d887c40132d7a2e3ea7abd4c755 tests/UsageControllerLifecycleHarness.qml
file_sha256=b06ed0f23782258bbcae2ae61320c1a26a9a79cc0a23335fcac0bc21be1862e9 tests/UsageControllerDataSourceLifecycleHarness.qml
file_sha256=4c5e670e9c1cbc3466b761c441fb1f0fd4a7882c42d3a33c4f787313d83e9349 tests/UsageControllerTerminationHarness.qml
file_sha256=c9932e3c5368f7cb3a1e07656380f49699908799a17173b8ddad25a916f74f93 tests/UsageControllerPreflightHarness.qml
file_sha256=a9cfa2d592fb225c3f2cc7781d176bb3245727c4babb6cda6f7cd320a508afdd tests/UsageControllerPathCheckHarness.qml
file_sha256=6d9a200385e686b082ec50309a6a30841a4682c95cad81727697b4da75ab961c tests/RefreshIntervalHarness.qml
file_sha256=830c87fd5e6f19b66bbc417c536ff6152db91eead5c97d77583e8a7ba24e1943 tests/SettingsInteractionTest.qml
file_sha256=5dc1f55a42cf9ccf7c2df5798bb95234af69636a64ce3ace09fd13a15d34ae71 tests/fixtures/codexbar-lifecycle-fixture.sh
file_sha256=b886810418f5b04a2485112f3a8f0558e9ed7d08752faa5a22d8e4ac6baf0ea0 scripts/run-qml-tests.sh
file_sha256=75b3a2263eb4794c0d38f24753926dfa82950921f00a4be5ed1b6cb2996e65ea docs/live-plasma-smoke.md
```

### Verdict

**FAIL**

The test/build commands exit 0 and the persistent lifecycle largely stays inside the CLI/UI boundary, but five critical blockers prevent spec-driven acceptance. Native settlement is `blocked(maintainer_decision)`; no new attempt or reset was made.
