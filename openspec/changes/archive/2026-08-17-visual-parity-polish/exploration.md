# Exploration: visual-parity-polish

## Status
Complete — both open questions resolved by user. Ready for `sdd-propose`.

## User Decisions (resolved 2026-08-15)
1. **Slice 4 "Extra usage / model windows" — dropped from scope.** No CLI backing found in the real fixture; user confirmed removal. `usage.providerCost` remains out of scope, a separate future decision if ever revisited.
2. **Slice 2 "refresh next to header" — refresh stays as-is.** The single global Refresh `ToolButton` above `ProviderSelector` is NOT repositioned into `ProviderHeader`. Slice 2 scope is now: `ProviderHeader` two-column layout (plan/login badge right, clean Updated) only — no refresh relocation.

## Executive Summary
All 5 proposed slices are technically feasible without violating the CLI/pricing/auth boundary, but slice 4's "model windows / extra usage" idea has **no CLI support** in the real captured fixture and should be dropped (or narrowly rescoped to the unused `usage.providerCost` field as a separate future decision), and slice 2's "refresh next to header" needs one design clarification (single global control repositioned vs. per-row). Recommend one consolidated `visual-parity-polish` OpenSpec change with chained work units, matching this repo's established pattern (`qml-visual-regression`, `final-popup-parity`), reusing the already-complete visual-regression harness for slice 5.

## Current State

The popup (`contents/ui/main.qml`) renders: a global `ToolButton` for Refresh (top, standalone, not tied to any provider header) → `ProviderSelector` tabs (icon + short name only, `All` + usable providers, already matches checklist) → `ProviderRow` delegates (summary rows for `All`, or one detailed row for the selected provider).

- `ProviderHeader.qml` — single `RowLayout`: icon on the left, then **one** `ColumnLayout` stacking name/source/version/login/email/org/"Updated: …" all left-aligned. No two-column layout, no badge styling anywhere.
- `UsageWindowRow.qml` — a single `RowLayout`: `label | ProgressBar | "% used"` all on one row; `Reset: …`, reset description, and pace text are separate rows **below**, only when `!summary`. Does **not** match the requested "title → full-width bar → '% used' | 'Resets in…' same band" hierarchy — a real layout gap.
- `ProviderSelector.qml` — `TabBar` already shows icon + short name only (no `%`, no threshold coloring); full `source` is accessible-name only. No percentage-in-tab or bar-coloring logic exists anywhere in the codebase.
- `CostSection.qml` / `CostController.qml` / `CostRequestPolicy.js` — cleanly isolated, generation-correlated, provider-gated (`codex`/`claude` only), fail-closed, matches `provider-cost-estimate` spec exactly. No pricing computed in QML.
- No in-popup footer exists at all today beyond the top Refresh button and the bottom `ErrorSummary`.

Real captured CLI fixture (`tests/fixtures/codexbar-usage-capture.json`) confirms the exact shape actually available:
- `usage.loginMethod` / `identity.loginMethod` (e.g. `"plus"`, `"SuperGrok"`, `"Individual"`) is already validated and rendered (`ProviderDetailsLogic.validLoginMethod`) — this **is** effectively the "plan" data macOS CodexBar shows; no new CLI capability needed for a plan badge.
- `pace.primary/secondary/tertiary` map 1:1 to Session/Weekly/Monthly (`contents/code/ProviderDetails.js:241-266`, `UsageModel.js`) — already implemented.
- **No per-model usage breakdown / "extra usage windows" field exists anywhere in the real fixture.** The only extra data point not currently surfaced is `usage.providerCost` (seen once, on `opencodego`: `{period, currencyCode, limit, used}`) — a *different* cost concept than our own `cost` CLI command's `sessionCostUSD`/`last30Days*` fields, and it is not normalized into the stable provider contract today.

`openspec/changes/qml-visual-regression` is fully applied (confirmed via `apply-progress.md`): all 3 work units done, native settlement `passed` for PR1/2/3, harness (`./scripts/run-visual-tests.sh`, 4 canonical Breeze Light/Dark × Cost present/absent scenarios, goldens under `tests/visual/goldens/`, Docker `UPDATE_GOLDENS=1` regeneration) is real and immediately usable for slice 5.

## Affected Areas

- `contents/ui/UsageWindowRow.qml` — slice 1: full row restructure (title/bar/percent-and-reset band). `objectName` aliases (`windowLabel`, `percentageLabel`, `resetsAtLabel`, `resetDescriptionLabel`, `paceSummaryLabel`) are asserted by `tests/ProviderRowHarness.qml`, `tests/ProviderDetailsIntegrationTest.qml`, and the visual harness — high blast radius, must preserve or deliberately update in lockstep.
- `contents/ui/ProviderHeader.qml` — slice 2: two-column layout (name/source left, plan/login badge right); same `objectName` test-coupling risk as above (`providerLabel`, `sourceLabel`, `versionLabel`, `loginLabel`, `emailLabel`, `organizationLabel`, `updatedAtLabel`).
- `contents/ui/main.qml` — slice 2: Refresh `ToolButton` currently lives above `ProviderSelector`, decoupled from any header; "refresh next to header" needs a design decision (see Risks).
- `contents/ui/ProviderSelector.qml` — slice 3: `TabBar`/`TabButton` for optional `%`-in-label and/or threshold-colored representative bar; no existing threshold-color module to reuse.
- `contents/ui/CostSection.qml` — slice 4: typography-only polish; already isolated and spec-compliant, low risk.
- `contents/ui/main.qml` (footer) — slice 4: no footer chrome exists; must stay purely informational (status/last-updated), not a new Settings/About control (see Risks).
- `tests/visual/goldens/*.png`, `docs/visual-regression.md`, `docs/ui-parity-checklist.md`, `docs/live-plasma-smoke.md` — slice 5: goldens need regeneration via the Docker `UPDATE_GOLDENS=1` flow since slices 1-3 intentionally change pixel output; manual live/theme checklist passes required per project convention.

