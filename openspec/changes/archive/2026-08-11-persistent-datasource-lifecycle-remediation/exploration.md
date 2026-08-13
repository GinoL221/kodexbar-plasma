# Exploration: Persistent DataSource Lifecycle Remediation

## Current State

The historical change `persistent-datasource-lifecycle` was verified as FAIL with 5 critical blockers, 0/4 requirements compliant, and 10/14 scenarios passing. The committed baseline is `dca2671` (plus `d027c1e`). The historical verify report (`openspec/changes/persistent-datasource-lifecycle/verify-report.md`) is the authoritative FAIL verdict. Native settlement was `blocked(maintainer_decision)`.

The current code at `dca2671` has 291 lines in `UsageController.qml`, 15 standalone QML harnesses, 3 QtTest suites (27 outcomes), and a runner that admits 16 harnesses including the lifecycle fixture argv assertion and PID termination proof. The apply-progress records authorized remediation tasks 4.1–4.6 as complete, but the historical verify report was generated before those remediations were fully reconciled with the spec/design documents.

**Critical finding**: Three of the five blockers are partially or fully resolved in the current code but remain flagged because (a) the design document contradicts itself, (b) the verify report was generated against a pre-remediation file hash, or (c) the coverage exists but was not recognized by the verifier.

## Affected Areas

| File | Why it's affected |
|---|---|
| `openspec/changes/persistent-datasource-lifecycle/design.md` | Coherence table line 148 ("Commit only fully successful command output" marked ❌) contradicts interfaces line 46 (nonzero+usable stdout commits). Self-contradiction in the design document. |
| `contents/ui/UsageController.qml` | Lines 172-204 implement nonzero-with-usable-stdout commit behavior. Lines 268-288 use per-DataSource `connectionGeneration` property for stale callback rejection. No code defect found; test-only entry points prove the guard. |
| `tests/UsageControllerFailureHarness.qml` | Lines 52-59 assert phase==="ready" for nonzero+usable stdout, matching the current spec. The verify report flagged this against the original spec. No code change needed. |
| `tests/UsageControllerDataSourceLifecycleHarness.qml` | Lines 31-51 test path-failure-after-snapshot retention (Ready → missing path → snapshot retained). This coverage exists and passes but was not recognized by the verifier. |
| `tests/fixtures/codexbar-lifecycle-fixture.sh` | Fixture accepts exact argv and emits valid JSON. Used by DataSourceLifecycleHarness and TerminationHarness. No change needed. |
| `scripts/run-qml-tests.sh` | Admits 16 harnesses including DataSourceLifecycleHarness. No change needed. |
| `docs/live-plasma-smoke.md` | Documents fixture-backed and manual real-provider evidence paths. Spec allows manual when automation is infeasible. Formalize the provenance statement. |
| `openspec/changes/persistent-datasource-lifecycle/specs/provider-usage-display/spec.md` | Current spec (lines 36-39) allows nonzero+usable stdout to commit. This is the authoritative requirement. No change needed unless the remediation decides to revert to strict "no commit on nonzero". |
| All 15 standalone harnesses | Share assert-flag+finish() pattern. No actual masking exists in current code, but the pattern is fragile. Harden to prevent future regressions. |

## Analysis of the Five Blockers

### Blocker 1: Nonzero usable stdout semantics vs. spec/design

**Current state**:
- Spec (spec.md lines 36-39): "usable providers and provider errors commit atomically" for nonzero+usable stdout; "when stdout is empty, no output commits and a nonzero-command Error appears."
- Design interfaces (design.md line 46): "Fully parsed and normalized usable stdout replaces committedProviders/committedErrors even when a nonzero exit reports optional provider failures."
- Design coherence table (design.md line 148): "Commit only fully successful command output" marked ❌ No.
- Implementation (UsageController.qml lines 176-204): Nonzero+non-empty stdout parses and commits; nonzero+empty stdout fails with Error.

**Diagnosis**: The spec and design interfaces AGREE on the behavior. The design coherence table CONTRADICTS them. This is a documentation inconsistency, not a code defect.

**Remediation**: Update design.md coherence table to reflect the accepted nonzero-with-usable-stdout semantics. Change the decision row from ❌ to ✅ and update the description to match the interfaces section.

**Risk**: Low. This is a documentation-only change. No behavior change.

---

### Blocker 2: Connection-captured generation for stale callbacks

**Current state**:
- UsageController.qml lines 268-288: `onNewData` uses `connectionGeneration` (a property on each DataSource), NOT `root.activeGeneration`.
- `beginStage()` line 86 sets `dataSource.connectionGeneration = requestGeneration`.
- `releaseStage()` line 132 sets `dataSource.connectionGeneration = 0`.
- Test `test_liveCallbackDeliveryRejectsCapturedGenerationAfterSameSourceReconnect` (UsageControllerFixture.qml lines 82-106) uses `deliverLiveStageForTest` with an explicit old generation and proves stale rejection.

