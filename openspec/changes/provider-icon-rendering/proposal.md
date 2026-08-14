# Proposal: Provider Icon Rendering

## Intent

Make every bundled provider icon render as a distinct, recognizable brand mark that is legible on both Breeze Light and Breeze Dark. Today 31 of the 49 SVGs in `contents/icons/providers/` carry a hardcoded literal fill/stroke that defeats theme adaptation: 25 are pure white (rendering as solid white squares at `Kirigami.Units.iconSizes.smallMedium`, ~22px) and 6 are near-black (effectively invisible on Breeze Dark). Two of the white files (`codex.svg`, `azureopenai.svg`) are additionally byte-identical copies of `openai.svg`, so they show the wrong brand entirely. This is an asset-only defect: the lookup layer, the render call sites, and the CLI boundary are correct and stay untouched.

## Scope

### In Scope

- Recolor 31 defective SVGs in `contents/icons/providers/` to the repository's existing `fill="currentColor"` root-`<svg>` convention:
  - 25 white-fill/stroke files: `abacus`, `amp`, `antigravity`, `augment`, `azureopenai`, `bedrock`, `claude`, `codex`, `commandcode`, `copilot`, `crof`, `cursor`, `factory`, `gemini`, `grok`, `groq`, `jetbrains`, `kiro`, `ollama`, `openai`, `synthetic`, `warp`, `windsurf`, `zai`, `vertexai`.
  - 6 near-black files: `alibaba`, `alibabatokenplan`, `kilo`, `manus`, `opencode`, `opencodego`.
- Author genuinely distinct brand geometry for the 2 duplicate files (`codex.svg`, `azureopenai.svg`) so each provider shows its own mark, not OpenAI's.
- Extend the existing offscreen QML harnesses (`tests/ProviderRowHarness.qml`, `tests/ProviderSelectorHarness.qml`) with strict-TDD RED/green assertions that every `knownProviders` key resolves to a parseable, non-duplicate SVG source.
- Add a manual light/dark `plasmawindowed` smoke step to `docs/live-plasma-smoke.md`, because no CI QML runtime exists to prove visual color.

### Out of Scope

Explicit non-negotiables for this change:

- No changes to legacy or current package IDs.
- No changes to the external `codexbar` CLI boundary or the exact command `usage --provider all --format json --json-only`.
- No changes to provider selection behavior.
- No accessibility regressions (accessible names, keyboard traversal, focus order stay as-is).
- No changes to the already-fixed responsive layout from `single-product-transition-responsive-ui`, unless a proven regression is directly caused by this icon fix.
- No changes to user configuration or to `contents/config/`.
- No legacy/current instance validation work mixed in.
- No live refresh, reorder, or removal work mixed in.
- No web dependencies, no emoji icons, no external icon packages or libraries: every fix stays a local, hand-authored or hand-adapted SVG asset in `contents/icons/providers/`.
- No changes to `contents/code/ProviderIcons.js` (`knownProviders` and `key()` are correct), nor to the render logic at `contents/ui/ProviderRow.qml:43-46` and `contents/ui/ProviderSelector.qml:230`.
- No changes to the 18 already-correct icons: the 16 `currentColor` files plus `codebuff.svg` (flat brand green) and `stepfun.svg` (muted grays), all verified legible on both themes.

## User and Developer Value

Users can tell providers apart at a glance in the popup selector and in `All` summary rows, on either Breeze theme, instead of reading a column of identical white blocks. Developers get a single, uniform icon convention across all 49 assets, removing the split between "themed" and "hardcoded" files and making future provider additions a one-line pattern to copy.

## Capabilities

### New Capabilities

- None: no new runtime behavior is introduced.

### Modified Capabilities

- `provider-usage-display`: the existing "authoritative icon or themed fallback" requirement is tightened so that a bundled provider icon MUST be visually distinct per provider and MUST adapt to the active Breeze theme rather than rendering as a fixed light or dark mark.

## Approach

Adopt the repository's own already-shipping convention uniformly: strip every hardcoded literal color from the 31 defective files and set `fill="currentColor"` (plus `stroke="currentColor"` where the source uses stroking) on the root `<svg>`, matching `deepseek.svg`, `mistral.svg`, and `perplexity.svg` exactly. Direct inspection during exploration confirmed each affected file's path geometry is already single-color-shaped and salvageable, so no real brand color is lost. For `codex.svg` and `azureopenai.svg`, replace the borrowed OpenAI path data with correct, distinct geometry authored in the same `currentColor` style; this is authoring work, not a find-replace, and is treated as its own reviewable unit.

Ordering: write the harness assertions first (`strict_tdd: true`), then convert one representative sample and run the manual light/dark `plasmawindowed` smoke check before committing the full batch, then apply the remaining recolors, then author the two replacement marks. `./scripts/lint-qml.sh` and `./scripts/run-qml-tests.sh` stay authoritative after each slice.

### Alternatives Considered

