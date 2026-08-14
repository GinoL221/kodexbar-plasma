# Design: Provider Icon Rendering

## Technical Approach

This is an asset-only change. `contents/code/ProviderIcons.js`, `contents/ui/ProviderRow.qml:38-46`, and `contents/ui/ProviderSelector.qml:230` are verified correct and stay byte-unchanged; every edit lands in `contents/icons/providers/*.svg` plus one new non-QML gate.

29 of the 31 defective files are a mechanical, token-level color swap to the repository's shipping `currentColor` convention. The remaining 2 (`codex.svg`, `azureopenai.svg`, both byte-identical to `openai.svg`) are replaced with hand-authored geometric marks. A new standard-library Python checker makes the asset invariants enforceable in CI, because direct inspection proved that **no existing gate inspects `contents/icons/providers/` at all**: `lint-qml.sh` only runs `qmllint` over `contents/ui/**/*.qml`, `validate-package.sh` only validates `metadata.json` fields plus five required paths, and `run-qml-tests.sh` (not run by CI) exercises the icon *resolver*, never the asset bytes.

The `currentColor` assumption is empirically settled only for single-tone, attribute-form SVGs. This design therefore gates the bulk batch behind a two-sample manual smoke check covering the two mechanically distinct color-carrier forms, and defines an explicit per-icon literal-color fallback.

## Architecture Decisions

