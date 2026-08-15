## Exploration: final-popup-parity

### Current State
The popup is a native Plasma/Kirigami `main.qml` surface: a refresh button, scroll view, provider selector, summary rows, selected-provider `ProviderRow`, and error summary. `UsageController.qml` owns path validation, the exact all-provider `usage` command, one active generation, watchdog, coalescing, stale-callback guards, and retained usage snapshots. `UsageModel.js` preserves each original CLI entry as `raw`, while `ProviderDetails.js` currently permits only version, login method, and sanitized details.

The committed usage fixture confirms `pace`, `credits`, `usage.updatedAt`, account email, and `usage.codexResetCredits`; the observed Codex entry has `availableCount: 0`, so the new reset-credit section must be conditionally absent. Current main specs explicitly exclude pace, credits, cost, email, and organization, so this change requires a deliberate delta rather than treating raw preservation as display authorization.

### Affected Areas
- `contents/ui/main.qml` — popup composition, native refresh/header/footer placement, selected-provider content order, and cost-controller wiring.
- `contents/ui/ProviderSelector.qml` — tabs currently render provider plus source; parity requires icon and short name only while preserving source in accessibility metadata.
- `contents/ui/ProviderRow.qml` — selected-provider header and conditional usage enrichment; summary/All rows must remain excluded from identity, pace, credits, resets, and cost.
- `contents/code/ProviderDetails.js` — narrow validated extractors for identity, organization filtering, pace, credits, reset inventory, and cost display data; current exclusion logic must not accidentally suppress the newly approved fields.
- `contents/ui/UsageController.qml` — remains authoritative for usage only; its snapshot/generation contract is the boundary a separate cost flow must not weaken.
- `contents/ui/CostController.qml` (new) — isolated optional `cost --provider {provider} --format json --json-only` lifecycle and provider-keyed snapshots.
- `tests/UsageControllerFixture.qml`, `tests/UsageController*Harness.qml` — protect unchanged usage command, coalescing, stale completion, timeout, and retained-snapshot behavior.
- `tests/ProviderDetailsIntegrationTest.qml`, new focused QML fixtures/harnesses — establish RED cases for selected-header identity, human-readable organization, pace/credits, zero/nonzero reset inventory, tabs, and cost failure/staleness.
- `tests/fixtures/` and `docs/cli-contract-capture.md` — add a redacted, separately pinned cost capture and document that usage and cost are distinct CLI contracts.
- `openspec/specs/provider-usage-display/spec.md` — replace the current provider-focused exclusions with tightly scoped display permissions and preserve all other external-boundary exclusions.

### Approaches
1. **Separate optional cost controller** — retain `UsageController` as the sole usage lifecycle owner and give `cost` its own provider-keyed, generation-guarded snapshot flow.
   - Pros: preserves the exact usage command and its one-active-request invariant; a cost error cannot replace usage state; independently testable and reviewable.
   - Cons: adds a small controller and explicit synchronization rules.
   - Effort: Medium.

2. **Add cost as a stage in UsageController** — run `cost` after usage in the existing controller generation.
   - Pros: fewer QML objects and one nominal refresh path.
   - Cons: couples optional cost latency/failure to usage release, watchdog, coalescing, and snapshot semantics; risks violating the protected lifecycle contract.
   - Effort: Medium-High.

### Recommendation
Use a separate `CostController` and keep it optional. Commit usage first through the unchanged controller; request cost only for explicitly supported provider keys using the configured executable and exact provider-specific command. Key a cost result to the usage snapshot generation plus provider, coalesce duplicate requests, and discard stale callbacks when either changes. Cost must render only when its matching successful snapshot exists, be labeled as a local token-cost estimate, and never alter the usage phase, errors, or snapshot.

Keep presentation extractors narrow and selected-provider-only: email from CLI identity/account fields; organization only after rejecting UUID/hex-like identifiers; `updatedAt`, plan/login badge, pace, `credits.remaining`, and `codexResetCredits` only when structurally valid. Hide reset inventory unless `availableCount > 0`, show listed expiry data only when supplied, and omit unavailable/invalid fields without placeholders. Retain Plasma/Kirigami/Breeze layout and accessible controls; do not clone macOS glass or add account, auth, quit, redeem, or price-calculation actions.

Review-budget slices (ask-on-risk, 400 changed lines): (1) contract captures/spec and extractor tests, (2) selected-provider/header/tabs plus pace-credit-reset UI and tests, (3) isolated cost controller plus lifecycle/UI tests, and (4) footer/manual Plasma smoke/docs. Each slice is expected to be reviewable independently; split further if a slice approaches 400 authored changed lines.

### Risks
- A cost callback can arrive after a newer usage refresh or provider selection; provider and usage-generation correlation is required before commit/render.
- Folding cost into `UsageController` can block or corrupt protected usage lifecycle states, retained snapshots, and exact-command tests.
- Account email is PII and organization values may be opaque IDs; fixtures require leaf-only redaction and display must reject non-human-readable organization tokens.
- Existing spec and integration tests assert these fields are excluded; they must be replaced deliberately, not silently loosened.
- The fixture demonstrates zero Codex reset credits but not a positive inventory or a separate cost payload, so both need redacted contract evidence before implementation.

### Ready for Proposal
Yes — proceed with a proposal that explicitly authorizes these narrow display fields and the separate cost CLI contract, preserves `usage --provider all --format json --json-only` unchanged, and schedules the four review-budget slices above.
