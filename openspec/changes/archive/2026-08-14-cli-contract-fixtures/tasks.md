# Tasks: CLI Contract Fixtures & Enrichment-Ready Normalization

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | Slice 0a ~450 / Slice 0b ~439 / Slice 0c ~154 / Slice 1 ~164 / Slice 2 ~160 — total ~1367 |
| 400-line budget risk | Slice 0a: Low — 12% over, accepted (unchanged from design.md). Slice 0b: Low — ~10% over, same accepted-exception class as 0a (see split rationale below). Slice 0c: None — in budget. Slice 1: **Resolved** — was ~862 (over, needed `size:exception`) under design.md's Option A; now ~164 (in budget) under the user's confirmed Option B. Slice 2: Low — in budget. |
| Chained PRs recommended | Yes |
| Suggested split | PR 0a exploration+proposal+spec → PR 0b design → PR 0c tasks → PR 1 capture evidence (doc + fixture) → PR 2 raw passthrough (tests + code + README) |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

**Slice count decision: 5 slices, revised up from design.md's 4.** The fixture shrinking from 767 to 69 lines resolves Slice 1's budget (over → in-budget) without changing its boundary — design.md is explicit that Slices 1 (evidence) and 2 (mechanism) "must not merge: the evidence gate (Phase 0) exists precisely so the mechanism (Phase 1) is reviewed against real data already on disk," an architectural constraint independent of line count, so a combined ~324-line total does not justify merging them. Separately, this phase found that design.md's own self-estimate of its length (~290 lines) undercounted its real committed size — `wc -l` confirms 439 lines — so design.md's originally-planned combined "design + tasks" slice (0b) would total design.md (439) + this `tasks.md` (154, confirmed by `wc -l` after writing) = **593 lines, 48% over budget**, a materially worse overage than 0a's accepted 12%. Rather than wave through a near-50%-over exception, **Slice 0b is split into 0b (design.md alone, ~439, ~10% over — the same accepted-exception class as 0a) and 0c (tasks.md alone, ~154, in budget)**, since the two documents have no narrative dependency preventing an independent split (unlike the README/`raw` case in Slice 1 vs 2, which does have one — see Guardrail #1). This is a re-evaluated boundary, not a rubber-stamped acceptance of the 48% figure; `sdd-apply` should still confirm with the user before opening 0b's PR if reviewers consider even the ~10% overage unacceptable.

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 0a | Exploration + proposal + spec delta | PR 0a | `git diff --check` | None (no product files) | `openspec/changes/cli-contract-fixtures/{exploration.md,proposal.md,specs/**}` only |
| 0b | Design | PR 0b | `git diff --check` | None (no product files) | `openspec/changes/cli-contract-fixtures/design.md` only |
| 0c | Tasks | PR 0c | `git diff --check` | None (no product files) | `openspec/changes/cli-contract-fixtures/tasks.md` only |
| 1 | Capture-and-redaction doc + compact redacted fixture | PR 1 | `git diff --check` + PII/value-equality gates (below) | None (doc + data only) | `docs/cli-contract-capture.md`, `tests/fixtures/codexbar-usage-capture.json` |
| 2 | RED-first `raw` tests, GREEN `UsageModel.js` diff, README reconciliation | PR 2 | `./scripts/run-qml-tests.sh` | `qmltestrunner -input tests/UsageModelTest.qml` | `tests/UsageModelTest.qml`, `contents/code/UsageModel.js`, `README.md` |

## Guardrail — read before Slice 1

