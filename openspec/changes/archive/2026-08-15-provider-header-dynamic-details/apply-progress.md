# Apply Progress: provider-header-dynamic-details

## Change

`provider-header-dynamic-details` — Dynamic Provider Header Details

## Mode

Strict TDD (`strict_tdd: true`, `apply.tdd: true`, runner `./scripts/run-qml-tests.sh`)

## Completed Tasks

- [x] 1.1 `tests/ProviderDetailsHarness.qml` RED cases for malformed details, identity-only/conflicting login ignored, single login source, exclusions in every slot, verbatim plain text.
- [x] 1.2 Component RED cases for collapsed default, Tab focus, Return/Space activation, accessible name/state, zero-min-width wrap, narrow/long rows, Breeze Light/Dark theme colors.
- [x] 1.3 `tests/test_cli_contract_fixture.py` pinning fixture bytes, JSON structure, docs provenance, leaf-only redaction, sensitive-pattern gates; no recapture/rescrub.
- [x] 1.4 `scripts/run-qml-tests.sh` registers `ProviderDetailsHarness.qml` and `test_cli_contract_fixture.py`.
- [x] 2.1 `contents/code/ProviderDetails.js` read-only sanitizer for `raw.version`, `raw.usage.loginMethod`, `raw.usage.details`; no mutation, no stringification.
- [x] 2.2 Validation: non-empty string version/login; detail object with non-empty title, array rows, ≥1 accepted row; row with non-empty label/value and optional string/null secondaryValue.
- [x] 2.3 Deterministic fail-closed exclusion inspection (camelCase split, lowercase, separator-normalize) for email/e-mail, organization/organisation, pace, credit(s), cost(s), token(s), email signature.
- [x] 3.1 `contents/ui/ProviderDetails.qml` native checkable `QQC2.ToolButton` disclosure, themed arrows, Kirigami units/theme, focus, keyboard activation, accessible name/state, zero-min-width wrap.
- [x] 3.2 `contents/ui/ProviderRow.qml` conditional version/login metadata (selected-provider only), delegates filtered details to `ProviderDetails.qml`.
- [x] 3.3 GREEN component cases pass offscreen.
- [x] 4.1 `contents/ui/main.qml` disables horizontal scrolling and uses as-needed vertical scrolling inside the 44-grid-unit popup bound.
- [x] 4.2 Overflow: expanded details remain vertically reachable; no horizontal overflow.
- [x] 5.1 `README.md` and `docs/live-plasma-smoke.md` updated with display exclusions and manual keyboard/theme/vertical-scroll checks.
- [x] 6.1 `./scripts/run-qml-tests.sh` and `./scripts/lint-qml.sh` pass; `UsageModel.js`, `UsageController.qml`, and fixture diffs are empty.
- [x] 6.2 Runtime boundaries preserved: compact selection, request lifecycle, exact all-provider CLI argv unchanged.
- [x] 6.3 Email/organization/pace/credits/cost/tokens never displayed; no commercial or reset data fabricated.

## Files Changed

| File | Action | What Was Done |
|------|--------|---------------|
| `contents/code/ProviderDetails.js` | Created | Read-only validation/sanitization helper for version, loginMethod, and usage.details with deterministic fail-closed exclusions. |
| `contents/ui/ProviderDetails.qml` | Created | Native collapsed disclosure component for accepted details; keyboard/accessible/theme-adaptive; zero-min-width wrap. |
| `contents/ui/ProviderRow.qml` | Modified | Added conditional version/login header metadata and delegated filtered details to `ProviderDetails.qml` for selected providers only. |
| `contents/ui/main.qml` | Modified | Disabled horizontal scrollbar and enabled as-needed vertical scrollbar in popup ScrollView. |
| `tests/ProviderDetailsHarness.qml` | Created | RED→GREEN QML harness covering sanitizer, exclusions, component behavior, accessibility, geometry, and theme colors. |
| `tests/test_cli_contract_fixture.py` | Created | Fixture byte pin, JSON/structure/docs/redaction/sensitive-pattern evidence without recapture/rescrub. |
| `tests/test_bound_qml_components.py` | Modified | Added `ProviderDetails.qml` to bound-behavior checks and added popup scrollbar-policy structural check. |
| `scripts/run-qml-tests.sh` | Modified | Registered `ProviderDetailsHarness.qml` and `test_cli_contract_fixture.py`. |
| `README.md` | Modified | Documented version/login/details display and exclusions. |
| `docs/live-plasma-smoke.md` | Modified | Added manual provider header/details keyboard/theme/scroll checks. |

## TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 1.1–1.2 | `tests/ProviderDetailsHarness.qml` | Harness (Unit + Component) | ✅ 49/49 existing tests passed | ✅ Written; failed to load (missing files) | ✅ Passed (exit 0) | ✅ 30+ sanitizer cases, 8+ component cases | ✅ Eliminated dead helper code; qualified `modelData` to satisfy qmllint |
| 1.3 | `tests/test_cli_contract_fixture.py` | Evidence (Python) | N/A (new) | ✅ Written; fixture sha mismatch on first run | ✅ Passed (9/9) | ✅ Path/date/version/binary/leaf-redaction/sensitive-pattern/structure/provider checks | ✅ Split assertions into focused test methods |
| 2.1–2.3 | `tests/ProviderDetailsHarness.qml` | Harness (Unit) | ✅ existing tests passed | ✅ ProviderDetailsHarness references `ProviderDetails.js` | ✅ JS-only harness passes | ✅ Valid/invalid version, valid/invalid login, malformed shapes, exclusions in title/label/value/secondaryValue, mixed rows, verbatim text | ✅ Extracted `normalizeWords`, `isRejectedText`, `isValidRow`, `isValidDetail`; kept pure functions |
| 3.1–3.3 | `tests/ProviderDetailsHarness.qml` + `tests/test_bound_qml_components.py` | Component + Static | ✅ ProviderRowHarness passed | ✅ ProviderDetailsHarness references `ProviderDetails.qml` | ✅ Component harness passes | ✅ Collapsed default, focus/activation, accessible name/state, wrap/theme, narrow/long rows | ✅ Used `detailDelegate`/`rowDelegate` ids to qualify `modelData`; used `root.translate*` |
| 4.1–4.2 | `tests/test_bound_qml_components.py` | Static structural | N/A (layout policy) | ✅ Added scrollbar-policy assertion | ✅ Passed | ✅ Structural check of both horizontal and vertical policies | ✅ N/A |
| 5.1 | Docs only | N/A | N/A | N/A | N/A | N/A | N/A |
| 6.1–6.3 | Full suite | Regression | ✅ Full suite passed | N/A | ✅ `./scripts/run-qml-tests.sh` + `./scripts/lint-qml.sh` + `git diff --check` | ✅ Verified model/controller/fixture diffs empty; verified exclusions never render | ✅ N/A |

## Work Unit Evidence

