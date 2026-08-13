# Apply Progress: Provider-Focused Popup UI

## Work Unit

Bounded correction / error-summary-sanitization.
Chain strategy: `stacked-to-main` — this final documentation slice targets `main` and remains autonomous for a future PR.

## Completed Tasks

- [x] 1.1 Create `tests/ProviderSelectorHarness.qml`
- [x] 1.2 Extend `tests/ProviderRowHarness.qml`
- [x] 1.3 Register `ProviderSelectorHarness` in `scripts/run-qml-tests.sh`
- [x] 2.1 Create `contents/ui/UsageWindowRow.qml`
- [x] 2.2 Create `contents/ui/ProviderSelector.qml`
- [x] 2.3 Modify `contents/ui/ProviderRow.qml`
- [x] 2.4 Modify `contents/ui/main.qml`
- [x] 3.1 Run focused harnesses and `./scripts/run-qml-tests.sh`
- [x] 4.1 Document selector/detail live-Plasma checks and preserved CLI invocation
- [x] 3.2 Sanitize expanded provider failure messages with representative raw-error harness coverage

## Remaining Tasks

- [ ] 4.2 Manual `plasmawindowed` smoke

## Files Changed

| File | Action | Lines | What Was Done |
|------|--------|------:|---------------|
| `tests/ProviderSelectorHarness.qml` | Created | 87 | RED harness for first-usable default, explicit `All`, pending load, reorder/removal/reopen fallback, null/duplicate identity, narrow geometry, keyboard/accessibility state. |
| `tests/ProviderRowHarness.qml` | Modified | +89/-6 | Extended with compact/detail mode, selector-owned `iconResolver`, elided name/source + full-source accessibility, finite/string/null/non-finite percentage guards, exact reset handling, shared `UsageWindowRow` assertions. |
| `scripts/run-qml-tests.sh` | Modified | +1 | Added `ProviderSelectorHarness` to the qml6 offscreen harness loop. |
| `contents/ui/UsageWindowRow.qml` | Created | 112 | Shared compact/detail window renderer with finite percentage and raw reset handling. |
| `contents/ui/ProviderSelector.qml` | Created | 227 | Native scrollable selector with transient identity reconciliation, pending-load default, accessibility, and existing icon fallback. |
| `contents/ui/ProviderRow.qml` | Modified | +43/-70 | Composes shared window rows and consumes the selector-owned icon resolver. |
| `contents/ui/main.qml` | Modified | +24/-6 | Wires selector to committed providers and switches compact All/detail presentation without changing controller or CLI behavior. |
| `README.md` | Modified | Documentation-only | Clarifies transient presentation-only selection, first-usable default, compact `All`, supplied detail fields, and exclusions. |
| `docs/live-plasma-smoke.md` | Modified | Documentation-only | Adds the provider-focused live manual checklist, including exact unchanged CLI argv. |

| `tests/ErrorSummaryHarness.qml` | Modified | Added RED/GREEN assertions for authentication guidance, local paths, commands, API-key text, platform diagnostics, preserved count/order/bound, and keyboard behavior. |
| `contents/ui/ErrorSummary.qml` | Modified | Deterministic safe classifier returns only authentication, platform-support, configuration, or unavailable messages. |

Total authored changed lines across cumulative PR1 + PR2 work: within the configured review budget; the `docs-smoke` documentation diff is +3/-1 in `README.md` and +19/-0 in `docs/live-plasma-smoke.md` (23 changed lines), under the 120-line cap, and unrelated worktree changes remain untouched.

## Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test command | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/ProviderSelectorHarness.qml` |
| Exact result | Pass, exit code `0`; selector assertions including refresh/reorder/reopen/null/duplicate/narrow keyboard cases completed. |
| Focused test command | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/ProviderRowHarness.qml` |
| Exact result | Pass, exit code `0`; finite/null/string/non-finite percentage, raw reset, compact/detail, resolver, elision, and accessibility assertions completed. |
| Full runner command | `./scripts/run-qml-tests.sh` |
| Exact result | Pass, exit code `0`; 32 QtTest assertions across three suites plus all executable harnesses and termination checks passed. The `UsageControllerDataSourceLifecycleHarness` exact argv assertion (`usage --provider all --format json --json-only`) passed unchanged. |
| Runtime harness scenario | Offscreen qml6 harnesses against fixture provider arrays; no live Plasma runtime boundary exists for this slice. |
| Rollback boundary | Revert only `contents/ui/UsageWindowRow.qml`, `contents/ui/ProviderSelector.qml`, and the production changes in `contents/ui/ProviderRow.qml` and `contents/ui/main.qml`; preserve unrelated worktree edits. |

### Error-Summary Sanitization Work Unit Evidence

| Evidence | Value |
|---|---|
| Safety-net baseline | `./scripts/run-qml-tests.sh` — pass, exit code `0`; 32 existing QtTest assertions/harness execution completed before edits. |
| Focused RED command | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/ErrorSummaryHarness.qml` — fail, exit code `1`; new safe-message assertions failed against raw `failureText`. |
| Focused GREEN command | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/ErrorSummaryHarness.qml` — pass, exit code `0`; authentication, availability, platform, path/API-key/command redaction, count/order/bound, and keyboard assertions passed. |
| Full runner command | `./scripts/run-qml-tests.sh` — pass, exit code `0`; QtTest totals `8 + 16 + 8` passed, all executable harnesses including `ErrorSummaryHarness` passed, and exact CLI argv regression remained covered. |
| Runtime harness scenario | Offscreen `qml6` ErrorSummary harness with 23 response-ordered failures; first three include API-key/auth guidance, a local path and command, and platform diagnostics. No live Plasma runtime was available. |
| Rollback boundary | Revert only `contents/ui/ErrorSummary.qml`, `tests/ErrorSummaryHarness.qml`, and the corresponding active spec/tasks/apply-progress correction entries. |

### Docs-Smoke Work Unit Evidence

| Evidence | Value |
|---|---|
| Safety-net runner | `./scripts/run-qml-tests.sh` — pass, exit code `0`; 32 QtTest assertions across three suites plus all executable harnesses passed. Existing offscreen `i18n`/`i18np` warnings remain non-failing. |
| Focused documentation check | `git diff --check` — pass, exit code `0`; the exact documentation/artifact diff has no whitespace errors. |
| Runtime smoke scenario | Manual `plasmawindowed org.kde.plasma.kodexbar.plasma` in Breeze Light/Dark with the documented selector, detail, refresh, error, keyboard, and narrow-overflow checks. Not run in this headless apply environment; task 4.2 remains pending for a live Plasma observer. Native attempt token `sha256:c157bd301e3c12578ccb685e2c48aead6a07eac79697a994b390e0381a21bc9b` was not acquired or settled. |
| Documentation diff | `README.md` documents transient presentation-only selection, first usable default, compact `All`, supplied Session/Weekly/Monthly/raw reset detail, and cost/credits/tokens/calculated-reset exclusions. `docs/live-plasma-smoke.md` documents first-provider, selector identity, All/detail, missing-field, keyboard, overflow, Breeze, reconciliation, global-error, and exact-argv checks. |
| Rollback boundary | Revert only the provider-focused paragraphs in `README.md` and the `## Provider-focused popup` section in `docs/live-plasma-smoke.md`; retain all runtime code, tests, CLI behavior, and unrelated documentation. |

