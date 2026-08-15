# Design: Dynamic Provider Header Details

## Technical Approach

Keep the existing `CodexBar CLI → UsageController.qml → UsageModel.js → QML UI` boundary. `ProviderRow.qml` will derive a presentation-only view from `providerData.raw`: conditional version/login metadata and filtered `usage.details[]`. A pure JavaScript helper will make validation and exclusions deterministic; a native disclosure component will render only accepted values. `main.qml` retains its 44-grid-unit popup bound with explicit scrollbar policies.

## Architecture Decisions

| Option | Tradeoff | Decision |
|---|---|---|
| Inline raw traversal | Fewer files, but couples validation, privacy, and rendering | Reject; create `contents/code/ProviderDetails.js` as a testable presentation sanitizer. |
| Reuse `ErrorSummary.qml` disclosure conventions | Native and established without sharing error semantics | Create `ProviderDetails.qml` with a checkable `QQC2.ToolButton`, themed arrows, focus, and Return/Space activation. |
| Enrich every summary | Changes compact and `All` presentation | Reject; render enrichment only when `!compact && !summary`. |
| Search multiple login paths | Broad compatibility, but invents unspecified precedence | Reject. Accept only non-empty string `raw.usage.loginMethod`; `raw.usage.identity.loginMethod` is account metadata, not a fallback. This provider-neutral rule follows the committed capture's `usage` contract and omits absent/invalid values deterministically. |
| Provider-specific exclusions | More precise but moves provider knowledge into UI | Reject; use one provider-neutral, fail-closed textual contract. |

## Data Flow

```text
provider.raw ──→ ProviderDetails.js ──→ safe header/details view
                                              │
                   ProviderRow.qml ──→ ProviderDetails.qml
                                              │
                   main.qml bounded ScrollView┘
```

`UsageModel.js`, `UsageController.qml`, compact selection, request lifecycle, and exact all-provider CLI invocation remain unchanged.

## File Changes

| File | Action | Description |
|---|---|---|
| `contents/code/ProviderDetails.js` | Create | Read only `raw.version`, `raw.usage.loginMethod`, and `raw.usage.details`; validate and exclude unsafe content. |
| `contents/ui/ProviderDetails.qml` | Create | Native collapsed disclosure with wrapped rows. |
| `contents/ui/ProviderRow.qml` | Modify | Add conditional metadata and selected-provider details. |
| `contents/ui/main.qml` | Modify | Disable horizontal scrolling and use as-needed vertical scrolling. |
| `tests/ProviderDetailsHarness.qml` | Create | RED-first extraction, filtering, accessibility, activation, and geometry coverage. |
| `tests/test_cli_contract_fixture.py` | Create | Pin the Phase 1 fixture bytes and verify JSON/provenance/redaction evidence without rewriting it. |
| `scripts/run-qml-tests.sh` | Modify | Register the offscreen QML harness and fixture-evidence test. |
| `tests/fixtures/codexbar-usage-capture.json` | Preserve | Already-committed Phase 1 real capture; no recapture, rescrub, or content change. |
| `docs/cli-contract-capture.md` | Preserve/verify | Authority for fixture path, 2026-08-14 capture date, CodexBar's non-self-reported version result plus binary pin, and lossless leaf-only redaction procedure. |
| `README.md`, `docs/live-plasma-smoke.md` | Modify | Document display exclusions and manual keyboard/theme/scroll checks. |

## Interfaces / Contracts

`ProviderDetails.js` returns strings/details only and never mutates `raw`. Version accepts only a non-empty `raw.version` string. Login accepts only a non-empty `raw.usage.loginMethod` string; identity-only or malformed values are omitted, so no precedence exists.

Details require a non-array object with non-empty string `title`, array `rows`, and at least one accepted row. Rows require non-empty string `label` and `value`; `secondaryValue` is absent/null or a string. Nothing is stringified.

For inspection only, titles and row strings are camel-case split, lowercased, and separator-normalized. A matching title rejects its detail; a matching row rejects that row for email/e-mail, organization/organisation, pace, credit(s), cost(s), token(s), or an email signature. Empty details are omitted. Accepted strings render unchanged with `Text.PlainText`.

The disclosure starts unchecked, exposes provider-specific accessible name/state, uses Kirigami theme units/colors, and wraps at zero minimum width. Vertical scrolling is as-needed; horizontal scrolling is disabled.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit/harness | Single login source, malformed shapes, exclusions in every slot, verbatim text | RED cases in `ProviderDetailsHarness.qml`, including identity-only and conflicting identity values being ignored. |
| Component | Conditional metadata, collapsed default, pointer/keyboard activation, accessibility, narrow/long rows | Instantiate real components offscreen. |
| Evidence | Fixture provenance, version/date record, and lossless redaction | `tests/test_cli_contract_fixture.py` pins Phase 1 bytes, parses JSON, checks `docs/cli-contract-capture.md` path/date/version outcome, leaf-only rule, and sensitive-pattern gates; retain archived Phase 1 value/key/type evidence. Never recapture or rescrub. |
| Regression | Four-key model, controller lifecycle, compact selection, exact CLI argv | Run `./scripts/run-qml-tests.sh`, `./scripts/lint-qml.sh`, and confirm model/controller/fixture diffs are empty. |
| Manual | Breeze Light/Dark, Tab/Enter/Space, focus, vertical scrolling | Extend `docs/live-plasma-smoke.md`. |

## Threat Matrix

N/A — No shell, routing, subprocess, VCS/PR automation, or process integration is introduced.

## Migration / Rollout

No migration required; this is reversible presentation enrichment over preserved raw data.

## Open Questions

None.
