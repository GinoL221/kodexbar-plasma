# Tasks: Provider Icon Rendering

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | Slice 0a ~276 / Slice 0b ~280 / Slice 1 ~306 / Slice 2 ~114 / Slice 3 ~45 — total ~1021 |
| 400-line budget risk | Low — all five slices under 400 after the confirmed 0a/0b split |
| Chained PRs recommended | Yes |
| Suggested split | PR 0a exploration+proposal+spec → PR 0b design+tasks → PR 1 authored marks + checker + CI + docs → PR 2 white-file recolor (gated by 2-sample smoke) → PR 3 near-black recolor + invariant-4 gate |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision resolved: user confirmed the 0a/0b split (not `size:exception`) for the Slice 0 budget risk. `sdd-apply` proceeds with five stacked-to-main PRs.
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: Low (all slices under 400 post-split)

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 0a | Exploration + proposal + spec delta | PR 0a | `git diff --check` | None (no product files) | `openspec/changes/provider-icon-rendering/{exploration.md,proposal.md,specs/**}` only |
| 0b | Design + tasks | PR 0b | `git diff --check` | None (no product files) | `openspec/changes/provider-icon-rendering/{design.md,tasks.md}` only |
| 1 | Authored marks + checker (invariants 1,2,3,5) + RED-first tests + CI + docs skeleton | PR 1 | `python3 -m unittest tests/test_provider_icons.py` | None (asset + Python only) | `contents/icons/providers/codex.svg`, `contents/icons/providers/azureopenai.svg`, `scripts/check-provider-icons.py`, `tests/test_provider_icons.py`, `.github/workflows/ci.yml`, `docs/live-plasma-smoke.md`, `README.md` |
| 2 | 2-sample de-risking smoke gate, then remaining 21 white-file recolors | PR 2 | `python3 -m unittest tests/test_provider_icons.py` | `plasmawindowed org.kde.plasma.kodexbar.plasma` + `plasma-apply-colorscheme BreezeLight`/`BreezeDark` | 23 white-file SVGs under `contents/icons/providers/` |
| 3 | 6 near-black recolors + enable checker invariant 4 | PR 3 | `python3 -m unittest tests/test_provider_icons.py` | `plasmawindowed` full-batch two-theme smoke (all 49 providers) | 6 near-black SVGs, `scripts/check-provider-icons.py` invariant-4 block |

## Guardrail — read before Slice 1

`contents/icons/codex.svg` is the **applet** icon (tri-color rounded-rect badge, required by `validate-package.sh`). It is **not** the same file as `contents/icons/providers/codex.svg` (the provider mark this change replaces). Every task below that names a `codex.svg` edit means the `contents/icons/providers/` path only. Never edit, reuse, or reference `contents/icons/codex.svg` in this change.

## Slice 0a: Planning — Exploration, Proposal, Spec (branch `slice/provider-icon-rendering-0a-planning`, base `main`)

- [x] 0a.1 Confirm `exploration.md`, `proposal.md`, and `specs/provider-usage-display/spec.md` are complete, internally consistent, and free of contradictions (already authored in the explore/propose/spec phases; no edits expected here).
- [x] 0a.2 Run `git diff --check` over the new/untracked files in this slice (whitespace only; no product files exist yet).

## Slice 0b: Planning — Design, Tasks (branch `slice/provider-icon-rendering-0b-design-tasks`, base Slice 0a)

- [x] 0b.1 Confirm `design.md` is complete, internally consistent with 0a, and free of contradictions (already authored in the design phase; no edits expected here).
- [x] 0b.2 Finalize this `tasks.md` (including the confirmed 0a/0b split recorded above) and persist it to both Engram (`sdd/provider-icon-rendering/tasks`) and `openspec/changes/provider-icon-rendering/tasks.md`.
- [x] 0b.3 Run `git diff --check` over the new/untracked files in this slice (whitespace only; no product files exist yet).

## Slice 1: Marks and Gate (branch `slice/provider-icon-rendering-1-marks-and-gate`, base Slice 0b)

### RED — checker contract, before the checker exists