| Alternative | Why not chosen |
|-------------|----------------|
| **Fixed literal color per icon** (a mid-gray or each brand's accent hex instead of `currentColor`) | Sidesteps the QtSvg `currentColor` caveat entirely, but leaves two competing "correct" patterns in one directory (16 `currentColor` files vs 31 literal-hex files) with no stated reason, and no single fixed color is guaranteed adequate contrast against both Breeze Light and Breeze Dark panel backgrounds — a milder rerun of the bug this change exists to fix. Retained as the documented fallback if the smoke check fails. |
| **Hybrid: `currentColor` by default, literal color only for inherently multi-tone marks** | Sound in principle, but it adds a per-file color-mode judgment call to every one of the 31 files, and none of them currently carries more than one literal color, so on the gathered evidence the decision collapses to the recommended approach without buying anything. Remains available per-file if authoring a replacement mark proves a brand genuinely needs two tones. |
| **QML-side recoloring (`isMask: true` or a `ColorOverlay`)** | Rejected: provider icons are intentionally full-color brand logomarks, `isMask` is deliberately unset at both call sites, and this would force every icon — including the correct multi-color ones — into a flat monochrome silhouette while touching render code that is out of scope. |

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/icons/providers/*.svg` (25 white) | Modified | Replace hardcoded white fill/stroke with `currentColor`. |
| `contents/icons/providers/*.svg` (6 near-black) | Modified | Replace hardcoded `#111111`/`#1a1a18`/`#34322D`/`#211E1E` with `currentColor`. |
| `contents/icons/providers/codex.svg`, `azureopenai.svg` | Rewritten | New distinct brand geometry, authored in `currentColor` style. |
| `tests/ProviderRowHarness.qml`, `tests/ProviderSelectorHarness.qml` | Modified | RED-first assertions for resolvable, parseable, non-duplicate icon sources. |
| `openspec/specs/provider-usage-display/spec.md` | Delta | Record the distinct-and-theme-adaptive icon requirement. |
| `docs/live-plasma-smoke.md` | Modified | Add the manual Breeze Light/Dark icon verification step. |
| `contents/code/ProviderIcons.js`, `contents/ui/ProviderRow.qml`, `contents/ui/ProviderSelector.qml` | Unchanged | Read-only reference; verified correct, must not change. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `currentColor` resolution through `Kirigami.Icon` is proven only empirically for the 16 shipping single-tone icons; general Qt docs state bare `QSvgRenderer` does not resolve it. | Med | Convert one sample and run a manual light/dark `plasmawindowed` smoke check **before** the full batch. If it fails, fall back to the fixed-literal-color alternative. |
| The two replacement marks (`codex.svg`, `azureopenai.svg`) are authoring work and are the most likely place to ship a wrong logo. | Med | Isolate as a separate reviewable work unit; verify each against the correct brand mark; do not bundle with the mechanical recolors. |
| 31 touched files plus tests, spec delta, and docs likely exceed the 400-line review budget. | High | Flag now. The tasks phase applies `ask-on-risk`: stop and request a delivery decision, then split `stacked-to-main` into white recolor / near-black recolor / duplicate-logo authoring slices. |
| No CI QML runtime exists, so automated tests can prove an SVG resolves and parses, not that it is visually legible. | High | Manual `plasmawindowed` smoke on both Breeze themes is a mandatory acceptance gate, not an optional extra. |
| Exploration's file count of "33 files" double-counted the 2 duplicates, which are already inside the 25-file white category. | Low | Corrected here and verified: 49 total icons = 31 affected + 18 needing no action (16 `currentColor` + `codebuff` + `stepfun`). |
| A recolored icon could lose contrast against an unusual custom Plasma color scheme. | Low | `currentColor` binds to the active `Kirigami.Theme` text color, which is contrast-guaranteed against its own background by the color scheme itself. |

## Rollback Plan

Revert the SVG, harness, spec-delta, and documentation changes as one work unit (or per stacked slice if the change is split). No QML or JS logic, package identity, installed package, panel instance, user configuration, or external CLI behavior is touched, so rollback restores the prior visual state exactly with no migration or data concern.

## Dependencies

- Plasma 6 / Kirigami runtime with Qt 6.11.1 and the existing `./scripts/run-qml-tests.sh` and `./scripts/lint-qml.sh` gates.
- `plasmawindowed` available locally for the manual light/dark smoke check.
- Reference brand geometry for the Codex and Azure OpenAI marks, sourced locally as hand-adapted SVG paths (no external icon package).

## Success Criteria

- [ ] Every provider in `knownProviders` renders a visible icon that is distinct from every other provider's icon; `codex.svg` and `azureopenai.svg` are no longer byte-identical to `openai.svg` or to each other.
- [ ] No icon renders as a solid white block or an invisible dark shape at `Kirigami.Units.iconSizes.smallMedium`.
- [ ] Manual `plasmawindowed` smoke confirms correct, legible rendering of the full provider list in **both** Breeze Dark and Breeze Light.
- [ ] All 31 converted files use `fill="currentColor"` on the root `<svg>` with no hardcoded literal color remaining; the 18 already-correct icons are byte-unchanged.
- [ ] Preserved-behavior guarantees verified: package IDs unchanged, `usage --provider all --format json --json-only` unchanged, provider selection behavior unchanged, no accessibility regression.
- [ ] `contents/code/ProviderIcons.js`, the two render call sites, `contents/config/`, and user configuration are unchanged.
- [ ] `./scripts/run-qml-tests.sh`, `./scripts/lint-qml.sh`, and `git diff --check` pass.
- [ ] If the change exceeds the 400-line review budget, an `ask-on-risk` delivery decision was requested and `stacked-to-main` slices were used.
