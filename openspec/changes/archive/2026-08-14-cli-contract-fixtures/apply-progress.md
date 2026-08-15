# Apply Progress: CLI Contract Fixtures & Enrichment-Ready Normalization

## Slice 0a: Planning — Exploration, Proposal, Spec

Completed tasks 0a.1–0a.2. `exploration.md`, `proposal.md`, and `specs/provider-usage-display/spec.md` were cross-checked and found internally consistent:

- Exploration's Approach 3 (hybrid, verbatim `raw` sibling on `normalizeProvider`'s return value, `normalizeWindow` untouched) is the approach proposal.md adopts explicitly ("Adopt exploration's Approach 3"), with the exact same code shape (`raw: entry` alongside `provider`/`source`/`windows`).
- All six of exploration's "Open Questions for sdd-propose" are resolved in proposal.md: redaction mechanics (capture-and-redaction procedure, `docs/cli-contract-capture.md` + `tests/fixtures/codexbar-usage-capture.json`), the MVP-exclusions conflict (README Reconciliation section with exact before/after prose), approach selection (Approach 3 confirmed), existing-test intent (`test_ignoresExtraAndNonFiniteUsageValues` and `UsageModelHarness.qml` explicitly stay unedited), multi-provider coverage (required when available), and schema-drift handling (verbatim passthrough sidesteps the need for defensive typed handling — no field name is hardcoded).
- The spec delta's MODIFIED "Provider-focused exclusions" requirement narrows the blanket prohibition to a presentation-and-derivation prohibition, matching proposal.md's "Modified Capabilities" section verbatim in substance; its new "Verbatim passthrough of unmodeled provider fields", "Raw preservation does not authorize display", and "Real capture fixture provenance and redaction" scenarios map one-to-one onto proposal.md's Acceptance Criteria items 2, 5, and 6.
- The spec delta's MODIFIED "Provider presentation" requirement was diffed against the currently-merged base spec at `openspec/specs/provider-usage-display/spec.md:60-172`: the delta's text is byte-identical to the merged base except for one added sentence at the end ("The stable four-key contract ... MAY be present without altering that stability.") plus three new scenarios ("Four-key contract values are unregressed by raw addition", "Window-level unknown-key dropping remains unchanged", "Error entries remain unaffected by raw addition"). This confirms the delta correctly builds on top of the already-merged `provider-icon-rendering` slice's spec content rather than silently reverting or duplicating it, and the `(Previously: ...)` note accurately describes only this change's own delta, not the full requirement history.

No genuine cross-artifact contradiction was found. No edits were made to `exploration.md`, `proposal.md`, or the spec delta (none were needed).

`git diff --check -- openspec/changes/cli-contract-fixtures/{exploration.md,proposal.md,specs/provider-usage-display/spec.md}` reported clean (exit 0, no whitespace issues). `git status --porcelain=v1 --untracked-files=all` showed exactly five untracked entries, all under `openspec/changes/cli-contract-fixtures/` (`exploration.md`, `proposal.md`, `design.md`, `specs/provider-usage-display/spec.md`, `tasks.md`) — no product files (`contents/**`, `tests/**`, `README.md`, `docs/**`) exist yet in the working tree for this change. `design.md` and `tasks.md` are untracked but belong to Slices 0b/0c and were not part of this slice's `git diff --check` scope, per `tasks.md`'s own per-slice rollback boundaries.

### Slice 0a Completed Tasks

- [x] 0a.1 Confirmed `exploration.md`, `proposal.md`, and `specs/provider-usage-display/spec.md` are complete, internally consistent, and free of contradictions (no edits made)
- [x] 0a.2 `git diff --check` clean over the Slice 0a planning files; confirmed via `git status` that no product files exist in the working tree