1. **README.md lands in Slice 2, not with the capture doc.** The orchestrator's slice-grouping brief filed the README edit under a "Doc slice" alongside `docs/cli-contract-capture.md`. This task list keeps README in Slice 2 instead, because the new README paragraph asserts a present-tense fact — "the data layer preserves them verbatim under a per-provider `raw` key" — that is only true once Slice 2's `UsageModel.js` edit lands. Shipping it in Slice 1 would leave `main` with documentation describing code that does not exist yet for the interval between the two merges. Design.md's own file-to-slice table already places README in the mechanism slice for this reason.
2. **`/tmp/codexbar-real-capture.json` is already redacted — do not re-scrub it.** The orchestrator has confirmed account emails, a timezone string, and a local username are already scrubbed in that file. Task 1.4's reformat step reads directly from this already-redacted source and changes only JSON serialization density (pretty → compact), never leaf values. Do not run design.md's `accountEmail -> redacted@example.com` scrub script against it — that script exists for an *unredacted* capture and is a no-op-or-worse against an already-redacted one.
3. **Compact fixture format (Option B) is confirmed, not design.md's recommended Option A.** Design.md's "Open Questions" §1 recommended Option A (pretty-printed, 767 lines, `size:exception`). The user has since explicitly chosen Option B (one compact JSON object per line, ~69 lines, in budget). Do not implement Option A. This resolves design.md's Open Question 1 and its flagged Threat-Matrix/Risk item on Slice 1's budget.
4. **Do not fabricate a CodexBar version.** Per design.md's "On the missing CodexBar version" section and Threat Matrix ("Apply invents a CodexBar version number"), this build's `codexbar --version` prints no number. Task 1.2 requires `sdd-apply` to ask the user before writing the provenance table; if unknown, record exactly "Not self-reported by this build" plus the binary's sha256 and mtime. Never infer a CodexBar version from a provider-CLI's own `version` field inside the payload (e.g. `codex` → `0.147.0` is the Codex CLI's version, not CodexBar's).
5. **Test 3 and part of Test 4 are already GREEN — do not claim false RED.** Per Strict TDD mode and design.md's own "RED evidence to record": `test_fourKeyContractIsUnregressedByRawAddition` passes before any `UsageModel.js` change (it is a regression pin, not new coverage). `test_rawRetainsWindowKeysThatWindowsStillDrop`'s `windows`-only assertions also pass before the change; only its `raw.*` assertions are genuinely RED. Task 2.2 must report this accurately.

## Slice 0a: Planning — Exploration, Proposal, Spec (branch `slice/cli-contract-fixtures-0a-planning`, base `main`)

- [x] 0a.1 Confirm `exploration.md`, `proposal.md`, and `specs/provider-usage-display/spec.md` are complete, internally consistent, and free of contradictions (already authored in the explore/propose/spec phases; no edits expected here).
- [x] 0a.2 Run `git diff --check` over the new/untracked files in this slice (whitespace only; no product files exist yet).

## Slice 0b: Planning — Design (branch `slice/cli-contract-fixtures-0b-design`, base Slice 0a)

- [x] 0b.1 Confirm `design.md` is complete, internally consistent with 0a, and free of contradictions (already authored in the design phase; no edits expected here).
- [x] 0b.2 Run `git diff --check` over the new/untracked files in this slice (whitespace only; no product files exist yet).

## Slice 0c: Planning — Tasks (branch `slice/cli-contract-fixtures-0c-tasks`, base Slice 0b)

- [x] 0c.1 Finalize this `tasks.md` (including the recomputed Slice 1 budget, the 0b/0c split rationale, and the fixture-format decision) and persist it to both Engram (`sdd/cli-contract-fixtures/tasks`) and `openspec/changes/cli-contract-fixtures/tasks.md`.
- [x] 0c.2 Run `git diff --check` over the new/untracked files in this slice (whitespace only; no product files exist yet).

## Slice 1: Capture Evidence — Doc + Fixture (branch `slice/cli-contract-fixtures-1-capture-evidence`, base Slice 0c)

### Doc

