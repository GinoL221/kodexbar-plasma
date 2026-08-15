# Design: Final Popup Parity

## Technical Approach

Keep `UsageController.qml` authoritative, adding only `committedGeneration` on successful snapshot commit. A separate `CostController.qml` consumes that generation and the validated executable path. Presentation is selected-provider-only; `All` is unchanged.

## Architecture Decisions

| Option | Tradeoff | Decision and rationale |
|---|---|---|
| Extend usage execution with cost | Fewer objects, coupled failures | Reject. Preserve exactly `'path' usage --provider all --format json --json-only`, one active generation, queued-refresh coalescing, source/stage/generation guards, retained snapshots, and existing timeout distinctions. |
| Separate cost lifecycle | Duplication | Choose. One active cost process is keyed by provider, committed usage generation, and request serial; duplicate pairs coalesce, selection changes replace work, and stale callbacks cannot publish. |
| Fetch cost for every provider | Faster tab switching, expensive scans | Reject. Under the hybrid strategy, `main.qml` requests cost only while a supported provider is selected: after a successful usage commit, or on selection when the current-generation record is missing. `All` starts no cost work and reads no cost records. |
| Render raw fields directly | Minimal code, privacy/schema risk | Reject. Extend `ProviderDetails.js` with read-only display extractors and add `CostModel.js`; QML performs composition only, never pricing or field inference. |

## Data Flow

    refresh -> UsageController -> committedProviders + committedGeneration
                                  | selected provider
                                  v
    ProviderSelector -> main.qml -> CostController -> provider/generation snapshot
                                  |
                                  v
                 ProviderRow -> reusable conditional sections

`CostController` allowlists verified providers (`codex`, `claude`) and emits exactly `cost --provider {shell-quoted provider} --format json --json-only` through `effectiveCommandPath`. It atomically replaces `{provider, usageGeneration, source, sessionCostUSD, sessionTokens, last30DaysCostUSD, last30DaysTokens}` records after exact provider match and finite, non-negative values. A 60-second watchdog disconnects the source; invalid, failed, timed-out, or superseded results publish nothing and never mutate usage.

## File Changes

| File | Action | Description |
|---|---|---|
| `contents/ui/UsageController.qml` | Modify | Expose committed snapshot generation; leave command and lifecycle branches intact. |
| `contents/ui/CostController.qml`, `contents/code/CostModel.js` | Create | Isolated command, correlation, normalization, coalescing, timeout, and snapshots. |
| `contents/code/ProviderDetails.js` | Modify | Validate pace by named window, `credits.remaining`, reset inventory/expiries, `usage.updatedAt`, email, and organization; reject UUID and long hex-like organizations. Identity fields prefer `usage.identity`, then documented `usage` fallback. |
| `contents/ui/main.qml`, `ProviderSelector.qml`, `ProviderRow.qml`, `UsageWindowRow.qml` | Modify | Coordinate selected cost, compact icon/name tabs, header and pace composition; keep summaries unenriched. |
| `contents/ui/ProviderHeader.qml`, `ResetCreditsSection.qml`, `CostSection.qml` | Create | Native reusable, conditional, wrapping sections; reset disclosure is keyboard reachable and announces expanded state. |
| `tests/**`, `tests/fixtures/codexbar-cost-capture.json`, `scripts/run-qml-tests.sh` | Modify/Create | Add contract, lifecycle, rendering, narrow-width, and Breeze fixtures/harnesses. |
| `README.md`, `docs/cli-contract-capture.md`, `docs/live-plasma-smoke.md` | Modify | Document exact contracts, redaction, optional cost, exclusions, and live checks; delta specs remain acceptance authority and archive later syncs main specs. |

## Interfaces / Contracts

`CostController.request(provider, usageGeneration)` coalesces an identical active/fresh pair; `snapshotFor(provider, usageGeneration)` returns a validated snapshot or `null`. `ProviderDetails.js` returns copied display objects/arrays consumed through QML `readonly` properties. Sections are absent—not placeholder/error rows—when validation fails.

## Testing Strategy

Strict RED-GREEN-REFACTOR applies per slice: (1) capture/model; (2) exact argv and lifecycle; (3) extractors and selected-vs-`All`; (4) responsive/a11y/Breeze integration, docs, lint, package validation, and live `plasmawindowed` smoke. Extend `UsageControllerFixture.qml`, `ProviderSelectorHarness.qml`, `ProviderRowHarness.qml`, and `ProviderDetailsIntegrationTest.qml`; add focused cost QtTest/DataSource harnesses to `run-qml-tests.sh`. Existing usage regressions run unchanged first.

## Threat / Risk Matrix

| Boundary | Applicability | Safe/failure behavior | Planned RED test |
|---|---|---|---|
| Documentation-like paths | N/A: no executable classification | No classifier added | None |
| Git repository selection | N/A: no repository routing | No Git invocation | None |
| Commit state | N/A: no commit automation | No index mutation | None |
| Push state | N/A: no push automation | No remote mutation | None |
| PR commands | N/A: no PR automation | No PR invocation | None |
| PII | Applicable | Show CLI email only in selected header; reject opaque org; fixtures fail closed if unredacted | PII/org and fixture-redaction cases |
| Subprocess arguments / external CLI | Applicable | Validated absolute executable, shell-quoted allowlisted provider, fixed argv; never reimplement providers/auth | Exact argv and hostile provider/path cases |
| Stale data | Applicable | Provider+committed-generation+serial match required; otherwise discard | Selection/refresh/reconnect races |
| Cost scan latency | Applicable | One process, duplicate coalescing, replacement, 60s disconnect; usage remains usable | coalesce, timeout, termination |
| Malformed CLI data | Applicable | Validate types/ranges/match; hide section and diagnostics | empty/partial/non-finite/wrong-provider/nonzero cases |

## Migration / Rollout

No data migration. Overall scope is likely above 400 authored lines: use four independently green work units matching the testing slices, each targeting under 400 lines. With `ask-on-risk`, tasks must require approval for chained PRs before apply rather than forcing one oversized review.

## Open Questions

None blocking; additional cost providers require new captured contract evidence before allowlisting.
