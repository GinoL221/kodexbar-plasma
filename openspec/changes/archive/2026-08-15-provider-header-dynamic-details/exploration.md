## Exploration: Provider Header & Dynamic Detail UI (Phase 2)

### Current State

**Architecture boundary (preserved, must stay preserved):** `CodexBar CLI` → `UsageController.qml` (independent, provider-neutral) → `UsageModel.js` (normalized snapshots) → `Plasma/Kirigami UI` (`ProviderSelector.qml`, `ProviderRow.qml`, `UsageWindowRow.qml`, `CompactUsageButton.qml`). UI must never reimplement providers, authentication, or fetching.

**Data availability (Phase 1 complete):** `contents/code/UsageModel.js:51-56` (`normalizeProvider`) now returns `{ provider, source, windows, raw }` where `raw` is a verbatim live reference to the parsed CLI entry. No field is promoted to a first-class normalized property. Window-level dropping in `normalizeWindow` (lines 21-33) is unchanged: `windows[]` still exposes only `{ key, label, usedPercent, resetsAt, resetDescription }`.

**What `raw` contains (evidence, not guesses):** `tests/fixtures/codexbar-usage-capture.json` (real CLI capture, redacted) shows rich per-provider fields the UI does not yet consume:
- `pace.{primary,secondary,tertiary}.{stage, deltaPercent, expectedUsedPercent, willLastToReset, etaSeconds, summary}` — projections and pace stage
- `credits.{remaining, updatedAt, events[]}` — balance history
- `usage.identity.{providerID, accountEmail, accountOrganization, loginMethod}` — account metadata
- `usage.details[]` — dynamic detail arrays (e.g. Copilot "Credits" rows)
- `usage.loginMethod`, `usage.codexResetCredits`, `usage.providerCost`, `usage.dataConfidence`, `usage.windowMinutes`
- `version`, `source` at provider level
- Provider-specific extras (Codex: `antigravityPlanInfo`; Grok: `accountOrganization`)

**Current UI surface (what renders today):**
- `ProviderRow.qml:55-91` renders provider icon, name (`provider`), source (`source`), then a `Repeater` over `displayedWindows`.
- `UsageWindowRow.qml:52-126` renders per-window: label, progress bar (if `usedPercent` is finite), percentage, resetsAt, resetDescription.
- `ProviderSelector.qml:184-242` is a `TabBar` with "All" + one tab per usable provider; each tab shows `provider + " · " + source`.
- `main.qml:62-142` is the popup layout: refresh button, loading/error labels, `ProviderSelector`, provider rows, error summary.
- No component reads `raw` anywhere. No dynamic details, no identity, no version, no pace, no credits.

**Test harness conventions:** Strict TDD (`openspec/config.yaml:10`). QML harnesses under `tests/` are executable, offscreen, QtTest-based. `UsageModelTest.qml` and `UsageModelHarness.qml` assert the four-key contract; `UsageControllerFixture.qml` asserts controller stage/datasource lifecycle. No CI QML runtime — tests run locally via `./scripts/run-qml-tests.sh`. Lint via `./scripts/lint-qml.sh` (qmllint 6.11.1).

