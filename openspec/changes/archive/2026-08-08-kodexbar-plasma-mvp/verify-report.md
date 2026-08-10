```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:922b80de63d0fce3c6bb4c28d151b7151b6bf884302022602dc62de8a432c62c
verdict: pass_with_warnings
blockers: 0
critical_findings: 0
requirements: 8/8
scenarios: 12/12
test_command: timeout 15s env QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/UsageModelHarness.qml
test_exit_code: 0
test_output_hash: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
build_command: git diff --check
build_exit_code: 0
build_output_hash: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

## Verification Report

**Change**: `kodexbar-plasma-mvp`  
**Version**: N/A  
**Mode**: Standard (Strict TDD disabled; `qmltestrunner` unavailable)  
**Artifact store**: Hybrid (OpenSpec + Engram)  
**Runtime attempt**: `proceed`; work unit `verify-final-2`; token `sha256:82a922ec0c1f25e62b403f926c0e3e234003e6d14c0a6cb36d4648b0fd36345d` authenticated against native generation 18.  
**Source mutation**: None; only the admitted hybrid verification report may be persisted.

### Completeness

| Metric | Value |
|---|---:|
| Requirements total | 8 |
| Requirements fully compliant | 8 |
| Scenarios total | 12 |
| Scenarios compliant | 12 |
| Tasks total | 11 |
| Tasks complete | 11 |
| Tasks incomplete | 0 |

All task checkboxes 1.1–3.4 are `[x]` in `tasks.md`. Native SDD status independently reports 11/11 complete, and cumulative apply-progress observation `#3905` revision 16 records the authorized correction and no remaining tasks.

### Build & Tests Execution

**Strict-envelope test command**: ✅ exit 0  
**Output hash**: `sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` (exact empty output)

**Complete available QML/runtime suite**: ✅ exit 0  
**Output hash**: `sha256:97265c5360b41a18711c2dbf638d0abb6c700c48023f5cd73de3671e20fe8093`  
**Output bytes**: 557

```text
qmltestrunner unavailable; QtTest files skipped
PASS tests/UsageModelHarness.qml
PASS tests/UsageControllerHarness.qml
PASS tests/UsageControllerLifecycleHarness.qml
PASS tests/UsageControllerPreflightHarness.qml
PASS tests/UsageControllerPathCheckHarness.qml
PASS tests/UsageControllerFailureHarness.qml
PASS tests/RefreshIntervalHarness.qml
PASS tests/CompactUsageButtonHarness.qml
PASS tests/MainCompactHarness.qml
PASS tests/ProviderRowHarness.qml
PASS tests/ErrorSummaryHarness.qml
PASS tests/UsageControllerTerminationHarness.qml (process terminated)
```

The termination gate produced a PID in `/tmp/opencode`, disconnected the executable DataSource, and passed only after `kill -0` confirmed the process was no longer alive. The temporary PID file was removed.

**Strict-envelope build command**: ✅ exit 0  
**Output hash**: `sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` (exact empty output)

**Complete build/config/scope/package smoke**: ✅ exit 0  
**Output hash**: `sha256:ae75dcf91e00307431ef28159a9f0c026addcdabba84b11bee7e6ea66a0ab07f`  
**Output bytes**: 528

```text
PASS XML syntax
PASS XML/config contract
PASS config smoke (expected live timeout 124)
PASS git diff --check
PASS scope scans compact=1 fixed_command=1 scroll_views=1 prohibited=0 source_remaps=0
PASS protected-path staged-baseline check
/home/ginopc/.local/share/plasma/plasmoids/org.kde.plasma.kodexbar.plasma/ instalado con éxito
PASS package install
PASS plasmawindowed smoke (expected live timeout 124)
/home/ginopc/.local/share/plasma/plasmoids/org.kde.plasma.kodexbar.plasma/ desinstalado con éxito
PASS package remove
```

