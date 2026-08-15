# Proposal: CLI Contract Fixtures & Enrichment-Ready Normalization

## Intent

Establish, for the first time, evidence of what the real `codexbar usage --provider all --format json --json-only` payload actually contains on this user's Linux machine, and stop the normalization layer from silently destroying everything in it that is not one of four keys.

Today `contents/code/UsageModel.js:35-54` (`normalizeProvider`) returns exactly `{ provider, source, windows }` and never reads any other top-level key on a provider entry. Upstream CodexBar documents `version`, `status`, `identity`, `credits`, `pace`, and a generic `usage.details` array — none of which exist anywhere in this repository's code, tests, or fixtures. The only fixture in the tree, `tests/fixtures/codexbar-lifecycle-fixture.sh:15`, is one hand-authored synthetic line (`[{"provider":"fixture","usage":{"primary":{"usedPercent":42}}}]`). No real payload has ever been captured here.

This change delivers roadmap Phase 0 (verify the real CLI contract with a real, redacted capture) and Phase 1 (preserve rich CLI data in normalization) as one reviewable unit. It is a **data-layer change only**. Nothing new is rendered. Nothing is fetched, computed, or fabricated. The CLI invocation is byte-for-byte unchanged.

## Scope

### In Scope

- **A documented capture-and-redaction procedure** (`docs/cli-contract-capture.md`, new) that the user follows on their own machine to produce a real, redacted, structurally-faithful CodexBar payload. This procedure is the deliverable of this proposal; the actual capture happens during apply and is gated on the user.
- **At least one redacted real capture committed as a contract fixture** under `tests/fixtures/`, preserving every key, every type, and the full nesting depth of the real output, with only sensitive leaf *values* replaced.
- **An additive `raw` verbatim-passthrough sibling** on each provider entry returned by `normalizeProvider`, holding the original CLI entry object unchanged, alongside the existing `provider`, `source`, and `windows` keys.
- **Strict-TDD tests** (per `openspec/config.yaml:10`) asserting that `raw` is present, verbatim, and that the existing four-key contract is byte-for-byte unaffected.
- **Reconciliation of `README.md`'s "MVP exclusions" prose** and of `openspec/specs/provider-usage-display/spec.md:325-332` ("Provider-focused exclusions"), so the documented product scope stops asserting something the data layer no longer does. The exact proposed replacement prose is drafted below and applied during apply, not now.

### Out of Scope

Explicit non-negotiables for this change:

- **No UI whatsoever.** No pace, credits, cost, token, richer-timestamp, dynamic-window, or per-provider-metadata rendering. That is roadmap Phase 2+ and is a separate change with its own proposal.
- **No change to the CLI invocation.** `UsageController.qml:38` keeps emitting exactly `usage --provider all --format json --json-only`.
- **No provider, OAuth, credential, cookie, probing, or account logic.** Those remain CodexBar's responsibility, permanently.
- **No change to the stable four-key contract's shape or semantics**: `provider`, `source`, and `windows[].{key,label,usedPercent,resetsAt,resetDescription}` keep their exact current values, types, ordering, and null behavior.
- **No change to `normalizeWindow`.** Window-level unknown-key dropping stays exactly as it is; `tests/UsageModelTest.qml:65-81` and `tests/UsageModelHarness.qml:26,38` stay valid and unedited.
- **No typed field promotion.** No new first-class named property for `pace`, `credits`, `identity`, `version`, or `status` is introduced by this change. That decision is deliberately deferred (see Alternatives).
- **No cost or token computation of any kind.** If the CLI does not emit a value, nothing is derived, estimated, or requested.
- **No touching `openspec/changes/persistent-datasource-lifecycle/`.** That stray un-archived directory is unrelated leftover state, flagged for separate cleanup.

## User and Developer Value

**For the user:** nothing changes visibly today — and that is the point. What changes is that the next phase becomes possible at all: once the CLI's richer fields survive normalization, the roadmap's provider header, pace projection, and credits work can be built against real captured evidence instead of guesses. It also means that when CodexBar ships a new field, the widget no longer throws it away before anyone can see it.