**Diagnosis**: The verify report (line 99) says "onNewData passes mutable root.activeGeneration rather than the generation captured when the source was connected." But the current code uses `connectionGeneration`, which IS captured per connection. The verify report was generated against file hash `f830feeb...` which may have been a pre-remediation version.

The current implementation is CORRECT for Qt's synchronous signal delivery:
1. First connection: `beginStage()` sets `connectionGeneration = gen1`.
2. Timeout/release: `releaseStage()` sets `connectionGeneration = 0`.
3. Reconnect: `beginStage()` sets `connectionGeneration = gen2`.
4. Old callback after disconnect: sees `connectionGeneration === 0`, rejected by `if (connectionGeneration !== 0)` guard.
5. New callback after reconnect: sees `connectionGeneration === gen2`, passes guard, then `isCurrentStage()` checks `generation === gen2` and `activeGeneration === gen2`, which pass.

The test-only `deliverLiveStageForTest` proves stale rejection by passing an explicit old generation that fails the `generation === requestGeneration` check in `isCurrentStage()`.

**Remediation**: No code change needed. Document the connection-scoped generation pattern and verify the test coverage is adequate. Optionally add a comment in UsageController.qml explaining the `connectionGeneration` lifecycle.

**Risk**: Low. The implementation is correct. Documentation-only change.

---

### Blocker 3: Verifier-run fixture-backed plasmawindowed acceptance

**Current state**:
- Spec (spec.md lines 5-12): "Automated fixture-backed Plasma-host execution is optional when the environment supports it; documented manual plasmawindowed evidence from a real provider response is acceptable when that exact fixture path cannot be automated."
- docs/live-plasma-smoke.md: Documents both fixture-backed and manual real-provider evidence paths.
- Verify report: "no verifier-run fixture-backed plasmawindowed test covers the exact scenario."

**Diagnosis**: The spec explicitly allows manual evidence when automation is infeasible. The documentation exists. The verifier flagged the absence of an automated test, but the spec does not require it.

**Remediation**: Formalize the provenance statement in docs/live-plasma-smoke.md to clearly state that manual evidence is the accepted path per the spec's own allowance. Optionally add a note in the spec or design explaining why automation is not feasible (requires Plasma runtime, not available in CI).

**Risk**: Low. Documentation-only change. No code change.

---

### Blocker 4: Path failure after a committed snapshot

**Current state**:
- UsageControllerDataSourceLifecycleHarness.qml lines 31-51: After reaching Ready with fixture data, changes commandPath to a missing path, requests refresh, and asserts the snapshot is retained.
- run-qml-tests.sh line 37: DataSourceLifecycleHarness is admitted.
- Apply-progress: "Fixture reaches Ready, exact provider is committed, missing-path refresh retains the snapshot, and the request is released."

**Diagnosis**: The coverage EXISTS and PASSES. The verify report said "no passing runtime test starts from a snapshot and then proves path-failure retention," but DataSourceLifecycleHarness does exactly this. The verifier may not have recognized this harness as covering the scenario, or the report was generated before the harness was added.

**Remediation**: No code change needed. Verify the harness runs and passes in the full runner. Document the coverage explicitly in the apply-progress or design.

**Risk**: None. Coverage already exists.

---

### Blocker 5: Assertion helpers that can mask failures

**Current state**:
- 15 standalone harnesses share the pattern:
  ```qml
  function assert(condition, message) {
      if (!condition) {
          console.error(...)
          assertionFailed = true
      }
  }
  function finish() { Qt.exit(assertionFailed ? 1 : 0) }
  ```
- 3 harnesses have direct `Qt.exit(1)` in timeout timers (DataSourceLifecycle, RefreshInterval, PathCheck) that bypass `finish()` — but these are genuine timeout failures.
- No harness has a direct `Qt.exit(0)` that bypasses `finish()`.
- The verify report said "Qt.exit(1) does not abort the callback before a later Qt.exit(0)" — but no such pattern exists in the current code.

**Diagnosis**: The assertion pattern is SAFE in the current code: if an assertion fails, `assertionFailed` is set, and `finish()` exits with code 1. No masking exists. However, the pattern is FRAGILE: a future refactor could introduce a direct `Qt.exit(0)` that bypasses `finish()`, masking earlier failures.

The verify report's specific concern about `UsageControllerFailureHarness.qml` expecting Error for `"[]"` + exit 7 is NO LONGER VALID: the harness now expects phase==="ready" for nonzero+usable stdout (matching the current spec).

**Remediation**: Harden the assertion pattern to prevent future regressions. Options:
1. Add `if (assertionFailed) return;` guard at the start of each test step (minimal change, prevents cascading assertions).
2. Make `assert()` throw an exception or call `Qt.exit(1)` immediately (breaks the batch-assertion pattern, requires restructuring).
3. Add a lint rule or code review checklist to prevent direct `Qt.exit()` calls outside `finish()`.