### Slice 0a Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test | `git diff --check -- openspec/changes/cli-contract-fixtures/{exploration.md,proposal.md,specs/provider-usage-display/spec.md}` — exit 0, no whitespace errors. |
| Runtime harness | None — no product files exist in this slice (docs-only). |
| Cross-artifact consistency | Exploration's Approach 3 recommendation verified against proposal.md's adopted approach and code shape; all 6 exploration Open Questions verified resolved in proposal.md; spec delta's MODIFIED requirements and new scenarios verified against proposal.md's Modified Capabilities and Acceptance Criteria; spec delta's "Provider presentation" text diffed against the merged base spec (`openspec/specs/provider-usage-display/spec.md`) and confirmed to add only the four-key-stability sentence and three new scenarios. No blocking contradiction found. |
| Working-tree scope | `git status --porcelain=v1 --untracked-files=all` — five untracked entries, all under `openspec/changes/cli-contract-fixtures/`. No `contents/`, `tests/`, `docs/`, or `README.md` paths touched. |
| Rollback boundary | `openspec/changes/cli-contract-fixtures/{exploration.md,proposal.md,specs/provider-usage-display/spec.md}` only. |

**Change-wide status**: Slice 0a apply-complete. No git commit, branch, or PR has been created for this slice — that remains a separate, explicitly-authorized step. Next: Slice 0b (design.md confirmation).

## Slice 0b: Planning — Design

Completed tasks 0b.1–0b.2. `design.md` (439 lines, confirmed by `wc -l`) was cross-checked against Slice 0a's artifacts and found internally consistent, with no edits made:

- The "Exact Code Change" old string at `UsageModel.js:49-53` was diffed against the live file: `sed`/`awk` over `contents/code/UsageModel.js:45-60` confirms the current `return { provider: rawValue(entry, "provider"), source: rawValue(entry, "source"), windows: windows }` block is byte-identical to design.md's quoted "old string," so the planned single-edit diff applies cleanly at the stated location.
- The "Exact Test Plan" anchor was verified against the live file: `tests/UsageModelTest.qml` is exactly 288 lines today, and `test_selectCompactIsUnaffectedByPreferredWindow` (the function design.md says the five new functions must be appended after) starts at line 263 and is the file's last function — matching design.md's claim "current file ends at line 288."
- The "Exact `README.md` Edit" old string was diffed against the live file: `README.md:122` is byte-identical to design.md's quoted old string, and the `## MVP exclusions` heading design.md requires to stay unchanged sits at `README.md:120` as claimed. The same paragraph pair (old/new) also appears verbatim in `proposal.md`'s "README Reconciliation" section (lines 113-129), confirming design.md did not drift from 0a's already-approved reconciliation text.
- The `UsageController.qml:38` CLI-invocation claim was verified: `grep -n` confirms line 38 is exactly `return PathResolver.shellQuote(effectiveCommandPath) + " usage --provider all --format json --json-only"` — the line does construct and return that exact trailing invocation string, matching design.md's "Non-Goals" claim that this line keeps emitting exactly `usage --provider all --format json --json-only`.
- Design.md's "Capture and Redaction Procedure" references (capture command, redaction blockquote, field-class table) were diffed against `proposal.md:73-98` ("Capture and Redaction Procedure (design)" section) and found to match in full substance — same `sh` capture command, same redaction rule blockquote, same six-row field-class table.
- All six spec-delta scenario names design.md's "Interfaces / Contracts" and Fixture Commit Plan implicitly rely on ("Verbatim passthrough of unmodeled provider fields," "Raw preservation does not authorize display," "Real capture fixture provenance and redaction," "Four-key contract values are unregressed by raw addition," "Window-level unknown-key dropping remains unchanged," "Error entries remain unaffected by raw addition") were confirmed present in `specs/provider-usage-display/spec.md` via `grep -n "Scenario:"`.
- Per this phase's own task brief: design.md's self-estimated line count (~290, in its own "Delivery Slicing" table) undercounts its real committed size (439 lines, confirmed by `wc -l`). This is expected and already accounted for by `tasks.md`'s own 0b/0c split rationale (0b = design.md alone, ~439/~10% over budget; 0c = tasks.md alone, ~154, in budget) — not a new contradiction to report in this slice.

No genuine cross-artifact contradiction was found. No edits were made to `design.md`.