**For the developer:** this repository gains its first ground-truth artifact of the external contract it depends on. Every prior change to `UsageModel.js` was made against hand-authored inline object literals invented in this repo. A redacted real capture turns "what does the CLI return?" from an unanswerable question into a file you can open. The `raw` passthrough additionally means future CodexBar schema changes surface as *available but unused* data rather than as silent loss requiring a normalization rewrite.

## Capabilities

### New Capabilities

- **Verbatim CLI passthrough**: the normalized snapshot exposes, per provider, the unmodified original CLI entry under a `raw` key, so consumers can read fields the normalizer does not model. No consumer uses it yet.
- **Documented contract capture procedure**: a repeatable, privacy-safe way to refresh the contract fixture when the installed CodexBar version changes.

### Modified Capabilities

- `provider-usage-display` — the "Provider-focused exclusions" requirement (`openspec/specs/provider-usage-display/spec.md:325-332`) currently reads "The plasmoid MUST NOT add cost, credits, tokens, ...". This is tightened from a blanket prohibition to a **presentation-and-derivation** prohibition: the plasmoid MUST NOT compute, request, fabricate, or display cost/credit/token data, but it MAY preserve CLI-supplied fields verbatim in the normalized snapshot without rendering them. The scenario "Missing commercial or reset data" (nothing is fabricated or requested) remains true and unchanged.
- `provider-usage-display` — the "Provider presentation" requirement gains a stability guarantee: the four-key contract MUST remain shape-stable while additive siblings are permitted.

## Approach

Adopt exploration's Approach 3 (hybrid verbatim `raw` sibling), in two ordered steps.

**Step A — Phase 0, evidence.** Ship `docs/cli-contract-capture.md` describing the exact capture and redaction procedure (below). The user runs it and supplies the redacted output. This gates Step B: the fixture's *contents* cannot be authored without it, and inventing them would defeat the entire purpose of Phase 0.

**Step B — Phase 1, mechanism.** Add one key to `normalizeProvider`'s return value:

```
return {
    provider: rawValue(entry, "provider"),
    source: rawValue(entry, "source"),
    windows: windows,
    raw: <the original entry, verbatim>
}
```

The mechanism is fully designable now precisely *because* it does not need to know any field names in advance — that is the property being bought. Only the fixture's literal contents depend on the real capture.

`normalizeWindow` is not touched. `normalize()`'s error branch is not touched. `UsageController.qml` is not touched: `handleCommand` already passes the parsed payload into `UsageModel.normalize()` and reads only `normalized.providers` / `normalized.errors`, so the new key rides along with zero controller change.

### Capture and Redaction Procedure (design)

The user runs, on their own machine:

```sh
CODEXBAR_PATH="$(command -v codexbar)"
"$CODEXBAR_PATH" usage --provider all --format json --json-only \
  | python3 -m json.tool > /tmp/codexbar-real-capture.json
```

The user then redacts `/tmp/codexbar-real-capture.json` **in place**, under one rule:

> Replace sensitive leaf **values** only. Never remove, rename, or reorder a key. Never change a type: strings stay strings, numbers stay numbers, arrays stay arrays, objects stay objects, `null` stays `null`, and nesting depth is preserved exactly.

| Field class | Action |
|---|---|
| `identity.accountEmail` | Replace with `"redacted@example.com"` |
| `identity.accountOrganization` | Replace with `"Redacted Org"` |
| `identity.providerID`, `loginMethod` | Replace only if account-identifying; keep the key and type |
| `credits.remaining`, any cost/balance figure | Replace with a same-magnitude placeholder number (e.g. round to a fixed value) |
| Any token, key, session ID, or URL containing one | Replace with a same-length placeholder string |
| `provider`, `source`, `version`, `status`, `primary`/`secondary`/`tertiary`, `usedPercent`, `resetsAt`, `resetDescription`, `windowMinutes`, `pace.*`, `usage.details[*]` structural keys | **Leave untouched** — these are exactly what this change needs to observe |