| Evidence | Required value |
|---|---|
| Focused test command and exact result | `./scripts/run-qml-tests.sh` → all QtTest + harness + fixture tests pass (exit 0); `python3 tests/test_cli_contract_fixture.py` → 9/9 pass. |
| Runtime harness command/scenario and exact result | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/ProviderDetailsHarness.qml` → exit 0. Offscreen verifies sanitizer, exclusions, disclosure, accessibility, narrow geometry, and theme-color usage. |
| Rollback boundary | Revert `contents/code/ProviderDetails.js`, `contents/ui/ProviderDetails.qml`, `contents/ui/ProviderRow.qml` presentation edits, `contents/ui/main.qml` scrollbar-policy edits, `tests/ProviderDetailsHarness.qml`, `tests/test_cli_contract_fixture.py`, `tests/test_bound_qml_components.py` additions, `scripts/run-qml-tests.sh` additions, `README.md`/`docs/live-plasma-smoke.md` additions. `UsageModel.js`, `UsageController.qml`, `tests/fixtures/codexbar-usage-capture.json`, `docs/cli-contract-capture.md` remain untouched. |

## Test Summary

- **Total tests written**: ProviderDetailsHarness (40+ behavioral assertions), test_cli_contract_fixture.py (9 methods), test_bound_qml_components.py additions (1 method + ProviderDetails in 3 existing methods).
- **Total tests passing**: All existing + new tests pass.
- **Layers used**: QML harness, Python unittest/static, qmllint.
- **Approval tests**: None — no refactoring of existing behavior.
- **Pure functions created**: `validVersion`, `validLoginMethod`, `acceptedDetails`, `isRejectedText`, `normalizeWords`, `isValidRow`, `isValidDetail` in `ProviderDetails.js`.

## Deviations from Design

- None in behavior or architecture. Implementation matches design decisions: separate `ProviderDetails.js` sanitizer, native `ProviderDetails.qml` disclosure, selected-only enrichment, `identity.loginMethod` ignored, deterministic fail-closed exclusions, no stringification.
- **Line-count note**: Actual authored additions total ~731 lines (across helper, component, harness, fixture test, docs, wiring), exceeding the forecasted ~320–400. The increase is driven by the required exhaustive RED harness coverage (malformed shapes, exclusions in every slot, verbatim text, component behavior, accessibility, geometry, theme) and the fixture-evidence test. The change remains a single work unit as requested.

## Issues Found

- Initial `ProviderDetailsHarness.qml` failed to load with generic "Did not load any objects" because the harness referenced `ProviderDetails.js` and `ProviderDetails.qml` before they existed. Resolved by creating the production files (expected RED→GREEN).
- Runtime geometry assertions required a `Timer` delay because Repeater-delegate labels need a layout pass before widths are valid.
- `hasHardcodedColor` initially recursed into `ToolButton` internals whose colors are not theme text colors; narrowed the check to actual `Label` items.
- `qmllint` rejected unqualified `modelData` and local `translate`/`translatePlural` calls in `ProviderDetails.qml`; fixed by qualifying `modelData` via delegate ids and using `root.translate*`.
- Fixture test initially asserted every provider entry has `version`; relaxed because some usable entries (e.g., claude) omit `version`. Also adjusted redaction assertions to accept the fixture's masked email pattern (`gxxxxxxxxxxxx@gmail.com`) and canonical redacted home path (`/home/redacted-user`).

## Remaining Tasks

None.

## Workload / PR Boundary

- Mode: single PR / single work unit (as designed; no size-exception requested by prompt despite actual line count exceeding forecast).
- Current work unit: Unit 1 — RED harness + sanitizer + native disclosure + bounded layout + docs.
- Boundary: From existing `main` through all Phase 1–6 tasks complete and verified.
- Estimated review budget impact: ~731 authored additions across 10 files; exceeds the ~320–400 forecast. Recommend reviewer treat as a single focused unit or consider splitting in a follow-up if review load is a concern.

## Status

16/16 tasks complete. Ready for verify.

## Final Commands and Results

```sh
./scripts/run-qml-tests.sh        # exit 0
./scripts/lint-qml.sh             # Accepted 58 exact KDE translation warning(s); exit 0
git diff --check                  # no whitespace errors
git diff -- contents/code/UsageModel.js contents/ui/UsageController.qml tests/fixtures/codexbar-usage-capture.json
# (no output — unchanged)
```

## Post-apply Privacy Correction

Removed the environment-specific `/home/ginopc` literal from
`tests/test_cli_contract_fixture.py`. The test now generically asserts that
only `/home/redacted-user` home-path segments occur in the fixture, preserving
the same privacy invariant without embedding the local username. The focused
fixture test passes 9/9 and no product behavior changed.

## Resolved Workload Decision

The implementation measured approximately 728 authored additions, exceeding the
original 320–400 forecast. The maintainer explicitly accepted `size:exception`
for this single work unit, so verification and review proceed without splitting
the already-completed implementation.

## Remediation: Verification blockers

All six failed-verification blockers are remediated in the same accepted
`size:exception` work unit. `ProviderDetailsIntegrationTest.qml` uses real
`ProviderRow` and `ProviderDetails` instances with synthetic non-commercial
payloads; the existing popup composition is reused for the bounded-scroll path.

### Completed Remediation Tasks

- [x] R1 Integrated `ProviderRow` metadata, malformed-details, and malicious-provider display tests.
- [x] R2 Exact Return/Space activation, changed accessible description, and Breeze Light/Dark runtime tests.
- [x] R3 Over-height vertical scrollbar movement and horizontal-disabled runtime test.
- [x] R4 Repository-wide tracked-test local-username removal.
- [x] R5 README display-exclusion clarification.
- [x] R6 Required remediation gates and protected-boundary checks.

### Remediation TDD Cycle Evidence

| Task | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|
| R1 | `ProviderDetailsHarness.qml` and `ProviderRowHarness.qml` exit 0 | `ProviderDetailsIntegrationTest.qml` failed 3/3 because `ProviderRow` did not expose its real details component | Added read-only `providerDetails` alias; conditional metadata, malformed details, and malicious payload cases pass | Valid/absent paths, malformed details, and approved/excluded payloads | Test helpers keep visual assertions user-facing |
| R2 | Focused integration test baseline recorded above | Return did not toggle before explicit native key handlers | Return and Space each toggle the real `QQC2.ToolButton`; accessible description changes | Same 7-test suite runs with `BreezeLight.colors` and `BreezeDark.colors` | Kept native ToolButton and added only key event handlers |
| R3 | Focused integration test baseline recorded above | New over-height test initially failed its viewport-reachability assertion | Real `ScrollView` proves vertical bar is required, moves to a nonzero position, and horizontal bar stays disabled | Eight rows exceed the viewport; valid and malformed rows cover distinct display branches | Replaced brittle coordinate assertion with scrollbar reachability behavior |
| R4–R6 | Existing full runner exit 0 | Generic test-artifact paths and README wording added before final gates | Full required gates pass | Checked every tracked `tests/` artifact, not only reported files | None needed |

### Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test command | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software /usr/lib/qt6/bin/qmltestrunner -input tests/ProviderDetailsIntegrationTest.qml -import .` → exit 0, 7 passed, 0 failed. |
| Runtime harness | `./scripts/run-qml-tests.sh` → exit 0. `ProviderDetailsIntegrationTest.qml` ran with `/usr/share/color-schemes/BreezeLight.colors` and `BreezeDark.colors`, 7/7 passed in each; the complete runner also passed 49 pre-existing QtTest cases, 9 fixture tests, and 20 executable QML harnesses. |
| Quality/package gates | `./scripts/lint-qml.sh` → exit 0, 58 accepted KDE translation warnings; `./scripts/validate-package.sh` → exit 0; `python3 -m unittest discover -s tests` → 42/42; `python3 tests/test_cli_contract_fixture.py` → 9/9; `git diff --check` → exit 0. |
| Privacy/boundary gates | `git grep -n '/home/ginopc' -- tests` → no matches; protected-boundary diff for `UsageModel.js`, `UsageController.qml`, Phase 1 fixture, and `docs/cli-contract-capture.md` → exit 0 with no output. |
| Rollback boundary | Revert `ProviderRow.qml` alias, `ProviderDetails.qml` key handlers, `ProviderDetailsIntegrationTest.qml`, runner registration, test-artifact path anonymization, README clarification, and remediation artifact sections. Preserve existing sanitizer, base UI, model/controller, fixture, and capture document. |