| Check | Exit | Interpretation |
|---|---:|---|
| `command -v qmltestrunner` | 1 | Unavailable; the two QtTest files could not run through `qmltestrunner`. |
| Eleven offscreen `qml6` harnesses | 0 | Model, controller, lifecycle, preflight/path, failure, interval, compact button/summary, provider row, and error summary passed. |
| Executable DataSource termination gate | 0 | `disconnectSource()` terminated the long-running fixture process. |
| XML syntax and exact KConfig contract | 0 | Exactly path and refresh interval entries exist; interval default/min/max are 60/1/3600. |
| Config QML smoke | 124 | Expected-live timeout after 12 seconds. |
| `git diff --check` | 0 | No whitespace errors. |
| Scope and protected-path scans | 0 | One fixed CLI command, one popup scroll surface, no prohibited behavior/remapping, and no unstaged protected-path delta. |
| Package install | 0 | Plasma applet installed. |
| Offscreen `plasmawindowed` smoke | 124 | Expected-live timeout after 12 seconds. |
| Package remove | 0 | Installed applet removed successfully. |

**Coverage**: ➖ Not available; configured threshold is 0%. No coverage tool or `qmltestrunner` is available.

### Spec Compliance Matrix

| Requirement | Scenario | Runtime evidence | Result |
|---|---|---|---|
| Authoritative all-provider request | Valid request | `UsageControllerHarness.qml` passed exact POSIX-quoted fixed-command construction, single active request, and no added arguments; scope scan found one literal command. | ✅ COMPLIANT |
| Authoritative all-provider request | Invalid path | `UsageControllerHarness.qml`, `UsageControllerPreflightHarness.qml`, and real executable-engine `UsageControllerPathCheckHarness.qml` passed relative, missing, and non-executable path blocking with actionable errors. | ✅ COMPLIANT |
| Provider presentation | Heterogeneous providers | `UsageModelHarness.qml` and `ProviderRowHarness.qml` passed nullable/raw fields, mapped and omitted windows, exact reset/source values, CLI order, themed fallback icon, and 160px geometry. | ✅ COMPLIANT |
| Deterministic compact summary | Percentage tie | `UsageModelHarness.qml` and `MainCompactHarness.qml` passed strict-greatest selection, Session priority, and first-provider ordering. | ✅ COMPLIANT |
| Deterministic compact summary | Invalid percentage | `UsageModelHarness.qml` passed null, nonnumeric, and non-finite percentage rejection and asserted that no compact value is invented. | ✅ COMPLIANT |
| Global states and CLI failures | Request lifecycle | `UsageControllerHarness.qml`, `UsageControllerLifecycleHarness.qml`, `UsageControllerFailureHarness.qml`, and `MainCompactHarness.qml` passed Loading/Error, timeout, malformed JSON, nonzero exit, manual-retry availability in the native surface, and committed-snapshot retention. | ✅ COMPLIANT |
| Global states and CLI failures | Empty response | `UsageControllerFailureHarness.qml` passed valid `[]` → `noData` and atomic replacement of the prior snapshot. | ✅ COMPLIANT |
| Mixed provider failures | Mixed result | `UsageModelHarness.qml` retained usable providers while separating errors; `ErrorSummaryHarness.qml` passed collapsed/bounded 20-of-23 disclosure behavior in narrow geometry. | ✅ COMPLIANT |
| Refresh and concurrency | Invalid interval | `RefreshIntervalHarness.qml` passed exact 1, 9, and 3600 acceptance plus rejection of zero, negative, string, and fractional values; the loaded native SpinBox is bounded to 1–3600. | ✅ COMPLIANT |
| Refresh and concurrency | Overlapping triggers | `UsageControllerHarness.qml` and `UsageControllerLifecycleHarness.qml` passed one active request, one queued follow-up, timeout invalidation, and stale-completion rejection. | ✅ COMPLIANT |
| Native and accessible UI | Keyboard and narrow layout | `CompactUsageButtonHarness.qml` loaded the native `QQC2.ToolButton`, obtained active focus under `Qt.StrongFocus`, asserted accessible status text, and passed native action activation; provider/error harnesses passed narrow geometry and labels. | ✅ COMPLIANT |
| MVP exclusions | Provider failure guidance | Error rendering harnesses, README inspection, and runtime scope scans passed: guidance stays informational and no auth/cookie/reset action is implemented. | ✅ COMPLIANT |