**Multi-provider coverage is required when available.** Upstream ships provider-specific extras that differ by provider (Codex carries `antigravityPlanInfo` / `openaiDashboard`; Claude carries different account metadata). If the user has more than one provider configured, the capture must include at least two distinct provider types, or the fixture under-represents the real contract.

The redacted file is committed as `tests/fixtures/codexbar-usage-capture.json`, with `docs/cli-contract-capture.md` recording the CodexBar version it came from, the capture date, and which fields were redacted. Because no CI QML runtime exists (`openspec/config.yaml`, README.md:184), drift detection against future CodexBar releases is a **manual re-capture cadence**, not automation — the doc states this explicitly rather than implying the fixture self-maintains.

### On the existing "unknown keys are dropped" tests

`tests/UsageModelTest.qml:65-81` (`test_ignoresExtraAndNonFiniteUsageValues`) and `tests/UsageModelHarness.qml:26,38` assert that an unrecognized *window* key (`extraRateWindow`, `ignored`) does not become a window and that exactly the recognized windows are retained. **That intent is fully preserved and those tests are not edited.** Their purpose is to stop unknown or malformed data from corrupting the stable `windows` array — and the stable `windows` array is not where `raw` lives. `raw` is a provider-level sibling. Robustness of the four-key contract against extra and non-finite values is unchanged in every respect.

### Alternatives Considered

| Alternative | Why not chosen |
|---|---|
| **Typed field promotion** — explicitly recognize and copy named fields (`windowMinutes`, `pace.*`, `credits`, `identity`) into the normalized objects with `finiteNumber`-style coercion. | Type-safe and self-documenting, but upstream CodexBar's own docs record that its JSON already underwent one breaking change (provider-specific usage keys removed in favor of a generic `usage.details` array; legacy keys such as `openRouterUsage` are explicitly unsupported). Hardcoding field names now bets on a schema that has already proven unstable, and would need redoing the moment the user's installed CLI differs. Also requires naming fields before any UI consumer exists to say which ones matter. **Deferred, not rejected** — this becomes a narrow follow-up change once real data and a Phase 2 UI consumer both exist. |
| **Generic passthrough bucket with no typed layer ever** — one loose `raw`/`extra` key and an explicit decision never to promote anything. | Same resilience as the chosen approach, but forecloses typed promotion as a matter of policy. There is no evidence yet that typed promotion is wrong; there is only evidence it is premature. Choosing "never" is a stronger claim than the data supports. |
| **Capture-only (Phase 0 alone), defer all normalization** | Smaller, but leaves the roadmap's stated blocker in place: normalization still discards the data, so Phase 2 UI work would be blocked on a second change anyway. The `raw` mechanism costs one key and no new field-name commitments, so splitting here buys nothing. |
| **Fabricate a fixture from upstream documentation instead of capturing** | Rejected outright. Upstream docs describe a schema that has already changed once and may not match the user's installed build. A fixture invented from docs is a guess presented as evidence, which is the exact failure Phase 0 exists to prevent. |

## README Reconciliation

`README.md:120-122` currently reads:

> ## MVP exclusions
>
> KodexBar Plasma deliberately does not implement cost data, credits, tokens, calculated reset durations, charts, provider or source switching, authentication or cookie automation, provider implementations, fallback probing, or reset/account actions. Use CodexBar and provider tools for those responsibilities.

The roadmap (Engram `architecture/product-roadmap`, `architecture/parity-roadmap`) supersedes the MVP-era blanket exclusion of cost/credits/tokens *data*. The heading and anchor stay stable; the body is revised during apply to:

> ## MVP exclusions
>
> KodexBar Plasma deliberately does not implement provider implementations, authentication or cookie automation, fallback probing, reset or account actions, provider or source switching, calculated reset durations, or charts. Use CodexBar and provider tools for those responsibilities.
>
> Cost, credit, token, pace, and other richer per-provider values are never computed, estimated, or requested by this widget. When the CodexBar CLI itself returns such fields, the data layer preserves them verbatim under a per-provider `raw` key so later phases can build on real data — **the popup does not display them today**. Surfacing them in the UI is planned roadmap work, not current behavior.