## TDD Cycle Evidence (Strict TDD)

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 1.1 | `tests/ProviderSelectorHarness.qml` | QML harness | 16/16 qmltestrunner + all prior harnesses green | Written; fails to load because `ProviderSelector` is absent | Expected RED in PR1; GREEN in PR2 when `ProviderSelector.qml` is implemented | 10+ cases (empty, first usable, explicit All, pending load, reorder, removal, reopen, null identity, duplicate identity, narrow geometry, keyboard/accessibility) | N/A for RED slice |
| 1.2 | `tests/ProviderRowHarness.qml` | QML harness | 16/16 qmltestrunner + all prior harnesses green | Written; fails to load because `UsageWindowRow` and new `ProviderRow` properties are absent | Expected RED in PR1; GREEN in PR2 when `UsageWindowRow.qml` and `ProviderRow.qml` changes land | 7+ cases (finite, null, string, Infinity, NaN percentages; compact/detail; exact resets; elided name/source; iconResolver) | N/A for RED slice |
| 1.3 | `scripts/run-qml-tests.sh` | Runner registration | 16/16 qmltestrunner + all prior harnesses green | Harness entry added; runner fails at the new RED harness as expected | Expected RED in PR1; GREEN in PR2 when components exist | N/A (structural registration) | N/A for RED slice |
| 2.1 | `tests/ProviderRowHarness.qml` | Integration | Focused row harness passed before/after implementation | Existing RED assertions referenced missing `UsageWindowRow` | Passed: finite, null, string, Infinity, NaN, raw resets, compact/detail | Passed: multiple data shapes | Passed: shared renderer removed duplicated logic |
| 2.2 | `tests/ProviderSelectorHarness.qml` | Integration | New harness was RED before implementation | Harness written in PR1; initial implementation exposed TabBar reset bug | Passed: full selector harness, including refresh/reorder/reopen/null/duplicate/narrow cases | Passed: 10+ selection and lifecycle cases | Passed: identity-based selection and stable delegate capacity |
| 2.3 | `tests/ProviderRowHarness.qml` | Integration | Focused row harness passed before/after implementation | Extended harness referenced new row surface | Passed: compact/detail composition and selector resolver | Passed: resolver, elision, accessibility, window edge cases | Passed: duplicated finite/reset rendering removed |
| 2.4 | `tests/ProviderSelectorHarness.qml`, `tests/ProviderRowHarness.qml` | Integration | Focused harnesses passed | Harnesses defined popup wiring surface | Passed: both focused harnesses | Passed: All/detail and selector state scenarios | Passed: presentation-only main wiring |
| 3.1 | `scripts/run-qml-tests.sh` | Regression/runtime | Full pre-existing suite was green in PR1 | New harnesses were intentionally RED in PR1 | Passed: full runner, all QtTest and executable harnesses | Passed: lifecycle, stale, timeout, snapshot, errors, settings, termination | N/A |
| 4.1 | Documentation-only (`README.md`, `docs/live-plasma-smoke.md`) | Manual documentation | `./scripts/run-qml-tests.sh` passed before documentation edits | N/A — no production behavior or permitted automated test surface changes | N/A — no production behavior changed | N/A — checklist covers distinct default, detail, omission, keyboard, overflow, theme, reconciliation, and error scenarios | Clean; no code refactor required |
| 3.2 | `tests/ErrorSummaryHarness.qml` | QML harness | 32/32 prior runner assertions and harnesses green | Written first; failed with raw auth/path/platform details | Passed with deterministic safe classifier and no raw detail leakage | Three representative raw-error categories plus count/order/bounded and keyboard regressions | Simplified classification to explicit substring categories; full runner remained green |

## Deviations from Design

The selector uses a stable delegate capacity while the popup is open because Qt Quick Controls `TabBar` resets `currentIndex` during synchronous `Repeater` model rebuilds. Surplus delegates are hidden and non-focusable; visible tabs preserve response order and the harness remains unchanged. This avoids conflating a model-reset event with explicit `All` selection.

## Issues Found

The offscreen selector emitted Qt Fusion warnings for the themed fallback icon name being treated as a local `icon.source`; this did not affect assertions or exit status. Existing settings tests also emit `i18n`/`i18np` warnings under qmltestrunner while passing.

## Notes

- The `ProviderSelectorHarness` references the intended public surface (`providers`, `phase`, `popupOpen`, `usableProviders`, `allSelected`, `selectedProvider`, `tabBar`, `iconResolver`).
- The `ProviderRowHarness` references the intended new surface (`compact`, `iconResolver`, `providerLabel`, `sourceLabel`, `iconSource`, and a shared `UsageWindowRow` with `progressBar`, `percentageLabel`, `resetsAtLabel`, `resetDescriptionLabel`).
- `ProviderSelectorHarness.qml` contains no fixture typo: its duplicate-provider accessibility assertion intentionally checks the first response entry's `src-dup-a` source.
- The external CLI/lifecycle contract remains unchanged; the full runner confirmed the exact lifecycle argv assertion.
- Task 4.2 requires a real interactive `plasmawindowed` session and remains deliberately unchecked; this headless documentation slice does not claim live runtime evidence.