**Roadmap context (Engram #4725):** Phase 0 (verify real CLI contract) and Phase 1 (preserve rich data in normalization) are archived (`cli-contract-fixtures`). This exploration is Phase 2: provider header and dynamic detail UI. Phases 3+ (authoritative pace/projection, credits/commercial details, cost/token pipeline, status/actions, preferences, icon, onboarding, release maturity) are explicitly out of scope.

**Plasma/Kirigami conventions (skill `plasma-kirigami-ui`):** Native Plasma 6 components only (`org.kde.plasma.components`, `QtQuick.Controls`, `Kirigami.*`). Use `Kirigami.Units`, `Kirigami.Theme`, `Kirigami.Separator`, `Kirigami.Icon`. Preserve keyboard navigation, accessible labels (`Accessible.name`, `Accessible.description`), theme adaptation, compact panel sizing. No web-generic patterns (HTML/CSS/JS layouts, emoji icons, browser metaphors).

### Affected Areas

- `contents/ui/ProviderRow.qml` — primary candidate for header enrichment (version, identity, loginMethod) and dynamic detail expansion.
- `contents/ui/UsageWindowRow.qml` — may gain supplementary detail rows if `usage.details[]` is surfaced.
- `contents/ui/ProviderSelector.qml` — tab labels could show version or loginMethod; may need layout adjustment if header grows.
- `contents/ui/main.qml` — popup layout may need scrolling/height adjustments if provider rows expand.
- `contents/code/UsageModel.js` — **NOT modified.** Normalization stays as-is; UI reads `raw` defensively.
- `contents/ui/UsageController.qml` — **NOT modified.** Controller stays provider-neutral.
- `tests/UsageModelTest.qml`, `tests/UsageModelHarness.qml` — **NOT modified.** Four-key contract tests unchanged.
- New test files likely: harness(es) asserting UI reads `raw` defensively, does not crash on missing fields, and renders expected header/detail content.
- `openspec/specs/provider-usage-display/spec.md` — will receive delta scenarios for header/detail rendering.
- `README.md` — MVP exclusions paragraph may need clarification that header/details display CLI-supplied data but do not compute pace/credits/cost.

### Approaches

1. **Minimal header enrichment only** — add `version` and `usage.identity.loginMethod` to `ProviderRow.qml` header (next to provider name/source). No dynamic details, no expandable sections. Show identity only if present in `raw`.
   - Pros: Smallest diff (~100-150 lines), lowest review risk, clear boundary ("header shows identity, nothing else"), no layout disruption.
   - Cons: Does not surface `usage.details[]` (Copilot credits, provider-specific extras) or `pace` inputs (though pace is Phase 3). May feel incomplete if users expect to see more.
   - Effort: Low.

2. **Header enrichment + expandable dynamic details** — enrich header as in Approach 1, plus add an expandable `Kirigami.ExpansionPanel` or custom collapsible section in `ProviderRow.qml` that iterates `raw.usage.details[]` (if present) and renders each detail's `title` and `rows[]` as label/value pairs. Defensive: if `details` is missing/malformed, section is hidden.
   - Pros: Surfaces Copilot's "Credits used" rows and similar provider-specific detail arrays without interpreting them (no computation, just display). Demonstrates the value of `raw` passthrough. Still under 400 lines if scoped tightly.
   - Cons: More layout complexity (expandable sections in a popup). Requires careful accessible labeling. Risk of scope creep into "interpret details" if not disciplined.
   - Effort: Medium.

3. **Full raw passthrough UI** — expose all `raw` fields (pace, credits, identity, version, details, provider-specific extras) with defensive rendering. Each field gets its own row/section. Pace is shown as raw values (not interpreted as projections). Credits shown as raw numbers (not labeled as "remaining balance"). 
   - Pros: Maximum information density. Demonstrates the full value of Phase 1's `raw` passthrough.
   - Cons: High risk of crossing into Phase 3/4 territory (pace projection interpretation, credits meaning). Layout complexity explodes. Review budget likely exceeded. Difficult to test exhaustively. Risk of web-generic dashboard patterns creeping in.
   - Effort: High.

### Recommendation

**Approach 2 (header enrichment + expandable dynamic details)**, with explicit scope guards:
- Header shows: provider name, source, version (if present), loginMethod (if present in `raw.usage.identity`).
- Dynamic details section: iterates `raw.usage.details[]` (if array, if non-empty), renders each detail's `title` and `rows[].{label, value, secondaryValue}` verbatim. No computation, no interpretation, no projection.
- Pace, credits, cost, token data are **NOT displayed** (Phase 3/4). They are available in `raw` but the UI does not render them in this change.
- Defensive rendering: all `raw` access is guarded (`raw && raw.usage && raw.usage.details instanceof Array`), missing fields hide their sections, malformed data does not crash.
- Test coverage: new harness(es) assert header renders version/loginMethod when present, details section iterates correctly, missing/malformed `raw` fields do not break rendering, four-key contract is unchanged.

**Rationale:** This approach surfaces the most immediate value of Phase 1's `raw` passthrough (identity, version, dynamic details) without crossing into Phase 3/4 (pace projection, credits interpretation). It stays under 400 lines, respects the architectural boundary (UI reads `raw` defensively, does not compute), and follows Plasma/Kirigami native patterns. It also answers the product question "what can we show now?" without premature commitment to pace/credits logic.

### Risks

- **Scope creep into pace/credits:** `raw` contains pace projections and credit balances. If the UI renders them as "projected to run out in X" or "Y credits remaining", that is Phase 3/4 work, not Phase 2. Mitigation: explicit spec scenarios stating "MUST NOT interpret pace as projection" and "MUST NOT label credits as remaining balance". Only display verbatim values if at all (recommendation: do not display pace/credits in this change).
- **Layout disruption in popup:** Adding header fields and expandable sections may break the current popup sizing/scrolling. Mitigation: test with `Kirigami.Units.gridUnit * 44` max height (from `main.qml:66`), ensure `ScrollView` handles overflow, verify compact representation (`CompactUsageButton.qml`) is unaffected.
- **Defensive rendering complexity:** `raw` access must be deeply guarded (`raw && raw.usage && raw.usage.identity && raw.usage.identity.loginMethod`). Missing null checks crash the UI. Mitigation: helper functions in a new `contents/code/RawFieldAccess.js` (or inline guards), exhaustive test coverage for missing/malformed fields.
- **Web-generic patterns:** Risk of introducing HTML/CSS-style layouts (grids, cards, badges) instead of native Plasma/Kirigami primitives. Mitigation: strict adherence to `plasma-kirigami-ui` skill — use `Kirigami.FormLayout`, `PlasmaComponents.Label`, `Kirigami.Separator`, `Kirigami.Icon`. No emoji, no web breakpoints.
- **Accessible labeling:** Expandable sections and dynamic details need `Accessible.name` and `Accessible.description` for screen readers. Mitigation: every new interactive element gets accessible labels per existing patterns in `ProviderRow.qml:50-53` and `UsageWindowRow.qml:34-50`.
- **Test coverage gaps:** New UI components need harness(es) asserting defensive rendering. Mitigation: new `tests/ProviderRowHeaderHarness.qml` and/or `tests/UsageWindowDetailsHarness.qml` following existing executable-harness pattern.
- **README/spec reconciliation:** Current `README.md:120-122` and `openspec/specs/provider-usage-display/spec.md:325-332` state "MVP exclusions" include cost/credits/tokens. This change displays some CLI-supplied data (identity, version, details) but not cost/credits/tokens. Mitigation: explicit spec delta clarifying "display CLI-supplied identity/version/details verbatim; do not compute or display cost/credits/tokens/pace-projections".

### Unresolved Product Questions for Proposal

1. **Should `usage.identity.accountEmail` be displayed (redacted or full)?** The fixture shows it's redacted (`"gxxxxxxxxxxxx@gmail.com"`), but the real CLI may return full email. Product decision needed: show full email, redact in UI, or omit? Recommendation: omit from this change (privacy risk, not critical for Phase 2).
2. **Should `pace` raw values be shown as "available data" (e.g., "pace stage: farAhead") or omitted entirely?** Recommendation: omitted (crosses into Phase 3 interpretation).
3. **Should `credits.remaining` be shown as a raw number or omitted?** Recommendation: omitted (crosses into Phase 4 interpretation).
4. **Should `usage.details[]` be expandable by default or collapsed?** Recommendation: collapsed by default, expandable on click/keyboard, to preserve popup compactness.
5. **Should provider-specific extras (e.g., Codex `antigravityPlanInfo`, Grok `accountOrganization`) be surfaced or ignored?** Recommendation: ignored in this change (too provider-specific, risks scope creep).

### Ready for Proposal

Yes. The exploration has:
- Identified the current state (Phase 1 complete, `raw` available, UI does not read it).
- Defined affected areas (UI components, not normalization/controller).
- Compared three approaches with pros/cons/effort.
- Recommended Approach 2 (header + expandable details) with explicit scope guards.
- Listed risks and mitigations.
- Surfaced unresolved product questions for the proposal phase.

Proposal can proceed on: Approach 2 scope, defensive rendering pattern, test harness strategy, spec delta for header/details rendering, README/spec reconciliation for "display CLI-supplied data but not compute cost/credits/tokens".