This is deliberately narrow. It moves the README from "we do not have this data" to "this data is captured but not surfaced", and it does not claim any UI capability this change does not deliver. The parallel spec requirement at `openspec/specs/provider-usage-display/spec.md:327` receives the equivalent MODIFIED delta during the spec phase.

## Affected Areas

| Area | Impact | Description |
|---|---|---|
| `contents/code/UsageModel.js:49-53` | Modified | One additive `raw` key on `normalizeProvider`'s return value. `normalizeWindow`, `normalize`, and every selector function unchanged. |
| `docs/cli-contract-capture.md` | New | Capture command, redaction rule and table, provenance record, manual re-capture cadence. |
| `tests/fixtures/codexbar-usage-capture.json` | New | Redacted real capture. Contents gated on user-supplied evidence. |
| `tests/UsageModelTest.qml` | Modified | New RED-first assertions for `raw` presence/verbatimness and four-key stability. Existing tests unedited. |
| `tests/UsageModelHarness.qml` | Unchanged | Existing window-count assertions remain valid as-is. |
| `README.md:120-122` | Modified | Revised exclusions prose per the block above. |
| `openspec/specs/provider-usage-display/spec.md:325-332` | Delta | "Provider-focused exclusions" narrowed from blanket prohibition to presentation-and-derivation prohibition. |
| `contents/ui/UsageController.qml` | Unchanged | Read-only reference. `handleCommand` needs no change; the new key rides through untouched. |
| `contents/ui/ProviderSelector.qml`, `ProviderRow.qml`, `UsageWindowRow.qml` | Unchanged | No UI consumes `raw` in this change. |
| `openspec/changes/persistent-datasource-lifecycle/` | Untouched | Unrelated stray directory; flagged for separate cleanup. |

## Acceptance Criteria

Scenario sketches for the spec phase (Given/When/Then, RFC 2119, per `openspec/config.yaml` spec rules):

1. **Stable contract is not regressed** — GIVEN any payload already covered by an existing `UsageModelTest` scenario, WHEN it is normalized, THEN `provider`, `source`, and every `windows[]` entry's `key`, `label`, `usedPercent`, `resetsAt`, and `resetDescription` MUST equal their current values exactly.
2. **Verbatim passthrough of unmodeled fields** — GIVEN a provider entry carrying top-level keys the normalizer does not model (e.g. `version`, `status`, `identity`, `credits`, `pace`), WHEN it is normalized, THEN the result MUST expose those keys unmodified under `raw`, AND `windows` MUST NOT gain an entry for any of them.
3. **Window-level dropping is unchanged** — GIVEN a `usage` object containing an unrecognized window key, WHEN it is normalized, THEN `windows` MUST contain only recognized windows, exactly as today.
4. **Error entries are unaffected** — GIVEN an entry with a non-null `error`, WHEN it is normalized, THEN it MUST still be routed to `errors` with `{provider, source, error}` and MUST NOT appear in `providers`.
5. **Real capture is real** — GIVEN the committed contract fixture, WHEN it is inspected, THEN it MUST originate from a documented run of the real CLI on the user's machine, MUST record its CodexBar version and capture date, and MUST NOT contain fabricated fields. Verification of provenance is a documented manual step, since no CI runtime can prove it.
6. **Redaction preserves shape** — GIVEN the committed fixture and the redaction rule, WHEN it is normalized, THEN every key and type present in the original capture MUST still be present, with only sensitive leaf values substituted.

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| **No real payload exists yet**, so the fixture's contents cannot be authored during propose or design. | High (certain) | Explicit gate: apply STOPS and requests the user's capture before authoring the fixture. Nothing about the `raw` *mechanism* depends on it, so the change is not blocked end-to-end — only its evidence artifact is. |
| **Upstream schema instability** — CodexBar's JSON already had one documented breaking change. | High | This is the primary reason `raw` is verbatim passthrough rather than typed promotion: no field name is hardcoded, so a schema change degrades to "different contents under `raw`" instead of a normalization rewrite. |
| **PII and cost exposure** — a real capture plausibly contains account email, organization name, and credit balances, and it lands in a public git history permanently. | High | Redaction rule and field table are part of the shipped doc, not tribal knowledge. Apply MUST diff the redacted fixture against the redaction table before commit. A leaked value cannot be un-committed cheaply, so this is a hard gate, not a checklist item. |
| **Fixture goes stale** as the user upgrades CodexBar, with no CI to notice. | Med | The doc records provenance (version + date) and states a manual re-capture cadence explicitly. This is acknowledged as an unsolved process risk, not claimed as solved. |
| **`raw` is misread as a UI feature**, or as license to display cost data. | Med | README and spec prose both state "preserved, not displayed" explicitly. No UI component reads `raw` in this change, and adding one is listed as out of scope. |
| **`raw` holds a live reference to the parsed payload**, so a future mutating consumer could corrupt the snapshot. | Low | Design phase decides reference-vs-copy explicitly; snapshots are currently treated as immutable by all consumers, and no consumer reads `raw` yet. |
| **Existing tests appear contradicted** by "we now keep unknown data" while `test_ignoresExtraAndNonFiniteUsageValues` says the opposite. | Low | Distinct levels: window-level dropping (unchanged) vs provider-level passthrough (new). Stated in the approach, and both behaviors are asserted side by side in the test suite. |
| **Spec delta looks like a scope reversal** on a previously agreed exclusion. | Low | The delta narrows *derivation and display* prohibitions while keeping them intact, and preserves the existing "nothing is fabricated or requested" scenario verbatim. |