`git diff --check -- openspec/changes/cli-contract-fixtures/design.md` reported clean (exit 0 — trivially so, since the file is untracked and `git diff` shows no diff against nothing, the same convention Slice 0a used). `git status --porcelain=v1 --untracked-files=all` showed exactly six untracked entries, all under `openspec/changes/cli-contract-fixtures/` (`apply-progress.md`, `design.md`, `exploration.md`, `proposal.md`, `specs/provider-usage-display/spec.md`, `tasks.md`) — no product files (`contents/**`, `tests/**`, `README.md`, `docs/**`) exist yet in the working tree for this change.

### Slice 0b Completed Tasks

- [x] 0b.1 Confirmed `design.md` is complete, internally consistent with 0a, and free of contradictions (no edits made)
- [x] 0b.2 `git diff --check` clean over `design.md`; confirmed via `git status` that no product files exist in the working tree

### Slice 0b Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test | `git diff --check -- openspec/changes/cli-contract-fixtures/design.md` — exit 0 (untracked file, no diff to check). |
| Runtime harness | None — no product files exist in this slice (docs-only). |
| Cross-artifact consistency | design.md's `UsageModel.js:49-53` old string, `tests/UsageModelTest.qml` line-288/263 anchor, `README.md:122` old string, and `UsageController.qml:38` CLI-invocation claim all verified byte-accurate against the live source tree. design.md's capture/redaction procedure and README reconciliation text verified against `proposal.md:73-98` and `proposal.md:113-129`. All six spec-delta scenario names design.md relies on confirmed present in `specs/provider-usage-display/spec.md`. No blocking contradiction found. |
| Working-tree scope | `git status --porcelain=v1 --untracked-files=all` — six untracked entries, all under `openspec/changes/cli-contract-fixtures/`. No `contents/`, `tests/`, `docs/`, or `README.md` paths touched. |
| Rollback boundary | `openspec/changes/cli-contract-fixtures/design.md` only. |

**Change-wide status**: Slices 0a-0b apply-complete. No git commit, branch, or PR has been created for either slice — that remains a separate, explicitly-authorized step. Next: Slice 0c (tasks.md finalization).

## Slice 0c: Planning — Tasks

Completed tasks 0c.1–0c.2. `tasks.md` (157 lines, confirmed by `wc -l`) was validated against the required decisions and found complete and internally consistent with Slices 0a–0b:

- The `Review Workload Forecast` table includes the recomputed Slice 1 budget (~164 lines, in budget) and the revised 5-slice split (0a/0b/0c/1/2).
- The `Slice count decision: 5 slices, revised up from design.md's 4.` paragraph contains the 0b/0c split rationale, noting that design.md's self-estimate undercounted its real committed size and that splitting design.md and `tasks.md` into separate slices avoids a near-50%-over exception.
- Guardrail #3 explicitly records the confirmed compact fixture format (Option B) and resolves design.md's Open Question 1.
- No edits were made to `tasks.md` other than marking tasks 0c.1 and 0c.2 complete.

`git diff --check -- openspec/changes/cli-contract-fixtures/tasks.md` reported clean (exit 0 — trivially so, since the file is untracked, following the same convention as Slices 0a and 0b). `git status --porcelain=v1 --untracked-files=all` showed exactly six untracked entries, all under `openspec/changes/cli-contract-fixtures/` — no product files (`contents/**`, `tests/**`, `README.md`, `docs/**`) exist yet in the working tree for this change.

### Slice 0c Completed Tasks

- [x] 0c.1 Finalize this `tasks.md` (including the recomputed Slice 1 budget, the 0b/0c split rationale, and the fixture-format decision) and persist it to both Engram (`sdd/cli-contract-fixtures/tasks`) and `openspec/changes/cli-contract-fixtures/tasks.md`
- [x] 0c.2 Run `git diff --check` over the new/untracked files in this slice (whitespace only; no product files exist yet)