**Compliance summary**: 12/12 scenarios compliant; 0 failing; 0 untested; 0 partial.

### Correctness (Static Evidence)

| Requirement | Status | Notes |
|---|---|---|
| Authoritative all-provider request | ✅ Implemented | `UsageController.qml` quotes only the absolute path and appends exactly `usage --provider all --format json --json-only`; preflight blocks invalid paths. |
| Provider presentation | ✅ Implemented | Normalization preserves CLI order and raw nullable values, maps only primary/secondary/tertiary, and rows omit absent windows with a themed fallback icon. |
| Deterministic compact summary | ✅ Implemented | Strict-greatest finite-number selection preserves window and provider tie priorities; invalid percentages produce no candidate. |
| Global states and CLI failures | ✅ Implemented | Loading, Error, and No data paths are recoverable; malformed, timeout, nonzero, and empty-output failures do not commit invalid output; valid empty JSON commits `noData`. |
| Mixed provider failures | ✅ Implemented | Usable providers remain primary; failures are separate, collapsed, counted, and capped at 20 rendered entries. |
| Refresh and concurrency | ✅ Implemented | Runtime interval parsing accepts integral 1–3600 exactly and rejects invalid values; controller coalesces overlap and rejects stale completions. |
| Native and accessible UI | ✅ Implemented | Compact activation is a focusable native ToolButton with built-in keyboard semantics and accessible labeling; popup actions/disclosure use native controls and theme bindings. |
| MVP exclusions | ✅ Implemented | No cost/chart/switching/auth/cookie/provider/fallback/reset implementation or source-category remapping was found. |

### Coherence (Design)

| Decision | Followed? | Notes |
|---|---|---|
| Preserve external CLI boundary | ✅ Yes | One quoted all-provider command; no provider/auth/fetching implementation. |
| Split lifecycle, controller, model, and delegates | ✅ Yes | `main.qml`, `UsageController.qml`, `UsageModel.js`, `CompactUsageButton.qml`, `ProviderRow.qml`, and `ErrorSummary.qml` have focused responsibilities. |
| Retain committed snapshot and atomically replace | ✅ Yes | Failure/stale paths do not commit; runtime failure harness retained prior data and valid empty data replaced it atomically. |
| Preserve raw source/reset values | ✅ Yes | Model and row harnesses passed exact raw-value assertions. |
| One active request, coalescing, stale/watchdog protection | ✅ Yes | Controller/lifecycle harnesses and the executable termination gate passed. |
| Native, keyboard-accessible UI | ✅ Yes | Pointer-only `MouseArea` was removed; native ToolButton focus/action/accessibility evidence passed. |
| Positive 1–3600 refresh configuration | ✅ Yes | XML, KCM, runtime parser, and `main.qml` wiring agree; no 10-second floor remains. |
| Explicit MVP exclusions | ✅ Yes | Code, config, README, and scope scans remain coherent. |

### Explicit Boundary and Exclusion Audit

- Exactly one literal all-provider usage command exists in runtime QML.
- `main.qml` does not execute a DataSource directly; acquisition remains in `UsageController.qml`.
- No cost command, chart, provider/source switcher, auth/cookie automation, provider implementation, fallback probing, reset/account action, or `web`/`local` source remapping exists in runtime QML/JS.
- Exactly one `QQC2.ScrollView` exists across the popup runtime.
- README keeps OpenCode Go cookie sync manual and documents all MVP exclusions.
- `metadata.json`, `contents/config/config.qml`, and provider assets have no unstaged delta from the staged baseline.

### Limitations