## Rollback Plan

Revert as one work unit: the `raw` key on `normalizeProvider`, the new tests, the fixture, the capture doc, the README paragraph, and the spec delta. Because `raw` is purely additive and no consumer reads it, removing it restores the previous normalized snapshot exactly — no migration, no persisted state, no user configuration, and no external CLI behavior is involved. If the fixture is later found to contain an unredacted value, rollback is *not* sufficient: the fixture must be purged from history, which is why redaction is gated pre-commit.

## Dependencies

- **The user's own machine and configured CodexBar install.** This change cannot complete without a real capture the user runs and redacts; `codexbar` is not vendored here and cannot be introspected offline.
- Plasma 6 / Kirigami runtime with the existing `./scripts/run-qml-tests.sh` and `./scripts/lint-qml.sh` gates (Qt 6.11.1).
- `python3` for the capture pipeline's pretty-printing step (already used in README.md:58's verification snippet).

## Success Criteria

- [ ] `docs/cli-contract-capture.md` exists and documents the capture command, the redaction rule, the field-class table, provenance fields, and the manual re-capture cadence.
- [ ] A redacted real capture is committed under `tests/fixtures/`, sourced from the user's actual CLI, covering at least two provider types when the user has more than one configured.
- [ ] The committed fixture contains no account email, organization name, real credit balance, token, or key; every original key and type survives redaction.
- [ ] `normalizeProvider` returns `raw` verbatim alongside `provider`, `source`, and `windows`.
- [ ] `normalizeWindow` is byte-unchanged; `tests/UsageModelHarness.qml` is byte-unchanged; `test_ignoresExtraAndNonFiniteUsageValues` is byte-unchanged and passing.
- [ ] New RED-first tests assert `raw` presence and verbatimness, and assert the four-key contract's values are unchanged for existing fixtures.
- [ ] No UI file, no `contents/ui/UsageController.qml` line, and no `contents/config/` file is modified.
- [ ] `commandLine()` still returns exactly `usage --provider all --format json --json-only`.
- [ ] `README.md`'s exclusions paragraph reads as drafted above: no cost/credit/token value is computed, estimated, or requested, data is preserved verbatim, and the UI does not display it.
- [ ] The `provider-usage-display` spec delta narrows "Provider-focused exclusions" without weakening the "nothing is fabricated or requested" guarantee.
- [ ] `./scripts/run-qml-tests.sh`, `./scripts/lint-qml.sh`, and `git diff --check` pass.
- [ ] The change stays within the 400-line review budget; if not, `ask-on-risk` applies and the capture/doc slice is split from the normalization slice.