```yaml
schema: gentle-ai.remediation-result/v1
lineage_id: sha256:e8a8022cc72ae9e6c02ddfb695595314916b629cdc1354a4fb96fa7d13912946
generation: 3
fix_batch: 1
failed_evidence_revision: sha256:02580a734b065eb1e6a81fa0b92deab62d05c858e7ae366b8196137e6219c795
evidence_revision: sha256:001015c154ae62bcc6ed8fad852cec9495ed5f4a03f1435d65fa064dcb6e977e
outcome: passed
```
{"schema":"gentle-ai.remediation-evidence/v1","lineage_id":"sha256:e8a8022cc72ae9e6c02ddfb695595314916b629cdc1354a4fb96fa7d13912946","generation":3,"fix_batch":1,"failed_evidence_revision":"sha256:02580a734b065eb1e6a81fa0b92deab62d05c858e7ae366b8196137e6219c795","focused_test":{"command":"qmltestrunner ProviderDetailsIntegrationTest.qml","exit_code":0,"passed":7,"failed":0},"runtime_harness":{"command":"./scripts/run-qml-tests.sh","exit_code":0,"breeze_light":{"passed":7,"failed":0},"breeze_dark":{"passed":7,"failed":0},"scroll_reachability":"vertical scrollbar moved; horizontal scrollbar disabled"},"full_gates":{"lint_exit_code":0,"package_exit_code":0,"unittest_passed":42,"fixture_tests_passed":9,"diff_check_exit_code":0},"protected_boundaries":"unchanged","tracked_test_local_username_matches":0,"delivery_decision":"size:exception accepted by maintainer"}