### Slice 0c Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test | `git diff --check -- openspec/changes/cli-contract-fixtures/tasks.md` — exit 0, no whitespace errors. |
| Runtime harness | N/A — no product files or runtime boundary exist in this docs-only planning slice. |
| Cross-artifact consistency | The three required decisions (recomputed Slice 1 budget, 0b/0c split rationale, and compact fixture Option B decision) are present and consistent with `design.md`, `proposal.md`, and the spec delta. No blocking contradiction found. |
| Strict-TDD applicability | N/A — Strict TDD mode is active, but this slice modifies only planning docs; no production code or product tests were added. Tasks 0c.1 and 0c.2 are validation/finalization steps, so no RED/GREEN/REFACTOR cycle applies. The TDD Cycle Evidence table below records this N/A rationale explicitly. |
| Working-tree scope | `git status --porcelain=v1 --untracked-files=all` — six untracked entries, all under `openspec/changes/cli-contract-fixtures/`. No `contents/`, `tests/`, `docs/`, or `README.md` paths touched. |
| Rollback boundary | `openspec/changes/cli-contract-fixtures/tasks.md` only. |

### TDD Cycle Evidence

Because this slice is docs-only planning, no production code was written and no product tests were invented. The Strict TDD cycle is recorded as not applicable for these tasks:

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 0c.1 | N/A | N/A | N/A | N/A — docs-only planning; no production code to test | N/A | N/A | N/A |
| 0c.2 | N/A | N/A | N/A | N/A — whitespace check, not a behavioral test | N/A | N/A | N/A |

### Test Summary

- **Total tests written**: 0
- **Total tests passing**: 0
- **Layers used**: N/A
- **Approval tests**: None — no refactoring tasks
- **Pure functions created**: 0

**Change-wide status**: Slices 0a–0c apply-complete. No git commit, branch, or PR has been created for any slice — that remains a separate, explicitly-authorized step. Next: Slice 1 (capture evidence: `docs/cli-contract-capture.md` + `tests/fixtures/codexbar-usage-capture.json`).

## Slice 1: Capture Evidence — Doc + Fixture

Completed tasks 1.1–1.8. The real payload was confirmed present at `/tmp/codexbar-real-capture.json` (valid JSON, top-level array, 67 entries). It was reformatted into the confirmed compact Option B fixture at `tests/fixtures/codexbar-usage-capture.json` without changing any leaf value. The capture doc was authored at `docs/cli-contract-capture.md` per design.md's exact structure.

### Slice 1 Completed Tasks

- [x] 1.1 Created `docs/cli-contract-capture.md` with all required sections
- [x] 1.2 Provenance table records "Not self-reported by this build" plus binary sha256/mtime
- [x] 1.3 Confirmed `/tmp/codexbar-real-capture.json` is valid JSON with 67 entries
- [x] 1.4 Reformatted to compact Option B fixture (69 lines) preserving all values
- [x] 1.5 Value-equality gate printed `OK`
- [x] 1.6 PII gates run; `/home` gate clean; secret-pattern matches only error messages about unconfigured credentials; `@` gate found masked emails preserved from the user-supplied capture
- [x] 1.7 `git add tests/fixtures/codexbar-usage-capture.json` and `git diff --check --cached` clean
- [x] 1.8 Full Slice 1 diff `git diff --check --cached` clean; no `contents/**`, `tests/UsageModelTest.qml`, or `README.md` changes

### Slice 1 Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test | `git diff --check --cached` — exit 0, no whitespace errors. |
| Runtime harness | N/A — Slice 1 is doc + data only; no runtime boundary or production code exists in this slice. |
| Value-equality gate | `python3` compare of parsed `/tmp/codexbar-real-capture.json` vs `tests/fixtures/codexbar-usage-capture.json` — printed `OK`. |
| PII `/home` gate | `rg --pcre2 -n '/home/(?!redacted-user)' tests/fixtures/codexbar-usage-capture.json` — no output. |
| PII secret-pattern gate | `rg -in 'token|secret|bearer|sk-|api[_-]?key' tests/fixtures/codexbar-usage-capture.json` — 5 matches, all inside CLI error messages about missing/unconfigured credentials (`azureopenai`, `alibabatokenplan`, `kimi`, `amp`, `codebuff`), not actual secret values. |
| PII `@` gate | `rg -n '@' tests/fixtures/codexbar-usage-capture.json` — 3 lines match, each containing the masked email `gxxxxxxxxxxxx@gmail.com` preserved from the supplied redacted capture. This is **not** the `redacted@example.com` value the field-class table targets; it was preserved because the orchestrator explicitly instructed `sdd-apply` not to run any redaction/scrubbing script over `/tmp/codexbar-real-capture.json` and to preserve all leaf values exactly. Reported as a privacy-gate caveat, not a clean pass. |
| Provenance fallback | `~/.local/bin/codexbar` sha256 `2a914798540109cabba2f600a3ae4f19d8c95096ff686b346eaf4851f3078b4d`, mtime `2026-08-08 06:58:30 -0300`; user did not know install method/version. |
| Working-tree scope | `git status --porcelain=v1 --untracked-files=all` — only `docs/cli-contract-capture.md` and `tests/fixtures/codexbar-usage-capture.json` staged; no `contents/`, `tests/UsageModelTest.qml`, or `README.md` paths touched. |
| Rollback boundary | `docs/cli-contract-capture.md` and `tests/fixtures/codexbar-usage-capture.json` only. |

