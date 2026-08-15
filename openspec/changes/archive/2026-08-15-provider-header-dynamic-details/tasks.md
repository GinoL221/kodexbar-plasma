# Tasks: Dynamic Provider Header Details

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~320–400 (authored additions + deletions) |
| 400-line budget risk | Medium |
| Chained PRs recommended | No |
| Suggested split | Single PR / single work unit |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: stacked-to-main
400-line budget risk: Medium

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | RED harness + sanitizer + native disclosure + bounded layout + docs | PR 1 | `./scripts/run-qml-tests.sh && ./scripts/lint-qml.sh` | `qml6` offscreen `tests/ProviderDetailsHarness.qml` + `python3 tests/test_cli_contract_fixture.py` (QT_QPA_PLATFORM=offscreen) | Revert `contents/code/ProviderDetails.js`, `contents/ui/ProviderDetails.qml`, `ProviderRow.qml`/`main.qml` presentation edits, harness, fixture-evidence test, docs; `UsageModel.js`/`UsageController.qml` untouched so normalized snapshot + CLI stay usable. |

## Phase 1: RED-First Harness & Fixture Evidence

- [x] 1.1 Create `tests/ProviderDetailsHarness.qml` RED cases: malformed `raw.usage.details` (non-array, missing rows, empty), identity-only and conflicting `identity.loginMethod` ignored, single `raw.usage.loginMethod` source, exclusions in every slot (email/e-mail, organization/organisation, pace, credit(s), cost(s), token(s), email signature), verbatim `Text.PlainText` rendering.
- [x] 1.2 Add RED component cases: disclosure starts unchecked, Tab focus, Return/Space activation, accessible name/state, zero-min-width wrap, narrow/long rows, Breeze Light/Dark.
- [x] 1.3 Create `tests/test_cli_contract_fixture.py` pinning `tests/fixtures/codexbar-usage-capture.json` bytes, parse JSON, assert `docs/cli-contract-capture.md` path, 2026-08-14 capture date, CodexBar non-self-reported version + binary pin, leaf-only redaction rule, sensitive-pattern gates; retain archived Phase 1 value/key/type evidence; never recapture or rescrub (scenario: Real capture fixture provenance and redaction).
- [x] 1.4 Modify `scripts/run-qml-tests.sh` to register offscreen `ProviderDetailsHarness.qml` and `test_cli_contract_fixture.py`; expect RED.

## Phase 2: Presentation Sanitizer & Filter Contract (GREEN)

- [x] 2.1 Create `contents/code/ProviderDetails.js`: read-only `raw.version`, `raw.usage.loginMethod`, `raw.usage.details`; never mutate `raw`; no stringification.
- [x] 2.2 Implement validation: version = non-empty string; login = non-empty `raw.usage.loginMethod` only; detail = object with non-empty string `title`, array `rows`, ≥1 accepted row; row = non-empty `label`+`value`, `secondaryValue` absent/null or string.
- [x] 2.3 Implement inspection-only rejection (camelCase split, lowercase, separator-normalize): email/e-mail, organization/organisation, pace, credit(s), cost(s), token(s), email signature; empty details omitted; GREEN harness passes (scenarios: Header metadata conditional, Invalid details safe, Raw preservation authorized fields).

## Phase 3: Header & Details UI

- [x] 3.1 Create `contents/ui/ProviderDetails.qml`: unchecked `QQC2.ToolButton` disclosure, themed arrows, `Kirigami.Units`/`Kirigami.Theme`, focus, Return/Space activation, accessible name/state, zero-min-width wrap (scenario: Details collapsed and accessible).
- [x] 3.2 Modify `contents/ui/ProviderRow.qml`: conditional version/login display without placeholders, selected-only render (`!compact && !summary`), delegate filtered details to `ProviderDetails.qml`.
- [x] 3.3 GREEN: offscreen component instantiation passes accessibility, activation, narrow/long-row, and theme cases.

## Phase 4: Integration & Layout

- [x] 4.1 Modify `contents/ui/main.qml`: disable horizontal scrolling, as-needed vertical scrolling inside 44-grid-unit popup bound.
- [x] 4.2 RED→GREEN overflow: expanded details exceeding height stay reachable vertically; no horizontal overflow (scenario: Expanded details remain bounded).

## Phase 5: Docs & Spec Reconciliation

- [x] 5.1 Update `README.md` and `docs/live-plasma-smoke.md`: document display exclusions and manual keyboard/theme/vertical-scroll checks.

## Phase 6: Full Verification

- [x] 6.1 Run `./scripts/run-qml-tests.sh` and `./scripts/lint-qml.sh`; confirm `UsageModel.js`/`UsageController.qml`/fixture diffs are empty.
- [x] 6.2 Confirm unchanged runtime boundaries: compact selection, request lifecycle, and exact all-provider CLI argv unchanged (scenarios: Presentation enrichment preserves runtime boundaries; Verbatim passthrough of unmodeled fields).
- [x] 6.3 Verify email/organization/pace/credits/cost/tokens never display and no commercial/reset data is fabricated (scenarios: Raw preservation authorized fields; Missing commercial or reset data).

## Resolved Workload Decision

- Actual implementation size: approximately 728 authored additions, above the 400-line review budget.
- The maintainer explicitly accepted `size:exception` for this single work unit; no slice split is required before verification.

## Remediation: Verification blockers

- [x] R1 Add integrated `ProviderRow` runtime coverage for conditional version/login/details rendering, malformed details, and approved-only display with a malicious provider payload.
- [x] R2 Add exact runtime Return/Space activation, changed accessible state, and Breeze Light/Dark evidence for the real details disclosure.
- [x] R3 Add runtime over-height vertical reachability coverage with horizontal overflow disabled, and register every remediation harness in the focused runner.
- [x] R4 Remove every `/home/ginopc` literal from tracked test artifacts and enforce generic home-path assertions across `tests/`.
- [x] R5 Clarify README display exclusions without changing the approved version/login/details display contract.
- [x] R6 Run the required focused/full remediation gates, confirm protected boundaries and Phase 1 artifacts are byte-unchanged, and persist cumulative hybrid evidence.

## Remediation: Bare email address bypass (structural defect)

- [x] R7 Fix `isRejectedText()` in `contents/code/ProviderDetails.js` to detect bare email addresses (e.g. `help@example.com`) against the original text before word-normalization strips `@`/`.`, and add unit (harness) and integration (`ProviderRow`) regression coverage proving such values never render.