- [x] 1.1 RED: create `tests/test_provider_icons.py` with `tempfile`-backed fixture-tree unit tests for invariants 1 (coverage: a `knownProviders` key with no matching SVG must fail), 2 (no orphans: an `.svg` with no matching key must fail), 3 (parseable: malformed XML must fail), and 5 (distinctness: an unsanctioned duplicate pair must fail; a `SANCTIONED_DUPLICATES` group — `{alibaba, alibabatokenplan}`, `{kimi, kimik2, moonshot}`, `{opencode, opencodego}` — must pass). Do not write invariant-4 (banned literal color) tests yet — deferred to Slice 3 per design's "invariants enabled in the slice where they become satisfiable."
- [x] 1.2 RED: confirm the suite fails because `scripts/check-provider-icons.py` does not exist yet (import/collection failure counts as RED).
- [x] 1.3 RED: add one integration-level test that runs the (not-yet-existing) checker against the real repository tree and asserts invariant 5 currently fails, naming the real defect: `openai.svg`, `contents/icons/providers/codex.svg`, and `contents/icons/providers/azureopenai.svg` currently share content hash `a35f3231d59ef004f88f598b44bc5eae`. Confirm this assertion is genuinely RED against the current tree.

### GREEN — authored marks (exact literal source from design.md, no interpretation)

- [x] 1.4 GREEN: replace the full contents of `contents/icons/providers/codex.svg` (the **provider** icon — see Guardrail above, not the applet icon) with the exact authored terminal-prompt-glyph SVG from `design.md` (`>` chevron path `M30 30L52 50L30 70` plus detached cursor bar `M58 70H74`, both `stroke="currentColor" stroke-width="10"`, round caps/joins, `fill="none"` root, `viewBox="0 0 100 100"`).
- [x] 1.5 GREEN: replace the full contents of `contents/icons/providers/azureopenai.svg` with the exact authored cloud-silhouette-with-anchor-dot SVG from `design.md` (three unioned `<circle>`s plus a rounded `<rect>` base bar, all `fill="currentColor"` inside one `<g>`, plus a separate anchor `<circle>` dot, `fill="none"` root, `viewBox="0 0 100 100"`).
- [x] 1.6 GREEN: confirm neither authored mark reuses the `vertexai.svg` hexagon motif, the `openai.svg` sunburst, or the `mimo.svg` chevron; confirm both are single-tone `currentColor` with no external fetch, icon package, or dependency.

### GREEN — checker (invariants 1, 2, 3, 5 only)

- [x] 1.7 GREEN: create `scripts/check-provider-icons.py` (`pathlib`, `re`, `hashlib`, `xml.etree.ElementTree` only — standard library, no new dependency) implementing invariants 1 (coverage), 2 (no orphans), 3 (parseable, root tag `{http://www.w3.org/2000/svg}svg`), and 5 (distinctness with `SANCTIONED_DUPLICATES` allowlist). Parse `knownProviders` from `contents/code/ProviderIcons.js`; enumerate `contents/icons/providers/*.svg`; exit 0 on pass, non-zero with a per-violation message on fail. Do not implement invariant 4 (banned literal color) yet.
- [x] 1.8 GREEN: run `python3 -m unittest tests/test_provider_icons.py` until all invariant 1/2/3/5 tests pass, including the Slice-1.3 integration test now passing because `codex.svg`/`azureopenai.svg` no longer duplicate `openai.svg`.

### Wiring and documentation