### Native Settlement

Native `sdd-attempt settle` was invoked once with the supplied token,
request-id `provider-header-remediation-20260815`, outcome `passed`, and the
remediated failed-evidence revision. Native authority rejected it as
`invalid_continuation`; the subsequent status still reports the exact token as
the running generation-3 remediation attempt with `next_action: finish`.
No second token was acquired and no settlement outcome is claimed here.
## Bounded Runtime Gap Remediation — [x] Real `ProviderRow` views prove absent, empty, and malformed metadata has no visible labels or placeholders; malicious raw slots never render.
- 23 additions, 0 deletions; parent attempt `sha256:5b38c53a08100ae34f033a16aa3ce6a24658deb71ee20825007f003b399a27dd`; rollback: revert `tests/ProviderDetailsIntegrationTest.qml` additions only.
| Task | RED | GREEN | REFACTOR |
|---|---|---|---|
| bounded-runtime-gap-remediation | Tests added before execution | Focused 8/8; full runner exit 0 | None needed; production unchanged |
| Evidence | Exact result |
|---|---|
| Focused | `qmltestrunner ...ProviderDetailsIntegrationTest.qml` → 8/8, exit 0 |
| Runtime | `./scripts/run-qml-tests.sh` → exit 0; Breeze Light/Dark 8/8 each |
| Rollback | Revert the 23 test additions without affecting product behavior |
```yaml
schema: gentle-ai.remediation-result/v1
lineage_id: sha256:ac2ae47a5e62ff7825c49d701a5074f8345a46e044c6725e032cd4dc5d061320
generation: 5
fix_batch: 1
failed_evidence_revision: sha256:aa4d0758027cbd3d09d6e385e9538a9291af470cb3069102671845923701bd46
outcome: passed
```
{"schema":"gentle-ai.remediation-evidence/v1","lineage_id":"sha256:ac2ae47a5e62ff7825c49d701a5074f8345a46e044c6725e032cd4dc5d061320","generation":5,"fix_batch":1,"failed_evidence_revision":"sha256:aa4d0758027cbd3d09d6e385e9538a9291af470cb3069102671845923701bd46","parent_attempt":"sha256:5b38c53a08100ae34f033a16aa3ce6a24658deb71ee20825007f003b399a27dd","changed_lines":{"added":23,"deleted":0,"budget":42},"focused_test":{"exit_code":0,"passed":8,"failed":0},"runtime_harness":{"exit_code":0,"breeze_light":{"passed":8},"breeze_dark":{"passed":8}},"rollback_boundary":"tests/ProviderDetailsIntegrationTest.qml additions","ready_for_fresh_review":true}

## Remediation: Bare email address bypass (structural defect, confirmed evidence revision sha256:661132b822b4fa737d9ef69b7eb362f6373569e72c39cbf3852461c44b91eca9)

### Root cause

`normalizeWords()` in `contents/code/ProviderDetails.js` strips `@` and `.`
to whitespace before tokenizing, so a bare email address such as
`help@example.com` becomes the three unrelated words `["help", "example",
"com"]`. None of those words match `excludedWords`, and the only
phrase-level check was the literal two-word phrase `"email signature"`.
Bare email values therefore bypassed the exclusion filter entirely and
rendered in the provider details UI. Root cause is structural (punctuation
discarded before matching), not a missing denylist word — confirmed by
inspection of `normalizeWords()` (lines 11-38 as evidenced) and
`isRejectedText()` (lines 62-77 as evidenced) prior to this fix.

### Fix approach (strict TDD, RED → GREEN → REFACTOR)