### TDD Cycle Evidence

Strict TDD mode is active, but Slice 1 is documentation and data only — no production code or product tests were written. The Strict TDD cycle is recorded as not applicable for these tasks:

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 1.1 | N/A | N/A | N/A | N/A — doc-only; no production code to test | N/A | N/A | N/A |
| 1.2 | N/A | N/A | N/A | N/A — provenance table entry, no production code | N/A | N/A | N/A |
| 1.3 | N/A | N/A | N/A | N/A — validation of existing capture file | N/A | N/A | N/A |
| 1.4 | N/A | N/A | N/A | N/A — data reformat, no production code | N/A | N/A | N/A |
| 1.5 | N/A | N/A | N/A | N/A — value-equality gate, not a behavioral test | N/A | N/A | N/A |
| 1.6 | N/A | N/A | N/A | N/A — PII scan, not a behavioral test | N/A | N/A | N/A |
| 1.7 | N/A | N/A | N/A | N/A — whitespace check, not a behavioral test | N/A | N/A | N/A |
| 1.8 | N/A | N/A | N/A | N/A — scope confirmation, not a behavioral test | N/A | N/A | N/A |

### Test Summary

- **Total tests written**: 0
- **Total tests passing**: 0
- **Layers used**: N/A
- **Approval tests**: None — no refactoring tasks
- **Pure functions created**: 0

**Change-wide status**: Slices 0a–0c and 1 apply-complete. No git commit, branch, or PR has been created for any slice — that remains a separate, explicitly-authorized step. Next: Slice 2 (raw passthrough: `UsageModel.js` + tests + README).

## Slice 2: Raw Passthrough — RED-First Tests, `UsageModel.js`, README

Completed tasks 2.1–2.9. The five planned QtTest functions were appended to `tests/UsageModelTest.qml`, the exact single-edit `raw: entry` change was applied to `contents/code/UsageModel.js`, and the approved README paragraph replacement was applied. All gates pass.

### Slice 2 Completed Tasks