Recommendation: Option 1 (guard clause) is the least invasive and prevents the most likely regression.

**Risk**: Low. Guard clauses are additive and do not change existing behavior.

## Approaches

### Approach 1: Documentation-only reconciliation (RECOMMENDED)

Update design.md coherence table to match the spec/interfaces. Formalize manual evidence provenance in docs. Add assertion guard clauses to all 15 harnesses. No production code changes.

**Pros**:
- Minimal risk: no behavior changes.
- Addresses 4 of 5 blockers directly (blockers 1, 3, 4, 5).
- Blocker 2 is already resolved; document the pattern.
- Stays well within the 800-line review budget.
- Preserves the historical FAIL as authoritative; the remediation reconciles artifacts.

**Cons**:
- Does not add new test coverage (but coverage already exists).
- Does not automate plasmawindowed (but spec allows manual).
- Relies on the verifier accepting documentation updates as resolving the blockers.

**Effort**: Low. ~50-100 lines of documentation and test harness hardening.

### Approach 2: Full spec reversion to strict "no commit on nonzero"

Change the spec, design, and implementation to reject ALL nonzero exits (no commit, even with usable stdout). This reverts to the original design intent.

**Pros**:
- Aligns with the original design coherence table.
- Simpler semantics: nonzero = error, always.

**Cons**:
- Breaks the current behavior that accepts partial results from CodexBar CLI.
- Requires changing UsageController.qml, spec.md, design.md interfaces, and all tests that expect nonzero+usable stdout to commit.
- Loses the ability to display partial usage when some providers fail.
- Higher risk: behavior change affects the user-facing contract.
- Exceeds the 800-line budget when all test updates are counted.

**Effort**: High. ~200-300 lines of changes across spec, design, implementation, and tests.

### Approach 3: Add automated plasmawindowed test

Create a new integration test that runs `plasmawindowed` with the fixture and asserts Ready state. This would provide verifier-run fixture-backed acceptance.

**Pros**:
- Fully automates the plasmawindowed scenario.
- Removes the "manual evidence" caveat.

**Cons**:
- Requires Plasma runtime in CI, which may not be available.
- Complex to set up and maintain.
- The spec already allows manual evidence, so this is not required.
- High effort for low value (manual evidence is already accepted).

**Effort**: High. ~100-200 lines of new test infrastructure, plus CI configuration.

## Recommendation

**Approach 1: Documentation-only reconciliation** is recommended.

Rationale:
- 3 of 5 blockers are already resolved in the current code (blockers 2, 4, 5).
- Blocker 1 is a documentation inconsistency (design coherence table vs. interfaces).
- Blocker 3 is explicitly allowed by the spec (manual evidence when automation is infeasible).
- Approach 1 addresses all blockers with minimal risk and effort.
- Preserves the historical FAIL as authoritative while reconciling the artifacts.
- Stays well within the 800-line review budget.

## Explicit Non-Goals

- Do NOT change production code behavior (UsageController.qml).
- Do NOT revert the nonzero-with-usable-stdout semantics (spec already accepts it).
- Do NOT automate plasmawindowed testing (spec allows manual evidence).
- Do NOT add new test coverage (coverage already exists for all scenarios).
- Do NOT modify the historical verify-report.md or apply-progress.md (preserve as historical authority).
- Do NOT change the spec.md requirements or scenarios (they are correct).

## Risks

1. **Verifier acceptance**: The verifier may not accept documentation updates as resolving the blockers. Mitigation: ensure the design.md update is explicit and unambiguous.
2. **Assertion hardening regressions**: Adding guard clauses to 15 harnesses could introduce typos or logic errors. Mitigation: review each harness individually; run the full test suite after changes.
3. **Historical integrity**: Updating design.md could be seen as rewriting history. Mitigation: preserve the historical verify-report.md unchanged; the remediation reconciles artifacts, not the verdict.
4. **Scope creep**: The remediation could expand to address other issues (e.g., pre-existing i18n warnings, CompactUsageButtonHarness failures). Mitigation: explicit non-goals; stay focused on the 5 blockers.

## Ready for Proposal

**Yes** — the exploration is complete and the remediation scope is clear.

The orchestrator should tell the user:
- The exploration identified that 3 of 5 blockers are already resolved in the current code.
- Blocker 1 is a documentation inconsistency (design coherence table vs. interfaces).
- Blocker 3 is explicitly allowed by the spec (manual evidence).
- The recommended remediation is documentation-only reconciliation plus assertion hardening.
- No production code changes are required.
- The historical FAIL verdict is preserved; the remediation reconciles artifacts.
- The orchestrator can proceed to proposal, spec, design, and tasks phases for `persistent-datasource-lifecycle-remediation`.