- [x] 1.9 Add one step to `.github/workflows/ci.yml` invoking `scripts/check-provider-icons.py` (mirrors the archived `check-qml-unqualified-baseline.py` CI wiring precedent). Do not modify the existing `validate-package.sh`, `lint-qml.sh`, or `git diff --check` steps.
- [x] 1.10 Update `docs/live-plasma-smoke.md`: add the mandatory two-theme provider-icon smoke section (the exact `plasmawindowed` + `plasma-apply-colorscheme BreezeLight`/`BreezeDark` procedure, PASS/FAIL criteria, and the per-icon literal-color fallback steps from `design.md`), plus an (initially empty) literal-color exception table for any file the fallback is later applied to.
- [x] 1.11 Update `README.md` to document the new `scripts/check-provider-icons.py` gate alongside the existing `validate-package.sh`, `lint-qml.sh`, and `run-qml-tests.sh` gates, matching the archived `modernize-qml-static-analysis` documentation precedent.
- [x] 1.12 Run `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, `./scripts/run-qml-tests.sh`, `python3 -m unittest tests/test_provider_icons.py`, and `git diff --check`. Confirm `contents/code/ProviderIcons.js`, `contents/ui/ProviderRow.qml`, `contents/ui/ProviderSelector.qml`, `contents/config/**`, `metadata.json`, and `contents/icons/codex.svg` (applet icon) remain byte-unchanged.

## Slice 2: White-File Recolor (branch `slice/provider-icon-rendering-2-white-recolor`, base Slice 1)

### De-risking gate — blocks the bulk batch

- [ ] 2.1 Convert `contents/icons/providers/synthetic.svg`: apply R1 (`fill="white"` → `fill="currentColor"`) and R4 (`stroke="white"` → `stroke="currentColor"`) at every occurrence (12 total: top-level strokes plus the nested `<g transform>` whose `<path>`/`<circle>` carry both). Do not touch any `fill="none"` (P1). No reformatting, no attribute reordering, no `xmlns`/`viewBox`/size changes (P6, P7).
- [ ] 2.2 Convert `contents/icons/providers/jetbrains.svg`: apply R5 by editing **inside the `style` attribute value only**, both occurrences (`style="fill:#fff;"` → `style="fill:currentColor;"` and `style="fill:#fff;fill-rule:nonzero;"` → `style="fill:currentColor;fill-rule:nonzero;"`). Do **not** add a `fill="currentColor"` presentation attribute (P5) — a CSS `style` declaration outranks a presentation attribute, so the literal would survive while the diff looked correct.
- [ ] 2.3 **MANUAL ACCEPTANCE GATE — not automatable, blocks task 2.4.** Run `plasmawindowed org.kde.plasma.kodexbar.plasma`; with the window open, run `plasma-apply-colorscheme BreezeLight`, open the popup, select `All`, and inspect `synthetic` and `jetbrains` at `Kirigami.Units.iconSizes.smallMedium`; then run `plasma-apply-colorscheme BreezeDark` and repeat. PASS requires: dark glyph on light background under BreezeLight, light glyph on dark background under BreezeDark, identical silhouette across both runs and versus pre-edit geometry, and the glyph is neither blank, a solid block, nor clipped. FAIL on either file: first re-diagnose for a surviving `style` literal (P5 cascade) or nested-override literal (P4); only if `currentColor` genuinely does not resolve, apply the `#7F7F7F` fallback to that file only, re-smoke both themes, record the file and reason in the `docs/live-plasma-smoke.md` exception table, and add the file to the checker's `LITERAL_COLOR_ALLOWLIST`. Do not proceed to 2.4 until both files PASS (with or without fallback).
- [ ] 2.4 Bulk-convert the remaining 21 white files under P1/P4/P6/P7, exactly per design's rule table: R1 `fill="white"` → `currentColor` for `abacus` (10 occurrences), `amp`, `antigravity`, `augment`, `claude`, `copilot`, `crof`, `cursor`, `factory`, `gemini`, `ollama`, `openai`, `warp`, `windsurf`, `zai`, `vertexai`; R2 `fill="#FFFFFF"` → `currentColor` for `bedrock`, `grok`, `groq`; R3 `fill="#ffffff"` → `currentColor` for `kiro` (fill sits on a `<g>`, not the root `<svg>` — P4); R4 `stroke="white"` → `currentColor` for `commandcode`. For `vertexai.svg`, swap only the two white tokens (`fill="white"` inner hexagon, `stroke="white"` outer hexagon) and retain `fill="#4285F4"` on the core circle unchanged (P2).
- [ ] 2.5 Run `python3 -m unittest tests/test_provider_icons.py`; confirm invariants 1, 2, 3, and 5 still pass (invariant 4 remains disabled until Slice 3).
- [ ] 2.6 Run `./scripts/run-qml-tests.sh`, `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, and `git diff --check`. Review `git diff --stat` and confirm only the 23 white-file SVGs changed in this slice — no path outside `contents/icons/providers/` moved.

## Slice 3: Near-Black Recolor and Color Gate (branch `slice/provider-icon-rendering-3-nearblack-and-color-gate`, base Slice 2)

- [ ] 3.1 RED: extend `tests/test_provider_icons.py` with invariant-4 unit fixtures: a banned `fill` attribute, a banned `style` `fill:`/`stroke:` declaration, a banned token inside a `<clipPath>`/`<mask>` subtree (must pass — skipped by tree position), `fill="none"`/`stroke="none"` (must pass — never a banned token), an allowlisted file (`codebuff.svg`, `stepfun.svg`, `vertexai.svg` — must pass despite `vertexai.svg`'s retained `#4285F4`). Confirm RED: the checker has no invariant-4 implementation yet, and/or the 6 near-black files still carry their literal tokens.
- [ ] 3.2 GREEN: convert the 6 near-black files under identical mechanical treatment (P1/P4/P6/P7, no per-brand judgment): R6 `fill="#111111"` → `currentColor` for `alibaba`, `alibabatokenplan`; R7 `fill="#1a1a18"` → `currentColor` for `kilo`; R8 `fill="#34322D"` → `currentColor` for `manus`; R9 `fill="#211E1E"` → `currentColor` for `opencode`, `opencodego`.
- [ ] 3.3 GREEN: enable invariant 4 in `scripts/check-provider-icons.py` — walk the element tree; fail on any `fill`/`stroke` attribute or `style` `fill:`/`stroke:` declaration matching a banned token (case-insensitive: `white`, `#fff`, `#ffffff`, `#111111`, `#1a1a18`, `#34322d`, `#211e1e`, `#000`, `#000000`, `black`); skip elements inside `<clipPath>`/`<mask>` subtrees by tree position; skip files in `LITERAL_COLOR_ALLOWLIST = {codebuff.svg, stepfun.svg, vertexai.svg}` plus any file added by the Slice 2 fallback procedure; never treat `fill="none"`/`stroke="none"` as banned.
- [ ] 3.4 Run `python3 -m unittest tests/test_provider_icons.py`; confirm the invariant-4 tests are now GREEN and the full suite (all 5 invariants) passes with no false positive on `openrouter.svg`'s inert `<clipPath>` rect, no false positive on the 3 allowlisted files, and no false positive on any of the 18 already-correct provider SVGs.
- [ ] 3.5 **MANUAL ACCEPTANCE GATE — not automatable, final.** Initially closed with cross-slice representative evidence (one icon per fix category: `codex`, `claude`/`grok`, `opencodego`), then fully closed the same day with a genuine full-catalog audit: a temporary ad hoc fixture CLI (not committed) emitted all 49 `knownProviders` at once in the exact CLI JSON contract, the user pointed their real panel widget at it, and visually confirmed all 49 providers render distinct, legible, correctly themed icons in BreezeLight (7 screenshots) with BreezeDark spot-checked equivalently, including `alibaba`/`alibabatokenplan` specifically confirmed legible against the dark background. See "Slice 3 full-batch manual gate evidence (2026-08-14)" and its "Update — full 49-provider live confirmation" in `docs/live-plasma-smoke.md`.
- [ ] 3.6 Run the full regression suite: `./scripts/run-qml-tests.sh`, `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, `python3 -m unittest discover -s tests`, and `git diff --check`. Review `git diff --stat` across all four slices and confirm `contents/code/ProviderIcons.js`, `contents/ui/ProviderRow.qml`, `contents/ui/ProviderSelector.qml`, `contents/config/**`, `metadata.json`, `contents/icons/codex.svg` (applet icon), `tests/ProviderRowHarness.qml`, `tests/ProviderSelectorHarness.qml`, and the 18 already-correct provider SVGs are all byte-identical to their pre-change state. All green: 15/15 QML harnesses, lint baseline accepted, package validated, 32/32 Python tests, `git diff --check` clean; all protected paths confirmed byte-unchanged via `git diff --quiet`.

## Non-Goals (in force for `sdd-apply` — drift into any of these is a defect)

- No changes to legacy or current package IDs.
- No changes to the external `codexbar` CLI boundary or the exact command `usage --provider all --format json --json-only`.
- No changes to provider selection behavior.
- No accessibility changes or regressions.
- No changes to the responsive layout from `single-product-transition-responsive-ui`.
- No changes to user configuration or to `contents/config/`.
- No changes to `contents/code/ProviderIcons.js`, `contents/ui/ProviderRow.qml`, or `contents/ui/ProviderSelector.qml`.
- No changes to the 18 already-correct provider icons.
- No QML-side recoloring (`isMask`, `ColorOverlay`).
- No web dependencies, emoji icons, external icon packages, or fetched assets.