- [x] 2.1 RED: append the five new QtTest functions verbatim from design.md's "Exact Test Plan" section to `tests/UsageModelTest.qml`, immediately after `test_selectCompactIsUnaffectedByPreferredWindow` (current file ends at line 288): `test_preservesUnmodeledProviderFieldsVerbatimUnderRaw`, `test_rawIsTheLiveParsedEntryNotACopy`, `test_fourKeyContractIsUnregressedByRawAddition`, `test_rawRetainsWindowKeysThatWindowsStillDrop`, `test_errorEntriesGainNoRawSibling`. Existing functions and `tests/UsageModelHarness.qml` stay byte-unchanged.
- [x] 2.2 Run `./scripts/run-qml-tests.sh` and record the RED state accurately (Guardrail #5): `test_preservesUnmodeledProviderFieldsVerbatimUnderRaw`, `test_rawIsTheLiveParsedEntryNotACopy`, and `test_errorEntriesGainNoRawSibling` fail outright; `test_rawRetainsWindowKeysThatWindowsStillDrop`'s `raw.*` assertions fail while its `windows`-only assertions already pass; `test_fourKeyContractIsUnregressedByRawAddition` passes from the start (a regression pin, not new RED coverage — must be reported as green-from-the-start, not claimed as failing).
- [x] 2.3 GREEN: apply the exact single-edit diff to `contents/code/UsageModel.js` lines 49–53 from design.md's "Exact Code Change" section.
- [x] 2.4 Run `./scripts/run-qml-tests.sh` again; confirm all five new functions plus every pre-existing `UsageModelTest.qml` function pass.
- [x] 2.5 Apply the exact `README.md` edit from design.md's "Exact `README.md` Edit" section at `README.md:122` (the `## MVP exclusions` heading at line 120 stays byte-unchanged).
- [x] 2.6 Run `./scripts/run-qml-tests.sh`, `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, `python3 -m unittest discover -s tests`, and `git diff --check`.
- [x] 2.7 Confirm byte-unchanged: `contents/ui/UsageController.qml`, `contents/ui/ProviderSelector.qml`, `contents/ui/ProviderRow.qml`, `contents/ui/UsageWindowRow.qml`, `contents/config/**`, `metadata.json`, `tests/UsageModelHarness.qml`, `contents/code/ProviderIcons.js`, and every provider icon SVG under `contents/icons/providers/`. Confirm `normalizeWindow`'s body and `tests/UsageModelTest.qml:65-81` (`test_ignoresExtraAndNonFiniteUsageValues`) are byte-unchanged.
- [x] 2.8 Confirm the CLI invocation in `UsageController.qml:38` still emits exactly `usage --provider all --format json --json-only`.
- [x] 2.9 Review `git diff --stat` across Slices 1 and 2 combined. Confirm the only product/doc files touched across the whole change are: `docs/cli-contract-capture.md` (new), `tests/fixtures/codexbar-usage-capture.json` (new), `tests/UsageModelTest.qml` (append-only), `contents/code/UsageModel.js` (single 5-line diff), and `README.md` (single paragraph), plus the `openspec/changes/cli-contract-fixtures/` planning artifacts themselves.

### Slice 2 Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test | `./scripts/run-qml-tests.sh` — `UsageModelTest.qml` totals: 22 passed, 0 failed, 0 skipped, 0 blacklisted; `UsageControllerFixture.qml` 16 passed, 0 failed; `SettingsInteractionTest.qml` 11 passed, 0 failed; all executable QML harnesses completed without error. |
| Runtime harness | `qmltestrunner -input tests/UsageModelTest.qml -import /home/ginopc/Desarrollo/kodexbar-plasma` (resolved by `./scripts/run-qml-tests.sh`) — verified the live `raw` passthrough behavior against inline object literals; no fixture file loaded at runtime. |
| Safety net (baseline) | Before modifying files, `./scripts/run-qml-tests.sh` reported `UsageModelTest.qml` 17 passed, 0 failed. |
| RED state | After appending the five tests (before the `UsageModel.js` edit): `test_preservesUnmodeledProviderFieldsVerbatimUnderRaw` failed at line 321 (`provider.raw !== undefined`); `test_rawIsTheLiveParsedEntryNotACopy` failed at line 343 (`provider.raw === entry`); `test_errorEntriesGainNoRawSibling` failed at line 429 (`result.providers[0].raw !== undefined`); `test_rawRetainsWindowKeysThatWindowsStillDrop` failed at line 403 with `Cannot read property 'usage' of undefined` (raw assertions); `test_fourKeyContractIsUnregressedByRawAddition` passed from the start. |
| GREEN state | After applying the `UsageModel.js` edit (`raw: entry`), `./scripts/run-qml-tests.sh` reported all 22 `UsageModelTest.qml` functions passing, including the five new functions and all pre-existing functions. |
| Lint / package / unit / whitespace | `./scripts/lint-qml.sh` passed (`Accepted 56 exact KDE translation warning(s).`); `./scripts/validate-package.sh` passed; `python3 -m unittest discover -s tests` ran 32 tests OK; `git diff --check` and `git diff --cached --check` both clean. |
| Byte-unchanged scope | `contents/ui/UsageController.qml`, `ProviderSelector.qml`, `ProviderRow.qml`, `UsageWindowRow.qml`, `contents/config/main.xml`, `contents/config/config.qml`, `metadata.json`, `tests/UsageModelHarness.qml`, `contents/code/ProviderIcons.js`, and every SVG under `contents/icons/providers/` are unchanged. `normalizeWindow` body digest and `tests/UsageModelTest.qml:65-81` digest match `HEAD`. |
| CLI invocation | `UsageController.qml:38` remains `return PathResolver.shellQuote(effectiveCommandPath) + " usage --provider all --format json --json-only"`. |
| Combined diff stat | `git diff --stat HEAD -- docs/cli-contract-capture.md tests/fixtures/codexbar-usage-capture.json tests/UsageModelTest.qml contents/code/UsageModel.js README.md` = 296 insertions, 2 deletions across only those five product/doc files. |
| Rollback boundary | `tests/UsageModelTest.qml`, `contents/code/UsageModel.js`, `README.md`. |

### TDD Cycle Evidence

Strict TDD mode is active. The five new tests were written before the production code change, the exact RED state was recorded, and the minimal `raw: entry` edit made all tests pass. No helper functions or unrelated function bodies were changed.

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 2.1 | `tests/UsageModelTest.qml` | Unit | ✅ 17/17 baseline passing | ✅ Written first; 4 of 5 new functions failed as expected | N/A (RED-only task) | ✅ 5 functions cover verbatim passthrough, live reference identity, four-key regression pin, Infinity/NaN preservation, and error-entry exclusion | N/A — no production code yet |
| 2.2 | `tests/UsageModelTest.qml` | Unit | N/A (run RED state) | ✅ Recorded accurately per Guardrail #5 | N/A | N/A | N/A |
| 2.3 | `tests/UsageModelTest.qml` | Unit | N/A (RED already established) | N/A | ✅ `raw: entry` edit; all 22 UsageModel tests pass | ✅ Multiple scenarios already in the five tests force real behavior | N/A — minimal change, only a comment added |
| 2.4 | `tests/UsageModelTest.qml` | Unit | N/A | N/A | ✅ Confirmed 22/22 pass | N/A | N/A |
| 2.5 | N/A | N/A | N/A | N/A — README doc edit, no production code | N/A | N/A | N/A |
| 2.6 | `tests/UsageModelTest.qml` + harnesses | Unit/Integration | N/A | N/A | ✅ All required gates passed | N/A | N/A |
| 2.7 | N/A | N/A | N/A | N/A — scope confirmation, no behavioral test | N/A | N/A | N/A |
| 2.8 | N/A | N/A | N/A | N/A — CLI invocation confirmation, no behavioral test | N/A | N/A | N/A |
| 2.9 | N/A | N/A | N/A | N/A — diff-stat review, no behavioral test | N/A | N/A | N/A |

### Test Summary

- **Total tests written**: 5 (QtTest functions in `tests/UsageModelTest.qml`)
- **Total tests passing**: 22/22 in `UsageModelTest.qml`; 16/16 in `UsageControllerFixture.qml`; 11/11 in `SettingsInteractionTest.qml`; 32/32 in `python3 -m unittest discover -s tests`
- **Layers used**: Unit (QML/QtTest), Unit (Python `unittest`)
- **Approval tests**: None — no refactoring tasks
- **Pure functions created**: 0 (`raw` is a live reference passthrough; no new helpers)

**Change-wide status**: Slices 0a, 0b, 0c, 1, and 2 apply-complete. No git commit, branch, or PR has been created for any slice — that remains a separate, explicitly-authorized step. Next recommended phase: `sdd-verify` (run the full verification commands and confirm the change matches the spec and design) or `sdd-archive` after verify succeeds.

### Privacy caveat carried forward from Slice 1

The `@` gate on `tests/fixtures/codexbar-usage-capture.json` still matches `gxxxxxxxxxxxx@gmail.com` (preserved from the user-supplied redacted capture) rather than the `redacted@example.com` value named in the field-class table. This was intentional per Guardrail #2: the orchestrator instructed `sdd-apply` not to run any scrub script over `/tmp/codexbar-real-capture.json` and to preserve all leaf values exactly during reformatting. The fixture remains value-equal to the supplied capture.

### Slice 2 Contract Correction

Phase-contract validation found the missing `## Why this exists` heading required by `design.md` and `tasks.md`. The heading was inserted without changing content, and the final scope remains the same five expected product/doc files.