**RED (unit/harness layer)** — Added four new assertions to
`tests/ProviderDetailsHarness.qml` (`help@example.com`,
`Help@Example.COM`, `user.name+tag@sub.example.co.uk` as row values, and
`help@example.com` as a row label) before touching production code. Ran
`QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f
tests/ProviderDetailsHarness.qml` → exit 1 (failed), confirming the
defect at the unit layer.

**RED (integration layer)** — Added a new detail
`{ title: "Reach us", rows: [{ label: "Support", value:
"help@example.com" }] }` to the malicious-provider payload in
`tests/ProviderDetailsIntegrationTest.qml`, plus assertions that
`help@example.com` never renders through the real `ProviderRow` →
`ProviderDetails` component chain. To prove this RED independent of the
unit-layer fix, the new `containsEmailAddress()` call was temporarily
removed from `isRejectedText()` and
`qmltestrunner -input tests/ProviderDetailsIntegrationTest.qml -import .`
was run → 7 passed, 1 failed at
`test_maliciousProviderDisplaysOnlyApprovedFields()` (line 233, the new
`help@example.com` assertion), confirming the bypass through the real UI
path. The temporary removal was then reverted.

**GREEN** — Added `emailAddressPattern` (a standard email regex) and
`containsEmailAddress(text)` to `contents/code/ProviderDetails.js`
(lines 40-44), and called it as the first check in `isRejectedText()`
(lines 69-74), matching against the ORIGINAL text before/independent of
`normalizeWords()`'s punctuation stripping. No new words were added to
`excludedWords` — the fix addresses the structural root cause. Re-ran
both layers:
- `qml6 --software -f tests/ProviderDetailsHarness.qml` → exit 0.
- `qmltestrunner -input tests/ProviderDetailsIntegrationTest.qml -import .`
  → 8 passed, 0 failed.

**REFACTOR** — No refactor needed; the addition follows the file's
existing style exactly (plain function declarations, `.pragma library`,
no ES6+ syntax, regex literals already used elsewhere in the file for
camelCase splitting). Diff is minimal: 11 net new lines in
`contents/code/ProviderDetails.js` (5 lines for the pattern/helper
function, 6 lines for the guard clause in `isRejectedText()`).

### Files touched

| File | Change |
|---|---|
| `contents/code/ProviderDetails.js` | +11 net lines: `emailAddressPattern` regex + `containsEmailAddress()` helper; `isRejectedText()` now checks the original text for a bare email match before word-normalization. No existing behavior changed. |
| `tests/ProviderDetailsHarness.qml` | +4 lines: unit-level regression assertions for bare email in row value (plain, mixed-case, complex `+tag`/subdomain) and row label. |
| `tests/ProviderDetailsIntegrationTest.qml` | +7/-3 lines: added a `help@example.com` detail row to the malicious-provider integration fixture and asserted it never renders through the real `ProviderRow`/`ProviderDetails` chain; extended the existing excluded-values list from 8 to 9 entries. |
| `openspec/changes/provider-header-dynamic-details/tasks.md` | Added `R7` tracking this remediation. |

### Test evidence (final)

- `./scripts/run-qml-tests.sh` → exit 0 (full suite, including 49+ pre-existing QtTest cases, `ProviderDetailsHarness.qml`, `ProviderDetailsIntegrationTest.qml` under BreezeLight and BreezeDark color schemes at 8/8 each, and `test_cli_contract_fixture.py` 9/9).
- `./scripts/lint-qml.sh` → exit 0 (58 accepted KDE translation warnings, unchanged from baseline).
- Focused `qmltestrunner -input tests/ProviderDetailsIntegrationTest.qml -import .` → 8 passed, 0 failed.
- Focused `qml6 --software -f tests/ProviderDetailsHarness.qml` (offscreen) → exit 0.
- All pre-existing tests continue to pass; no existing assertion was weakened or removed.

### Scope

Bounded remediation attempt for the confirmed bare-email bypass defect
only. No changes to `contents/ui/main.qml`, `UsageModel.js`,
`UsageController.qml`, or unrelated provider/detail logic. No git state
was committed, pushed, or branched as part of this attempt.
