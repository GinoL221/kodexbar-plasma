## Exploration: CLI Contract Fixtures & Enrichment-Ready Normalization

### Current State

**The exact CLI boundary** (unchanged, must stay unchanged): `contents/ui/UsageController.qml:38` builds `commandLine()` as `PathResolver.shellQuote(effectiveCommandPath) + " usage --provider all --format json --json-only"`. README.md:11 states "The CLI is the boundary" and README.md:122 lists MVP exclusions (see Risk below).

**Normalization gap, cited exactly:**
- `contents/code/UsageModel.js:21-33` (`normalizeWindow`) accepts a per-window object and returns only `{ key, label, usedPercent, resetsAt, resetDescription }` — any other key on that window object (e.g. upstream's `windowMinutes`, `pace`) is read but never copied into the return value, so it is silently dropped.
- `contents/code/UsageModel.js:35-54` (`normalizeProvider`) returns only `{ provider, source, windows }` from `entry` — any other top-level key on a provider entry (e.g. upstream's `version`, `status`, `identity`, `credits`, `usage.details`) is never read at all.
- `contents/ui/UsageController.qml:219-252` (`handleCommand`) does `payload = JSON.parse(stdout)` (line 237) then `UsageModel.normalize(payload)` (line 243) directly — nothing raw is captured, logged, or held before normalization discards fields. There is no intermediate "raw payload" value anywhere in the controller.
- Grepped `contents/code/UsageModel.js` for `version|status|windowMinutes` — zero matches. Confirms none of these upstream-documented fields are handled anywhere today, not even read-and-ignored explicitly; they simply never appear in the code.

**This gap is intentionally tested, not accidental:** `tests/UsageModelTest.qml:65-81` (`test_ignoresExtraAndNonFiniteUsageValues`) explicitly asserts that an unrecognized per-window key (`extraRateWindow`) is dropped and does not appear in `windows`. `tests/UsageModelHarness.qml:26,38` also asserts an `ignored: { usedPercent: 99 }` window key produces exactly 2 (not 3) retained windows. Any enrichment work must decide explicitly whether/how to touch this guarantee (see Open Questions).

**No real captured payload exists anywhere in this repo.** The only fixture, `tests/fixtures/codexbar-lifecycle-fixture.sh:15`, emits one hand-authored synthetic line: `[{"provider":"fixture","usage":{"primary":{"usedPercent":42}}}]` — invented, single-field, not representative of real CLI output. `tests/UsageModelTest.qml` and `tests/UsageModelHarness.qml` fixtures are likewise hand-authored inline JS object literals, not captured payloads.

**No CLI JSON schema documentation exists in this repo.** README.md documents only the invocation itself (line 38, line 58's verification snippet `"$CODEXBAR_PATH" usage --provider all --format json --json-only | python3 -m json.tool`, which pretty-prints but does not persist output anywhere) and the "How it works" summary (README.md:207-213). No `docs/cli-contract.md` or equivalent exists.

**`codexbar` itself is not vendored or embedded in this repo.** Per README.md:27-67: it's an external binary the user installs separately (`brew install steipete/tap/codexbar` or a Linux tarball from CodexBar releases), discovered only at `$HOME/.local/bin/codexbar`, `/usr/local/bin/codexbar`, `/usr/bin/codexbar`, or `$HOMEBREW_PREFIX/bin/codexbar`. No man page, no local copy of its docs, nothing to introspect offline in this repo — grounding the requirement that Phase 0 evidence-gathering can only come from the user's own machine.

**External grounding (upstream CodexBar repo docs, NOT a substitute for a real local capture):** `docs/cli.md` in `steipete/CodexBar` documents a JSON shape with `provider`, `version`, `source`, `status`, usage windows (`primary`/`secondary`/`tertiary` with `usedPercent`, `windowMinutes`, `resetsAt`), a `pace` object (`stage`, `deltaPercent`, `expectedUsedPercent`, `willLastToReset`, `etaSeconds`, `summary`), `identity` (`providerID`, `accountEmail`, `accountOrganization`, `loginMethod`), `credits` (`remaining`, `updatedAt`), and provider-specific extras (Codex: `antigravityPlanInfo`, `openaiDashboard`; Claude: account metadata). Critically, upstream documentation itself notes a **breaking JSON change**: provider-specific usage payload keys were removed from `codexbar usage --format json` in favor of a generic `usage.details` array, and legacy keys like `openRouterUsage` are explicitly unsupported now. This means the upstream contract is actively unstable, which is direct evidence for why a real local capture (not upstream docs, and not invented data) is required, and why any new normalized fields should be defensive against schema drift rather than hardcoded to one snapshot of upstream's docs.

**Housekeeping note, explicitly out of scope for this change:** `openspec/changes/persistent-datasource-lifecycle/` exists un-archived alongside two properly dated-archived lifecycle changes (`archive/2026-08-09-persistent-datasource-lifecycle-closeout/`, `archive/2026-08-11-persistent-datasource-lifecycle-remediation/`). It contains `exploration.md`, `proposal.md`, `design.md`, `tasks.md`, `apply-progress.md`, `verify-report.md`, and a live `specs/provider-usage-display/spec.md`. This looks like dead/leftover state and should be flagged to the user/orchestrator for separate cleanup — do not touch it in this change.

### Affected Areas
- `contents/code/UsageModel.js:21-54` — `normalizeWindow`/`normalizeProvider` must gain additive enrichment without changing the existing four return keys' behavior (`provider`, `source`, `windows[].{key,label,usedPercent,resetsAt,resetDescription}`).
- `contents/ui/UsageController.qml:219-252` (`handleCommand`) — only affected if a raw/pre-normalization payload needs to be captured; currently `payload` is a local var, never exposed.
- `tests/UsageModelTest.qml`, `tests/UsageModelHarness.qml` — existing regression coverage for "extra keys are dropped"; new tests must be added per `strict_tdd: true` (`openspec/config.yaml:10`) without silently breaking these.
- `tests/fixtures/codexbar-lifecycle-fixture.sh` — the only existing fixture pattern to follow/extend for any new fixture; single hand-authored line today.
- `README.md:120-122` ("MVP exclusions") and `README.md:114-118` ("The popup renders supported CLI fields") — both describe current UI/data scope and are in tension with the roadmap's Phase 1 intent (see Risks).
- `openspec/specs/provider-usage-display/spec.md` — current stable-contract spec; any new requirement/scenario for enriched normalization belongs here in the design/spec phase, not this exploration.
- New artifact needed (location to be decided in propose): a redacted-but-structurally-real captured fixture, and a short doc describing how it was captured/redacted.

### Evidence-Gathering Required From the User (Phase 0)

This cannot be fabricated. The user must run their own configured, real `codexbar` CLI and share the result. Proposed exact step:

```sh
CODEXBAR_PATH="$(command -v codexbar)"
"$CODEXBAR_PATH" usage --provider all --format json --json-only | python3 -m json.tool > /tmp/codexbar-real-capture.json
```

Then the user reviews `/tmp/codexbar-real-capture.json` and redacts, in place, only sensitive leaf **values** while preserving every key and the JSON shape/types (arrays stay arrays, objects stay objects, numbers stay numbers) — for example:
- Replace `accountEmail`/`accountOrganization` string values with placeholders like `"redacted@example.com"` / `"Redacted Org"`.
- Replace `credits.remaining` or any cost figures with a placeholder number that preserves magnitude order but isn't the real balance (e.g. round to a fixed number).
- Leave `provider`, `source`, `version`, `status`, window keys (`primary`/`secondary`/`tertiary`), `usedPercent`, `resetsAt`, `windowMinutes`, `pace.*`, and any `usage.details` structural keys untouched — these are exactly what this change needs to see.
- If the user runs multiple configured providers (e.g. Codex + Claude + OpenRouter), share one real object per distinct provider type, since provider-specific extras (`antigravityPlanInfo`, `openaiDashboard`, etc., per upstream docs) differ by provider and a single-provider capture would under-represent the real contract.

The shared file (or its structure) becomes the actual Phase-0 deliverable; this exploration cannot substitute a synthetic guess for it without defeating the entire purpose of Phase 0.

### Approaches (for Phase 1 — how to shape the enriched-but-backward-compatible normalized snapshot)

1. **Typed field promotion** — extend `normalizeWindow`/`normalizeProvider` to explicitly recognize and copy specific new fields (e.g. `windowMinutes`, a `pace` sub-object with fixed keys, `credits`, `identity`) into the existing `provider`/`window` objects as new named properties, validated/coerced the same way `usedPercent` is today (`finiteNumber`-style guards).
   - Pros: Type-safe, self-documenting, easy to spec with Given/When/Then scenarios; UI consumers (Phase 2+) get a predictable shape with no defensive `typeof` checks.
   - Cons: Upstream's own docs confirm the schema already had one breaking change (provider-specific keys → generic `usage.details`); hardcoding field names now risks staleness the moment the local CLI version differs from what the user captures today, or upstream changes again. Requires re-doing this work if/when the contract shifts.
   - Effort: Medium — mechanical extension of `normalizeWindow`/`normalizeProvider` plus new fixtures/tests per new field.

2. **Generic passthrough bucket** — add one new key (e.g. `raw` or `extra`) at the provider level (and optionally window level) that holds the corresponding original sub-object verbatim (or lightly filtered to drop only truly unsafe fields), with no fixed schema enforced by `UsageModel.js`.
   - Pros: Fully resilient to upstream schema drift — exactly the property the evidence above says matters most; no repeated normalization-code churn as CodexBar's JSON evolves; still 100% additive to the existing stable four-key contract.
   - Cons: No validation/type coercion at all — consumers (Phase 2 UI, or tests) must defensively handle missing/malformed nested data themselves; less self-documenting; "generic bucket" style is not yet an established pattern anywhere else in this codebase (harder to review against precedent).
   - Effort: Low-Medium — one new key added to `normalizeProvider`'s return value, but the redaction/safety story becomes more important since nothing is filtered by design.

3. **Hybrid — verbatim `raw` sibling plus later, separately-scoped typed promotion**: keep `windows` exactly as-is today; add one new top-level `raw` property per provider entry in `normalizeProvider`'s return value holding the original `entry` object (or a redacted copy) untouched; do NOT touch `normalizeWindow`'s fixed three-field window shape at all in this change. Defer deciding which specific typed fields (pace, credits, etc.) get promoted to first-class normalized properties to a later, narrower change once real data is confirmed and a UI consumer (Phase 2+) actually needs them.
   - Pros: Smallest, lowest-risk diff that still satisfies "preserve rich data" — nothing is lost, nothing existing changes shape, `test_ignoresExtraAndNonFiniteUsageValues` and the harness assertion about window count stay valid untouched (they test window-level dropping, not a new provider-level sibling key). Directly matches this change's own stated constraint ("this change is DATA layer only... don't scope-creep into UI work") by not committing to a UI-facing typed shape prematurely.
   - Cons: Defers the harder design decision (which fields are "first-class") rather than resolving it now; `raw` still needs the same redaction-before-commit care as approach 2 if any of it lands in a fixture; two-step roadmap work (this change, then a follow-up promotion change) adds process overhead versus doing it once.
   - Effort: Low — one additive key on `normalizeProvider`'s output, one new fixture, new tests asserting `raw` is present/backward-compatible and existing keys/tests are untouched.

### Recommendation

Approach 3 (hybrid, verbatim `raw` sibling), with the field-promotion question (approach 1) explicitly deferred to a follow-up change once (a) a real capture is in hand and (b) product/roadmap decides how to reconcile the README's stated MVP exclusions with using this data anywhere. This is the lowest-risk way to satisfy "preserve rich data... without breaking the current stable contract" while genuinely staying data-layer-only as instructed, and it is the most defensive choice against the already-demonstrated upstream schema instability. It does not preclude promoting specific fields later — it only avoids committing to specific field names before real data and a UI plan both exist.

### Open Questions for sdd-propose

1. **Redaction mechanics**: should propose ship a small redaction script/checklist (see Evidence-Gathering above), or is manual user redaction sufficient/preferred? Where does the redacted fixture live — a new `tests/fixtures/codexbar-real-capture*.json`, or `docs/`?
2. **MVP exclusions conflict**: README.md:120-122 explicitly states KodexBar Plasma "deliberately does not implement cost data, credits, tokens... provider implementations... fallback probing." This change stores (not renders) cost/credits/pace-adjacent data at the data layer only. Does propose need to amend/qualify that README statement now (e.g. "the data layer preserves raw CLI fields for future phases; the UI does not render cost/credit data"), or is that deferred to the Phase 2 UI change that actually surfaces it? This should not be silently left unresolved — it's a documented product decision the roadmap's Phase 1 intent runs directly into.
3. **Approach selection**: confirm approach 3 (verbatim `raw` sibling) versus 1 (typed promotion) versus 2 (generic bucket with no typed layer at all) — or an explicit hybrid combining 2+3.
4. **Existing test intent**: should `tests/UsageModelTest.qml:65-81` (`test_ignoresExtraAndNonFiniteUsageValues`) and `tests/UsageModelHarness.qml:26,38` remain completely unchanged (since they test window-level key dropping, which approach 3 does not touch), or does propose want to also relax window-level dropping as part of this change? Recommendation leans toward "leave unchanged" — flag as explicit confirmation needed.
5. **Multi-provider coverage**: should the user's real capture cover more than one configured provider type (e.g. Codex + Claude) given upstream docs show provider-specific extras differ (`antigravityPlanInfo` vs Claude account metadata)? Recommendation: yes, at least two if the user has more than one configured, to avoid under-scoping the "richer per-provider metadata" goal.
6. **Schema drift handling**: given upstream's own documented breaking change (provider keys → generic `usage.details`), should normalization treat both old- and new-style upstream shapes defensively, or trust that the real local capture reflects the user's currently-installed CLI version only (accepting staleness risk on future CLI upgrades)?

### Risks

- **Fabrication risk**: without a real user-provided capture, any concrete field-name decision in propose/design would be guesswork dressed as fact — this must not happen; Phase 0's entire purpose is defeated if skipped.
- **Upstream schema instability**: `steipete/CodexBar` docs confirm at least one breaking JSON change already shipped (provider-specific keys removed in favor of generic `usage.details`); hardcoding specific new field names (approach 1) risks going stale quickly. Approach 3's verbatim-passthrough posture is a direct mitigation.
- **PII/cost exposure**: a real captured payload plausibly contains account email, organization name, and cost/credit balances — must never be committed unredacted; redaction approach must preserve structural shape (keys, types, nesting) so it remains a faithful contract fixture, not just safe.
- **Documented product-decision conflict**: README.md's "MVP exclusions" statement (cost data, credits, tokens explicitly excluded) needs explicit reconciliation with this change's data-preservation goal before or during propose — silently ignoring this creates a doc/behavior mismatch even though this change touches no UI.
- **Existing regression-test tension**: `test_ignoresExtraAndNonFiniteUsageValues` and the harness's `ignored` key assertion codify "drop the unknown" as intended behavior today; whichever approach is chosen must state explicitly whether/why that guarantee still holds after this change.
- **Unrelated housekeeping**: the stray un-archived `openspec/changes/persistent-datasource-lifecycle/` directory should be flagged to the user/orchestrator separately; it is not part of this change's scope and should not be touched here.
- **No CI QML runtime** (`openspec/config.yaml:27` / README.md:184): schema-drift detection over time depends on manual periodic re-capture by the user, not automation; propose/design should note a revisit cadence or at least acknowledge this is a manual-process risk, not a solved one.

### Ready for Proposal
Yes, but gated: sdd-propose should NOT lock in specific new field names or a final normalized shape until the user supplies at least one real (redacted-as-needed) `codexbar usage --provider all --format json --json-only` capture per the Evidence-Gathering section above. Propose CAN proceed now on: the redaction/fixture-storage convention, the approach-3-hybrid decision (pending confirmation), and reconciling the README MVP-exclusions statement — none of which require the real payload in hand yet, only the field-shape specifics do.