- `qmltestrunner` is unavailable, so `UsageModelTest.qml` and `UsageControllerFixture.qml` were inspected but not executed through QtTest. Their normative cases are covered by the passing offscreen `qml6` harnesses listed above.
- Offscreen software rendering proves component loading, native control focus/action semantics, package lifecycle, and 12-second applet liveness. It cannot prove end-to-end keyboard traversal on a live Plasma desktop or switching between live light/dark themes; no such live-desktop evidence is claimed.
- Gentle AI CLI is `2.3.0`, while the loaded operations reference documents verification-envelope parsing at `2.1.11`. Native `2.3.0` status, acquire behavior, help text, and validator admission are authoritative; no lifecycle, model, provider, profile, or effort setting was changed.

### Issues Found

**CRITICAL**: None.

**WARNING**:

1. `qmltestrunner` remains unavailable; verification relies on the complete executable `qml6` harness suite.
2. Live desktop keyboard traversal and live light/dark theme switching remain outside what the offscreen environment can prove.
3. The installed Gentle AI CLI version exceeds the version documented by the loaded envelope-parsing reference; native 2.3.0 authority was preserved without substitution.

**SUGGESTION**: None. Independent final verification does not start correction, another reviewer, or archive.

### Canonical Verification Evidence Preimage

The following exact bytes, including the final newline, hash to the envelope `evidence_revision`:

```text
schema=gentle-ai.verification-evidence-preimage/v1
change=kodexbar-plasma-mvp
runtime_attempt_token=sha256:82a922ec0c1f25e62b403f926c0e3e234003e6d14c0a6cb36d4648b0fd36345d
runtime_attempt_work_unit=verify-final-2
candidate_identity=sha256:3549d27c48adae447ae902c8b0aafc934ee2991b2a0c4b77ab8015d1ce89c5c1
candidate_tree=c9b79786b739475e2b6fd2779216821c977f5f7b
apply_progress_observation=3905
apply_progress_revisions=16
requirements_total=8
scenarios_total=12
tasks_complete=11/11
test_output_hash=sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
build_output_hash=sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
aggregate_test_output_hash=sha256:97265c5360b41a18711c2dbf638d0abb6c700c48023f5cd73de3671e20fe8093
aggregate_build_output_hash=sha256:ae75dcf91e00307431ef28159a9f0c026addcdabba84b11bee7e6ea66a0ab07f
file_sha256=23373f8ae863e46b11485b96ff0cfbb2dcc7429973a7903127de02f6cf5510c5 openspec/changes/kodexbar-plasma-mvp/proposal.md
file_sha256=2af48f8252fdeedb1b243f9041081592047348645b5ea8f7a36d977bf2f4ca02 openspec/changes/kodexbar-plasma-mvp/specs/provider-usage-display/spec.md
file_sha256=c1991a944080c8fe031af7f44243ee1c2722ae8276186655482cc1ac16b159b8 openspec/changes/kodexbar-plasma-mvp/design.md
file_sha256=a9fac42d3a299bee2ebfbaa506d00e9aef4a80d66a04a2c69f46f89276ba7f06 openspec/changes/kodexbar-plasma-mvp/tasks.md
file_sha256=a6e68ff13ba0affe68f72def5e7e0a2e09f419ed8e0635b8797fac666790143e openspec/config.yaml
file_sha256=f0727022b1b80af9e9cbdf4098a1c27d9aea0d295d122ed911b65803a36fc459 contents/code/UsageModel.js
file_sha256=8065793e4c005ef21d28acdcde9c4b8292c65cb0ec55e3b4af0ffe0b9b8b6383 contents/code/RefreshInterval.js
file_sha256=704ef600d90d6a9db30030a5e073a773aefd04be7a999feb84c3b83441482cda contents/ui/UsageController.qml
file_sha256=036bf15933e574c584946a9a1bb841eb1efac6a59ecda9e521230f9aa586859b contents/ui/main.qml
file_sha256=f1a69084696390ebf436afde961d2988e6f901921f5944bd02a5e37a43881220 contents/ui/CompactUsageButton.qml
file_sha256=d875050a62a0372a8c95b0d48b1fd81338c82deda5999e04c1917c6956313199 contents/ui/ProviderRow.qml
file_sha256=569b00b679cbf69990088b228b71dda827c4df56c6a360f20063f5d7bcc26b0e contents/ui/ErrorSummary.qml
file_sha256=cfe7c8d6909fc71de1f50f3535b05588a92815a3c5ea677c0a54e25a5b75a91d contents/ui/config/configGeneral.qml
file_sha256=1d9f9aca2e1028029d4b8de7b18e741baf1f1c0a7df2c7d01c688b79f390fb7a contents/config/main.xml
file_sha256=e60b5897dd5ee402aaaea0f341a3c87cff65d86c09d5c7951aa41f59c77f2681 contents/config/config.qml
file_sha256=7f8ab4053a5541aaaba6e958c822dda17d9d0c0c5fae29d2908b2b18019602d8 README.md
file_sha256=4056aa825e913116eefb68d0063fd83ab6ba576c19dfd65c8783f31cc835d58f metadata.json
file_sha256=da762d22e2e9a7ba11eadf47eded0a3e6e3a96af6a5be65194d96f70a6a375dd tests/UsageModelHarness.qml
file_sha256=8edd520744dc76f9f00ef32d05b885b99456be49713499ef64ee1634a1ebf380 tests/UsageControllerHarness.qml
file_sha256=6b66290af7c58c18a097fbcffdc630af1e6e54fd163a3278f2b6708537e4dc2c tests/UsageControllerLifecycleHarness.qml
file_sha256=c9932e3c5368f7cb3a1e07656380f49699908799a17173b8ddad25a916f74f93 tests/UsageControllerPreflightHarness.qml
file_sha256=a9cfa2d592fb225c3f2cc7781d176bb3245727c4babb6cda6f7cd320a508afdd tests/UsageControllerPathCheckHarness.qml
file_sha256=5304b17e7b8d445e8ef4a5f83f5e81800427b2e9a9303223675d0222ce59a51e tests/UsageControllerFailureHarness.qml
file_sha256=df29b268094c32bf62499dcc4fdd0056753956513dcfa50a5039fc9b3fed2152 tests/RefreshIntervalHarness.qml
file_sha256=c08f15d8a9210ce01ad773f4d53e7831760b336a8a159dc95de0521989d57564 tests/CompactUsageButtonHarness.qml
file_sha256=2a72ca73ba79151ac097a51ea774dc1cce5ebaa09e0390a92af89971424bfd8e tests/MainCompactHarness.qml
file_sha256=1e2924485db5a33f36a295a4f0ed71ebf18d25781abfcdc44f7665a8b625ca0f tests/ProviderRowHarness.qml
file_sha256=8173906bc3cbdbf2cc0ba9dc03a95c1ec1d524108ab41a34dc6470d71fcd6546 tests/ErrorSummaryHarness.qml
file_sha256=6a03e5b469326d3f9f50d0d9d259de6be122b1fd284eda8bd2be8c1324fe1ada tests/UsageControllerTerminationHarness.qml
file_sha256=e0a46d57a6ce95783b25b10c5c717d2c5b0776da6d4e043905fb8e5d5f6ebb3b tests/UsageModelTest.qml
file_sha256=d5b24542a8f8c8388fb8aa30b0c98bcc9be2b491db9d31f4d1dc755345c6c740 tests/UsageControllerFixture.qml
file_sha256=135b9d0e05e13862486c34112060b79f7587b1710fc84efdd16a281c23527fe6 tests/fixtures/long-running-executable.sh
```

### Verdict

**PASS WITH WARNINGS**

All 11 tasks are checked, all 8 requirements and 12 normative scenarios have passing executable coverage, the authorized correction resolves the prior compact-activation and interval contradictions, and all available harness/config/scope/package checks pass. Warnings are limited to unavailable `qmltestrunner`, live-desktop keyboard/theme limitations, and the operations-reference version mismatch.