- [x] 1.1 Create `docs/cli-contract-capture.md` (new file, ~95 lines) per design.md's "`docs/cli-contract-capture.md` — Exact Structure and Content" section, mirroring `docs/live-plasma-smoke.md`'s heading style (`# Title`, `## Section`, `### Subsection`, tables, fenced `sh` blocks). Sections in order: Why this exists; Capture command (verbatim `sh` block from proposal.md's "Capture and Redaction Procedure", plus the note that this is the exact invocation `UsageController.qml:38` emits); Redaction rule (verbatim blockquote) with the Field-class table (verbatim 6-row table from proposal.md); Verification before commit (the PII gate and value-equality gate commands from tasks 1.5–1.6 below); Provenance of the committed fixture (table — see task 1.2); On the missing CodexBar version (verbatim substance from design.md, see Guardrail #4); Re-capture cadence (verbatim substance from design.md — manual, no CI QML runtime).
- [x] 1.2 Provenance table: ASK the user whether they know their CodexBar install method/version before writing this row (Guardrail #4). If yes, record it as a third provenance line. If unknown or declined, record exactly "Not self-reported by this build" plus the installed binary's sha256 and mtime (`~/.local/bin/codexbar`) and the capture date. Do not infer a version from any provider-CLI `version` field inside the payload.

### Fixture

- [x] 1.3 Confirm `/tmp/codexbar-real-capture.json` is present, is valid JSON (a top-level array of 67 entries), and is already redacted per Guardrail #2. Do not run design.md's dict-scrub script against it.
- [x] 1.4 RED→N/A (data, not code): reformat `/tmp/codexbar-real-capture.json` from pretty-printed (767 lines) into the compact one-object-per-line form and write it to `tests/fixtures/codexbar-usage-capture.json` (design.md Option B: an opening `[` line, 67 single-line `json.dumps(entry, separators=(",", ":"), ensure_ascii=False)` lines with a trailing comma on every line but the last, and a closing `]` line — 69 lines total, matching the compact-JSON convention already used at `tests/fixtures/codexbar-lifecycle-fixture.sh:15`). Exact script:
  ```sh
  cd /home/ginopc/Desarrollo/kodexbar-plasma
  python3 - <<'PY'
  import json, pathlib
  entries = json.loads(pathlib.Path("/tmp/codexbar-real-capture.json").read_text())
  lines = ["["]
  for i, entry in enumerate(entries):
      comma = "," if i < len(entries) - 1 else ""
      lines.append(json.dumps(entry, separators=(",", ":"), ensure_ascii=False) + comma)
  lines.append("]")
  pathlib.Path("tests/fixtures/codexbar-usage-capture.json").write_text("\n".join(lines) + "\n")
  PY
  ```
- [x] 1.5 **Value-equality gate (must print `OK`) — proves no redacted value regressed during reformatting.** This subsumes design.md's Option-A shape-preservation gate: byte-for-byte value equality implies shape/type equality, so only this one check is needed for a pure reformat.
  ```sh
  python3 - <<'PY'
  import json, pathlib
  a = json.loads(pathlib.Path("/tmp/codexbar-real-capture.json").read_text())
  b = json.loads(pathlib.Path("tests/fixtures/codexbar-usage-capture.json").read_text())
  print("OK" if a == b else "VALUE DRIFT DETECTED")
  PY
  ```
- [x] 1.6 Run the three PII gates from design.md's Fixture Commit Plan against `tests/fixtures/codexbar-usage-capture.json` (all three must return no unexpected match):
  ```sh
  rg -n '@' tests/fixtures/codexbar-usage-capture.json        # only redacted@example.com
  rg -n '/home/(?!redacted-user)' tests/fixtures/codexbar-usage-capture.json
  rg -in 'token|secret|bearer|sk-|api[_-]?key' tests/fixtures/codexbar-usage-capture.json
  ```
- [x] 1.7 `git add tests/fixtures/codexbar-usage-capture.json` and run `git diff --check`. **Hard pre-commit gate** (design.md, Rollback Plan): an unredacted value cannot be removed from history by revert.
- [x] 1.8 Run `git diff --check` over the full Slice 1 diff. Confirm no product code file changed in this slice — `contents/**`, `tests/UsageModelTest.qml`, and `README.md` remain byte-unchanged (README lands in Slice 2; see Guardrail #1).


## Slice 2: Raw Passthrough — RED-First Tests, `UsageModel.js`, README (branch `slice/cli-contract-fixtures-2-raw-passthrough`, base Slice 1)

### RED — tests before `raw` exists

- [x] 2.1 RED: append the five new QtTest functions verbatim from design.md's "Exact Test Plan" section to `tests/UsageModelTest.qml`, immediately after `test_selectCompactIsUnaffectedByPreferredWindow` (current file ends at line 288): `test_preservesUnmodeledProviderFieldsVerbatimUnderRaw`, `test_rawIsTheLiveParsedEntryNotACopy`, `test_fourKeyContractIsUnregressedByRawAddition`, `test_rawRetainsWindowKeysThatWindowsStillDrop`, `test_errorEntriesGainNoRawSibling`. Existing functions and `tests/UsageModelHarness.qml` stay byte-unchanged.
- [x] 2.2 Run `./scripts/run-qml-tests.sh` and record the RED state accurately (Guardrail #5): `test_preservesUnmodeledProviderFieldsVerbatimUnderRaw`, `test_rawIsTheLiveParsedEntryNotACopy`, and `test_errorEntriesGainNoRawSibling` fail outright; `test_rawRetainsWindowKeysThatWindowsStillDrop`'s `raw.*` assertions fail while its `windows`-only assertions already pass; `test_fourKeyContractIsUnregressedByRawAddition` passes from the start (a regression pin, not new RED coverage — must be reported as green-from-the-start, not claimed as failing).

### GREEN — `raw` key

- [x] 2.3 GREEN: apply the exact single-edit diff to `contents/code/UsageModel.js` lines 49–53 from design.md's "Exact Code Change" section: replace
  ```js
      return {
          provider: rawValue(entry, "provider"),
          source: rawValue(entry, "source"),
          windows: windows
      }
  ```
  with
  ```js
      // raw is a live reference to the parsed CLI entry, never a copy: normalized
      // snapshots are read-only, and a JSON round-trip would destroy Infinity/NaN.
      return {
          provider: rawValue(entry, "provider"),
          source: rawValue(entry, "source"),
          windows: windows,
          raw: entry
      }
  ```
  No helper function is added. `rawValue`, `normalizeWindow`, `normalize`, `firstFiniteWindow`, `definitionForPreferred`, `matchesDefinition`, `preferredFiniteWindow`, `selectRepresentative`, and `selectCompact` stay byte-unchanged.
- [x] 2.4 Run `./scripts/run-qml-tests.sh` again; confirm all five new functions plus every pre-existing `UsageModelTest.qml` function pass.

### Doc: README (lands here, not in Slice 1 — see Guardrail #1)

- [x] 2.5 Apply the exact `README.md` edit from design.md's "Exact `README.md` Edit" section at `README.md:122` (the `## MVP exclusions` heading at line 120 stays byte-unchanged). Replace:
  ```
  KodexBar Plasma deliberately does not implement cost data, credits, tokens, calculated reset durations, charts, provider or source switching, authentication or cookie automation, provider implementations, fallback probing, or reset/account actions. Use CodexBar and provider tools for those responsibilities.
  ```
  with:
  ```
  KodexBar Plasma deliberately does not implement provider implementations, authentication or cookie automation, fallback probing, reset or account actions, provider or source switching, calculated reset durations, or charts. Use CodexBar and provider tools for those responsibilities.

  Cost, credit, token, pace, and other richer per-provider values are never computed, estimated, or requested by this widget. When the CodexBar CLI itself returns such fields, the data layer preserves them verbatim under a per-provider `raw` key so later phases can build on real data — **the popup does not display them today**. Surfacing them in the UI is planned roadmap work, not current behavior.
  ```

### Verification (Slice 2, final for the change)

- [x] 2.6 Run `./scripts/run-qml-tests.sh`, `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, `python3 -m unittest discover -s tests`, and `git diff --check`.
- [x] 2.7 Confirm byte-unchanged: `contents/ui/UsageController.qml`, `contents/ui/ProviderSelector.qml`, `contents/ui/ProviderRow.qml`, `contents/ui/UsageWindowRow.qml`, `contents/config/**`, `metadata.json`, `tests/UsageModelHarness.qml`, `contents/code/ProviderIcons.js`, and every provider icon SVG under `contents/icons/providers/`. Confirm `normalizeWindow`'s body and `tests/UsageModelTest.qml:65-81` (`test_ignoresExtraAndNonFiniteUsageValues`) are byte-unchanged.
- [x] 2.8 Confirm the CLI invocation in `UsageController.qml:38` still emits exactly `usage --provider all --format json --json-only`.
- [x] 2.9 Review `git diff --stat` across Slices 1 and 2 combined. Confirm the only product/doc files touched across the whole change are: `docs/cli-contract-capture.md` (new), `tests/fixtures/codexbar-usage-capture.json` (new), `tests/UsageModelTest.qml` (append-only), `contents/code/UsageModel.js` (single 5-line diff), and `README.md` (single paragraph), plus the `openspec/changes/cli-contract-fixtures/` planning artifacts themselves.

## Non-Goals (in force for `sdd-apply` — drift into any of these is a defect)

Restated verbatim in substance from design.md's "Non-Goals and Boundaries" section:

1. **No UI whatsoever.** No pace, credits, cost, token, richer-timestamp, dynamic-window, or per-provider-metadata rendering. That is roadmap Phase 2+ with its own proposal.
2. **No change to the CLI invocation.** `contents/ui/UsageController.qml:38` keeps emitting exactly `usage --provider all --format json --json-only`.
3. **No provider, OAuth, credential, cookie, probing, or account logic.** Those stay CodexBar's responsibility, permanently.
4. **No change to the stable four-key contract's shape or semantics** — `provider`, `source`, and `windows[].{key,label,usedPercent,resetsAt,resetDescription}` keep their exact current values, types, ordering, and null behavior.
5. **No change to `normalizeWindow`.** Window-level unknown-key dropping is untouched; `tests/UsageModelTest.qml:65-81` and `tests/UsageModelHarness.qml:26,38` stay byte-unchanged.
6. **No typed field promotion.** No first-class named property for `pace`, `credits`, `identity`, `version`, or `status`. Deferred, not rejected.
7. **No cost or token computation of any kind.** If the CLI does not emit a value, nothing is derived, estimated, or requested.
8. **No touching `openspec/changes/persistent-datasource-lifecycle/`.** Unrelated stray directory, flagged for separate cleanup.
9. **No runtime fixture loading in QML tests** (design.md AD-3). The new QtTest functions use inline object literals; they do not read `tests/fixtures/codexbar-usage-capture.json` from disk.