| Option | Tradeoff | Decision and rationale |
|---|---|---|
| Enforce asset invariants in the QML harnesses (proposal's stated plan) | Matches the proposal text | **Rejected, documented refinement.** The invariants are pure file-content facts needing no QML runtime; QML file I/O over `file://` is awkward; and CI does not run `run-qml-tests.sh` (`.github/workflows/ci.yml` marks it a local gate), so the assertions would never gate a PR. `tests/ProviderRowHarness.qml` and `tests/ProviderSelectorHarness.qml` stay unchanged. |
| New `scripts/check-provider-icons.py` + `tests/test_provider_icons.py`, wired into CI | One extra CI step | **Chosen.** Exactly mirrors the precedent archived in `2026-08-14-modernize-qml-static-analysis` (`scripts/check-qml-unqualified-baseline.py` + `tests/test_qml_unqualified_baseline.py`). Standard library only, no new dependency, runs in CI where `run-qml-tests.sh` cannot. |
| Raw regex over SVG text for the banned-color check | Simple, but wrong | **Rejected.** A text regex cannot distinguish structural `fill="none"` from paint, and would false-positive on `openrouter.svg`'s inert `<clipPath>` rect. Walk the XML tree and inspect `fill`/`stroke` attributes and `style` declarations by element position instead. |
| "No two provider SVGs may be byte-identical" | Cheap and directly prevents the regression class | **Chosen with an allowlist.** `md5sum` proved three *sanctioned* brand-family duplicate groups already exist (`alibaba`/`alibabatokenplan`, `kimi`/`kimik2`/`moonshot`, `opencode`/`opencodego`). A naive rule would produce three false failures; the allowlist encodes intent. |
| Force `vertexai.svg` fully monochrome | Uniformity | **Rejected.** `vertexai.svg` is genuinely dual-tone (`stroke="white"` hexagon, `fill="white"` inner hexagon, `fill="#4285F4"` core). Swap only the two white tokens; retain `#4285F4` as a documented intentional accent, matching the accepted precedent of `codebuff.svg` (`#44FF00`) and `stepfun.svg` (grays), both already classified "no action". This corrects the proposal's claim that no affected file carries more than one literal color. |
| One sample file for the pre-batch smoke check | Proposal's plan | **Refined to two.** Two mechanically distinct carrier forms exist; a pass on the attribute form proves nothing about the CSS `style` form. See the de-risking gate below. |

## Component Boundaries and Data Flow

    ProviderIcons.knownProviders (49 keys, unchanged)
      -> ProviderRow.defaultIconSource / ProviderSelector delegate (unchanged)
      -> Qt.resolvedUrl("../icons/providers/<key>.svg")
      -> Kirigami.Icon  (isMask deliberately unset, unchanged)
      -> KIconEngine / QtSvg resolves currentColor against Kirigami.Theme text color

    scripts/check-provider-icons.py
      -> parse knownProviders from contents/code/ProviderIcons.js
      -> enumerate contents/icons/providers/*.svg
      -> XML tree walk + byte hashing -> pass/fail

## SVG Edit Mechanics

Apply to the **29 recolor files only**. The 18 already-correct icons (16 `currentColor` files plus `codebuff.svg` and `stepfun.svg`) must remain byte-unchanged.

| Rule | Exact match in file | Replacement | Files |
|---|---|---|---|
| R1 | `fill="white"` | `fill="currentColor"` | abacus, amp, antigravity, augment, claude, copilot, crof, cursor, factory, gemini, ollama, openai, synthetic, warp, windsurf, zai, vertexai |
| R2 | `fill="#FFFFFF"` | `fill="currentColor"` | bedrock, grok, groq |
| R3 | `fill="#ffffff"` | `fill="currentColor"` | kiro |
| R4 | `stroke="white"` | `stroke="currentColor"` | commandcode, synthetic, vertexai |
| R5 | `fill:#fff` **inside the `style` attribute value** | `fill:currentColor` | jetbrains (2 occurrences: `style="fill:#fff;"` and `style="fill:#fff;fill-rule:nonzero;"`) |
| R6 | `fill="#111111"` | `fill="currentColor"` | alibaba, alibabatokenplan |
| R7 | `fill="#1a1a18"` | `fill="currentColor"` | kilo |
| R8 | `fill="#34322D"` | `fill="currentColor"` | manus |
| R9 | `fill="#211E1E"` | `fill="currentColor"` | opencode, opencodego |

The 6 near-black files take the **identical** mechanical treatment (R6-R9); no special-casing, no per-brand color judgment.

Hard prohibitions:

- **P1 — never change `fill="none"`.** It is structural (stroke-only shapes and container groups). Every white file also carries it; a blanket fill replacement destroys geometry.
- **P2 — never change `fill="#4285F4"`** in `vertexai.svg`.
- **P3 — never touch `openrouter.svg`.** Its `fill="white"` sits on a `<rect>` inside `<clipPath id="clip0">`, where paint is ignored by the clipping algorithm. It is inert, and `openrouter.svg` belongs to the already-correct set.
- **P4 — replace at every occurrence, including nested overrides.** Do not assume the root `<svg>` fill governs: `kiro.svg` carries its fill on a `<g>`, `synthetic.svg` carries `stroke="white"` on 8 sibling `<path>` elements plus a nested `<g>` whose `<path>` and `<circle>` each carry both `fill="white"` and `stroke="white"`, and `abacus.svg` has 10 separate occurrences.
- **P5 — for `jetbrains.svg`, edit inside the `style` attribute.** Do **not** add a `fill="currentColor"` presentation attribute: a CSS `style` declaration outranks a presentation attribute, so the literal would survive and the icon would stay white while the diff looked correct. This is the single most likely silent failure in the batch.
- **P6 — no reformatting.** Do not re-indent, re-minify, reorder attributes, or normalize line endings. The diff must be color-token-only so review can confirm geometry is untouched.
- **P7 — do not add or remove** `xmlns`, `width`/`height`, `viewBox`, `<title>`, `<metadata>`, or the potrace comment in `kiro.svg`.

## De-risking Gate: Sample Conversion and Manual Smoke

Convert exactly two samples first, before any bulk batch:

1. **`synthetic.svg`** — maximal attribute-form case: 12 occurrences, top-level `stroke="white"` plus a nested `<g transform>` with both `fill="white"` and `stroke="white"` on descendants. Proves nested overrides and stroke recoloring.
2. **`jetbrains.svg`** — the only CSS `style`-property carrier (R5). A pass on `synthetic.svg` says nothing about this form.

Smoke procedure, using the repository's own established mechanism from `docs/live-plasma-smoke.md` (not the System Settings GUI):

```sh
plasmawindowed org.kde.plasma.kodexbar.plasma
plasma-apply-colorscheme BreezeLight   # run with the window open
plasma-apply-colorscheme BreezeDark
```

Open the popup, select `All`, and inspect both icons at `Kirigami.Units.iconSizes.smallMedium`.

**PASS** requires all of: the mark renders as a dark glyph on the light background under BreezeLight and as a light glyph on the dark background under BreezeDark; the silhouette is identical in both runs and identical to the pre-edit geometry; the glyph is neither blank nor a solid filled block nor clipped.

**FAIL** is any of: a solid filled square or block; an invisible or blank mark in either theme; a mark that does not invert with the theme (stays white on light, or stays dark on dark); changed geometry versus pre-edit (a stroke became a fill, or a knockout closed).

**Per-icon literal-color fallback**, applied only to the failing file:

1. First re-diagnose: if a `style` declaration on the element or an ancestor still carries a literal, the failure is a P5 cascade defect, not a `currentColor` defect. Fix inside `style` and re-smoke. Likewise check for a surviving nested override (P4).
2. Only if `currentColor` genuinely does not resolve for that file's structure, set that file's literal to the documented fallback `#7F7F7F` (neutral mid-gray, chosen to sit between both Breeze panel backgrounds), re-run the same two-theme smoke to confirm legibility, record the file and the reason in the `docs/live-plasma-smoke.md` exception table, and add the file to the checker's `LITERAL_COLOR_ALLOWLIST`. This is the path the spec's *Documented literal-color fallback remains legible* scenario requires.
3. The fallback is per-file. A single failure never converts the whole batch to literal colors.

## Authored Replacement Marks

Constraints: no external fetch, no icon package, no dependency, no pixel-for-pixel reproduction of a third-party trademark. Both marks are hand-authored geometric glyphs on `viewBox="0 0 100 100"` (the repository's hand-authored convention, shared by `commandcode.svg`, `opencode.svg`, `vertexai.svg`, `synthetic.svg`, and the `openai.svg` they replace), single-tone `currentColor`, following the simplified-interpretation precedent already set by this repo's other brand icons.

Neither mark reuses the hexagon motif (taken by `vertexai.svg`), the sunburst (`openai.svg`), or the `M` chevron (`mimo.svg`).

**`codex.svg` — terminal prompt glyph.** A `>` chevron plus a detached cursor bar, in the exact stroke idiom of `commandcode.svg` (round caps and joins, `fill="none"` root). Reads instantly at 22px as "coding agent CLI" and is structurally unlike every other bundled mark.

```xml
<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M30 30L52 50L30 70" stroke="currentColor" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M58 70H74" stroke="currentColor" stroke-width="10" stroke-linecap="round"/>
</svg>
```

**`azureopenai.svg` — cloud silhouette with anchor dot.** A filled cloud built as a union of three overlapping circles plus a rounded base bar (union of solid subpaths; no arc math, no even-odd knockout, so the geometry is deterministic and cannot render inverted), with a separate dot below that distinguishes it from any generic cloud mark.

```xml
<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
  <g fill="currentColor">
    <circle cx="42" cy="40" r="19"/>
    <circle cx="66" cy="49" r="15"/>
    <circle cx="27" cy="52" r="14"/>
    <rect x="20" y="52" width="60" height="14" rx="7"/>
  </g>
  <circle cx="50" cy="80" r="7" fill="currentColor"/>
</svg>
```

`contents/icons/codex.svg` is the **applet** icon (a tri-color rounded-rect badge, referenced by `validate-package.sh`) and is a different file from `contents/icons/providers/codex.svg`. It must not be edited, reused, or confused with the provider mark.

## File Changes

| File | Action | Description |
|---|---|---|
| 23 white files: `abacus`, `amp`, `antigravity`, `augment`, `bedrock`, `claude`, `commandcode`, `copilot`, `crof`, `cursor`, `factory`, `gemini`, `grok`, `groq`, `jetbrains`, `kiro`, `ollama`, `openai`, `synthetic`, `warp`, `windsurf`, `zai`, `vertexai` (`.svg` under `contents/icons/providers/`) | Modify | Apply R1-R5 under P1-P7. |
| 6 near-black files: `alibaba`, `alibabatokenplan`, `kilo`, `manus`, `opencode`, `opencodego` | Modify | Apply R6-R9 under P1-P7. |
| `contents/icons/providers/codex.svg`, `contents/icons/providers/azureopenai.svg` | Rewrite | Replace borrowed OpenAI geometry with the authored marks above. |
| `scripts/check-provider-icons.py` | Create | Standard-library asset-invariant checker (contract below). |
| `tests/test_provider_icons.py` | Create | RED-first `unittest` contract for the checker. |
| `.github/workflows/ci.yml` | Modify | Add one step invoking the checker. |
| `docs/live-plasma-smoke.md` | Modify | Add the mandatory two-theme provider-icon smoke section and the literal-color exception table. |
| `README.md` | Modify | Document the new gate alongside the existing ones (matches the archived static-analysis precedent). |
| `openspec/changes/provider-icon-rendering/{exploration,proposal,design,tasks}.md`, `.../specs/provider-usage-display/spec.md` | Create | SDD planning artifacts. |
| `contents/code/ProviderIcons.js`, `contents/ui/ProviderRow.qml`, `contents/ui/ProviderSelector.qml`, `contents/config/**`, `metadata.json`, `contents/icons/codex.svg`, `tests/ProviderRowHarness.qml`, `tests/ProviderSelectorHarness.qml`, the 18 correct provider SVGs | Unchanged | Must be byte-identical after the change. |

Count reconciliation: 49 provider SVGs = 31 touched (23 white + 6 near-black + 2 rewritten) + 18 untouched. Matches the proposal's corrected arithmetic.

## Interfaces / Contracts

`scripts/check-provider-icons.py --repo-root <path>` exits 0 on pass, non-zero with a per-violation message on fail. Standard library only (`pathlib`, `re`, `hashlib`, `xml.etree.ElementTree`). Invariants:

1. **Coverage** — every `knownProviders` key parsed from `contents/code/ProviderIcons.js` has a matching `contents/icons/providers/<key>.svg`.
2. **No orphans** — every `.svg` in `contents/icons/providers/` maps back to a `knownProviders` key.
3. **Parseable** — each file parses as well-formed XML with root tag `{http://www.w3.org/2000/svg}svg`.
4. **No theme-defeating literal** — walking the element tree, no `fill`/`stroke` attribute and no `fill:`/`stroke:` declaration inside a `style` attribute equals a banned token (case-insensitive: `white`, `#fff`, `#ffffff`, `#111111`, `#1a1a18`, `#34322d`, `#211e1e`, `#000`, `#000000`, `black`). Skipped by tree position: any element inside a `<clipPath>` or `<mask>` subtree. Skipped by name: `LITERAL_COLOR_ALLOWLIST = {codebuff.svg, stepfun.svg, vertexai.svg}` plus any file added by the documented fallback procedure. `fill="none"` and `stroke="none"` are never banned tokens.
5. **Distinctness** — no two provider SVGs share a content hash, except the sanctioned groups `SANCTIONED_DUPLICATES = [{alibaba, alibabatokenplan}, {kimi, kimik2, moonshot}, {opencode, opencodego}]`. Any other collision fails, naming both files.

Invariant 5 is the durable guard against the exact regression that produced this change: `openai.svg`, `codex.svg`, and `azureopenai.svg` currently share hash `a35f3231d59ef004f88f598b44bc5eae`.

Scenario coverage: invariants 1-3 and 5 back *Every known provider renders a distinct, visible icon*; invariant 4 backs *No hardcoded literal color defeats theme adaptation*; invariant 5 backs *Codex and Azure OpenAI show their own brand mark*; the allowlist plus the docs exception table backs *Documented literal-color fallback remains legible*; the docs section backs *Manual Breeze Light and Dark smoke check gates acceptance*; the unchanged-paths row plus the three existing gates back *Icon-only fix preserves unrelated runtime boundaries*.

## Testing Strategy and Validation Order

Strict TDD is active. `tests/test_provider_icons.py` is written and RED before any line of `scripts/check-provider-icons.py` exists, and the invariant-4 test is written and RED before invariant 4 is enabled.

| Layer | What to test | Approach |
|---|---|---|
| Unit RED/GREEN | Each invariant in isolation | Drive the checker's pure functions over `tempfile` fixture trees: a missing key, an orphan file, malformed XML, a banned `fill` attribute, a banned `style` declaration, a banned token inside `<clipPath>` (must pass), `fill="none"` (must pass), an allowlisted file (must pass), an unsanctioned duplicate pair (must fail), a sanctioned group (must pass). |
| Integration RED/GREEN | Whole repository | Run the checker against the real tree. RED before the slice that satisfies the invariant it asserts; GREEN at that slice's tip. |
| Regression | Untouched boundaries | `./scripts/validate-package.sh`, `./scripts/lint-qml.sh`, `./scripts/run-qml-tests.sh`, `python3 -m unittest discover -s tests`, `git diff --check`, and a `git diff --stat` review confirming no path outside the File Changes table moved. |
| Manual acceptance | Visual color and legibility | The two-theme `plasmawindowed` smoke check. Mandatory gate, not optional: no CI QML runtime exists, so nothing automated can prove visual legibility. |

Invariants are enabled in the slice where they become satisfiable, so every slice tip is green rather than carrying a knowingly-red gate forward.

## Delivery Slicing

The change-owned diff is roughly 465 lines of code, config, and docs plus roughly 556 lines of SDD artifacts, so it exceeds the 400-line review budget and must be chained. Strategy: `stacked-to-main`, each branch based on the previous.

| Slice | Branch | Base | Contents | Est. diff lines |
|---|---|---|---|---|
| 0 | `slice/provider-icon-rendering-0-planning` | `main` | SDD artifacts only (exploration, proposal, spec delta, design, tasks) | ~556, documentation-only |
| 1 | `slice/provider-icon-rendering-1-marks-and-gate` | slice 0 | Authored `codex.svg` + `azureopenai.svg`; checker with invariants 1, 2, 3, 5; `tests/test_provider_icons.py`; CI step; docs smoke section; README | ~306 |
| 2 | `slice/provider-icon-rendering-2-white-recolor` | slice 1 | Two smoke samples first, then the remaining 21 white files (23 total, 57 changed lines) | ~114 |
| 3 | `slice/provider-icon-rendering-3-nearblack-and-color-gate` | slice 2 | 6 near-black files (9 changed lines) plus enabling checker invariant 4 and its RED-first test | ~45 |

Slice 1 leads with the authoring work because it is the highest-risk unit and the smallest to review carefully, and because landing it first makes invariant 5 green immediately. Slice 0 is passive documentation; if the 400-line budget is enforced literally against it, split it into 0a (exploration, proposal, spec delta — 276 lines) and 0b (design, tasks). Report the recalculated per-slice totals under `ask-on-risk` before delivery.

## Non-Goals and Boundaries

Restated verbatim in force for `sdd-apply`; drift into any of these is a defect:

- No changes to legacy or current package IDs.
- No changes to the external `codexbar` CLI boundary or the exact command `usage --provider all --format json --json-only`.
- No changes to provider selection behavior.
- No accessibility changes or regressions: accessible names, keyboard traversal, and focus order stay as-is.
- No changes to the responsive layout from `single-product-transition-responsive-ui`, unless a proven regression is directly caused by this icon fix.
- No changes to user configuration or to `contents/config/`.
- No legacy/current instance validation work mixed in.
- No live refresh, reorder, or removal work mixed in.
- No web dependencies, no emoji icons, no external icon packages or libraries, no fetched assets: every mark is a local, hand-authored or hand-adapted SVG in `contents/icons/providers/`.
- No changes to `contents/code/ProviderIcons.js`, `contents/ui/ProviderRow.qml`, or `contents/ui/ProviderSelector.qml`.
- No changes to the 18 already-correct icons.
- No QML-side recoloring (`isMask`, `ColorOverlay`) — rejected in the proposal and still rejected.

## Threat Matrix

| Boundary | Minimum adversarial cases | Applicability | Design response | Planned RED tests |
|---|---|---|---|---|
| SVG content | XXE, external entity, remote `xlink:href`, embedded `<script>` | Applicable: the checker parses untrusted-shaped XML | `xml.etree.ElementTree` resolves no external entities by default; the checker only reads attributes and never renders. Authored marks contain no scripts, entities, or hrefs. | Malformed-XML rejection test |
| Path traversal | `../` in a provider key, symlinked SVG | Applicable: keys build file paths | `ProviderIcons.key()` returns only values present in `knownProviders`; the checker resolves and confirms each path stays inside `contents/icons/providers/` | Orphan and coverage tests |
| Git repository selection | `git -C`, relative/absolute paths | N/A: the checker invokes no Git | None | None |
| Commit/push/PR state | staged, `commit -a`, tracking branch, explicit `--head` | N/A: no commit, push, or PR automation in this change | None | None |

## Migration / Rollout and Rollback

No migration, no data, no config, no installed-package or panel-instance concern. Rollback is `git revert` of the affected slice; because the diff is color-token-only for 29 files and whole-file for 2, reverting restores the exact prior visual state.

## Open Questions

None. The two-sample smoke gate resolves the `currentColor` uncertainty empirically before the bulk batch, and the documented per-icon literal-color fallback covers the failure branch without reopening the design.