## Approaches Considered

### 1. One consolidated `visual-parity-polish` change, 5 chained work units (recommended)
Matches `qml-visual-regression`, `final-popup-parity` precedent — every past change in `openspec/changes/archive/` uses one change folder + one `tasks.md` with multiple chained/stacked PR work units.
- Pros: keeps visually-coupled slices (UsageWindowRow + ProviderHeader both render inside every `ProviderRow`) coherent under one spec/design; reuses this repo's own chaining discipline (400-line budget/PR, `ask-on-risk`/`stacked-to-main`); one golden-regeneration pass at the end.
- Cons: larger single spec surface to review; needs careful per-work-unit budget tracking across 5 slices.
- Effort: Medium per unit, Medium-High overall.

### 2. Five independent SDD changes, one per slice
- Pros: maximal isolation, trivially small individual review diffs.
- Cons: fragments two files (`UsageWindowRow.qml`, `ProviderHeader.qml`) touched by different "changes" but rendered together — increases merge/golden churn (regeneration needed after *each* slice instead of once); breaks from this repo's established one-change-many-work-units convention; 5x proposal/spec/design/tasks overhead.
- Effort: Low per change, High in aggregate coordination cost.

## Recommendation
Approach 1 — one `visual-parity-polish` change, work units mirroring the 5 slices, with slice 5 (verification) as the final chained unit regenerating goldens once. Resolve two open questions before `sdd-propose`/`sdd-spec` (see Risks) so they don't have to guess.

## Risks

- **Slice 4 boundary risk (real, not hypothetical)**: the CLI does not return any per-model/"extra usage window" data in the actual fixture. Implementing this as literally requested would force fabricating data in QML, which `Requirement: Provider-focused exclusions` in `openspec/specs/provider-usage-display/spec.md` explicitly forbids ("MUST NOT compute or fabricate pace, credits, resets, identity, organization, cost, or tokens"). Recommend dropping "Extra usage / model windows" from scope entirely; the only real candidate is the unused `usage.providerCost` field (seen for `opencodego`), a *different* cost concept from the `cost` CLI command, needing its own explicit spec decision — out of scope for this polish round unless requested separately.
- **Slice 4 footer risk**: the brief asks for "a useful footer without Quit/Add Account," but `docs/ui-parity-checklist.md` already states "Settings via Plasma configure action only (no in-popup Auth / Add Account / Quit)" — adding any in-popup Settings/About control would directly contradict this existing, already-verified rule. Footer must stay informational only (e.g. status/last-updated line reusing `controller.phase`/`committedGeneration` state), not a new control surface.
- **Slice 2 ambiguity**: "refresh button placed next to header" is underspecified — `ProviderHeader` is instantiated once per `All`-summary row *and* once for the selected-detail row, but there is exactly one global Refresh control today. Moving it "into" the header risks either duplicating it per summary row (wrong) or needing a redesign of where the single control lives. Needs one explicit design decision before `sdd-design`.
- **Test/harness coupling**: `UsageWindowRow.qml` and `ProviderHeader.qml` `objectName` aliases are asserted by multiple existing QML test harnesses and the visual-regression suite. Any restructuring must update those assertions in the same TDD cycle (RED before GREEN), per this repo's Strict TDD convention.
- **Golden regeneration cost**: slices 1-3 will change pixel output, so the 4 existing visual goldens are expected to break and must be regenerated via the documented Docker `UPDATE_GOLDENS=1` flow (host-only regeneration is explicitly discouraged per `docs/visual-regression.md`) — expected, not a defect, but should be budgeted as its own final work unit.
- **Threshold-coloring (slice 3, optional)**: no existing module colors a `QQC2.ProgressBar` by usage threshold; must use `Kirigami.Theme.*` semantic colors only (no hardcoded hex), per `skills/plasma-kirigami-ui/SKILL.md`. Feasible but adds real implementation surface — confirm the user wants this optional item before scoping it into tasks.

## Key Learnings
1. `usage.loginMethod`/`identity.loginMethod` already functions as a plan indicator (e.g. `"plus"`, `"SuperGrok"`) — a plan badge needs no new CLI capability.
2. No per-model or "extra usage window" field exists in the captured `codexbar` usage fixture; only `usage.providerCost` (seen once, for `opencodego`) is unrendered and would need a separate spec decision.
3. `UsageWindowRow.qml` currently places label, bar, and percentage on one row instead of the requested title-then-full-width-bar-then-percent/reset band layout.
4. `openspec/changes/qml-visual-regression` is fully applied with all native settlements passed, so its four-scenario Docker-based golden harness is immediately reusable for verification.
5. `docs/ui-parity-checklist.md` already forbids any in-popup Settings/About control, which directly constrains how a "useful footer" in slice 4 can be implemented.

## Ready for Proposal
Yes — both blockers resolved (see User Decisions above). `sdd-propose` can proceed with:
- Slice 4 scope: Cost section typography polish + informational footer only. No model-window/extra-usage data.
- Slice 2 scope: `ProviderHeader` two-column layout only. Global Refresh control stays where it is today.
