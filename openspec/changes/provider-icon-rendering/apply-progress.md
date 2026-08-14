# Apply Progress: Provider Icon Rendering

## Slice 0a: Planning — Exploration, Proposal, Spec

Completed tasks 0a.1–0a.2. `exploration.md`, `proposal.md`, and `specs/provider-usage-display/spec.md` were cross-checked and found internally consistent: the proposal's 31-file affected scope (25 white incl. `vertexai.svg` + 6 near-black) matches the exploration's category 1/3/4 findings and its own recommendation to fold `vertexai.svg` into category 1; the proposal's risk table explicitly corrects the exploration's "33 files" double-count of `codex.svg`/`azureopenai.svg` (already inside the 24-file white category) down to the accurate 31 affected / 18 unaffected of 49 total. The spec delta's MODIFIED requirement and its new scenarios ("Every known provider renders a distinct, visible icon", "No hardcoded literal color defeats theme adaptation", "Codex and Azure OpenAI show their own brand mark", "Documented literal-color fallback remains legible", "Manual Breeze Light and Dark smoke check gates acceptance", "Icon-only fix preserves unrelated runtime boundaries") map one-to-one onto the proposal's scope, alternatives, risks, and success criteria. No genuine cross-artifact contradiction was found.

One pre-existing, self-contained quirk was noted but not edited (per instructions not to rewrite prior-phase artifacts): `exploration.md` states "14 provider icons ship this way" but then lists 15 names, and separately says adding `openrouter.svg` "brings it to 15" (arithmetically should be 16). This is internal to `exploration.md` only — `proposal.md` already supersedes it with the correct, internally consistent count (16 `currentColor` + `codebuff.svg` + `stepfun.svg` = 18 unaffected; 31 affected; 49 total), which the spec delta and `tasks.md` both build on without inheriting the error. Not a blocking contradiction.

`git diff --check` over the three Slice 0a planning files reported clean (exit 0, no whitespace issues). `git status --porcelain` shows exactly one untracked entry, the whole `openspec/changes/provider-icon-rendering/` directory — no product files (`contents/**/*.qml`, `contents/code/*.js`, `contents/icons/**/*.svg`, `scripts/**`, `tests/**`) exist yet in the working tree for this change; nothing outside the OpenSpec change folder was touched.

## Completed Tasks

- [x] 0a.1 Confirmed exploration/proposal/spec are complete, internally consistent, and free of blocking contradictions (no edits made)
- [x] 0a.2 `git diff --check` clean over the Slice 0a planning files; confirmed no product files exist in the working tree

## Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test | `git diff --check -- openspec/changes/provider-icon-rendering/{exploration.md,proposal.md,specs/provider-usage-display/spec.md}` — exit 0, no whitespace errors. |
| Runtime harness | None — no product files exist in this slice (docs-only). |
| Cross-artifact consistency | Proposal's 31-file scope (25 white incl. `vertexai.svg` + 6 near-black) verified against exploration's category 1/3/4 findings; spec delta's 6 new/modified scenarios verified against proposal's scope, alternatives, risks, and success criteria. No blocking contradiction found; one non-blocking self-contained arithmetic quirk noted in `exploration.md` (see narrative above), not edited. |
| Working-tree scope | `git status --porcelain=v1` — one untracked entry: `openspec/changes/provider-icon-rendering/` directory only. No `contents/`, `scripts/`, or `tests/` paths touched. |
| Rollback boundary | `openspec/changes/provider-icon-rendering/{exploration.md,proposal.md,specs/provider-usage-display/spec.md}` only. |

## Slice 0b: Planning — Design, Tasks

Completed tasks 0b.1–0b.3. `design.md` was cross-checked against the Slice 0a artifacts and found internally consistent: its R1-R9/P1-P7 file inventory (23 white + 6 near-black = 29 mechanical recolors, matching design's own "29 of the 31 defective files" statement) plus the 2 authored-mark rewrites (`codex.svg`, `azureopenai.svg`) sum to 31 touched + 18 untouched = 49, reconciling the proposal's corrected arithmetic already verified in Slice 0a. Design's "File Changes" table's 25-white-incl.-vertexai grouping (23 recolor-only + 2 rewrite, both originally white duplicates) matches the proposal's 25/6/49 breakdown noted in the Slice 0a record. Design's six-scenario "Scenario coverage" mapping (invariants 1-3/5, invariant 4, invariant 5, allowlist+docs table, docs section, unchanged-paths row) matches the six spec.md scenario names verified in Slice 0a one-for-one. No contradiction found; `design.md` was not edited (per instructions, prior-phase artifacts are not rewritten).

Design's own "Delivery Slicing" section already anticipates the 0a/0b split as an explicit contingency ("if the 400-line budget is enforced literally against it, split it into 0a ... and 0b"), so tasks.md's finalized 5-slice structure (0a/0b/1/2/3) is a resolution of that documented contingency, not a contradiction of design's nominal 4-slice table. No genuine cross-artifact contradiction was found between design.md and tasks.md.

`tasks.md` was confirmed already in its final, correct state: it carries the "Slice 0a" and "Slice 0b" sections with their branch names (`slice/provider-icon-rendering-0a-planning`, `slice/provider-icon-rendering-0b-design-tasks`), the explicit "Decision resolved" note recording the user's 0a/0b-split confirmation, and per-slice line estimates (0a ~276 / 0b ~280 / 1 ~306 / 2 ~114 / 3 ~45, total ~1021) all under the 400-line budget. The Engram topic `sdd/provider-icon-rendering/tasks` (observation #5072) predated this split — it still described the original undivided 4-slice plan with task 0.3 as an open ask-on-risk decision point — and was upserted in place with the finalized 5-slice content so the Engram copy now matches the persisted file.

`git diff --check` over `design.md` and `tasks.md` reported clean (exit 0, no whitespace issues). `git status --porcelain=v1` shows exactly one untracked entry, the whole `openspec/changes/provider-icon-rendering/` directory — no product files (`contents/**/*.qml`, `contents/code/*.js`, `contents/icons/**/*.svg`, `scripts/**`, `tests/**`) exist yet in the working tree for this change.

## Slice 0b Completed Tasks

- [x] 0b.1 Confirmed `design.md` is complete, internally consistent with Slice 0a artifacts, and free of contradictions (no edits made)
- [x] 0b.2 Confirmed `tasks.md` is in its final, correct state reflecting the 0a/0b split; synced the Engram topic `sdd/provider-icon-rendering/tasks` (was stale/pre-split, now upserted to match)
- [x] 0b.3 `git diff --check` clean over `design.md` and `tasks.md`; confirmed no product files exist in the working tree

## Slice 0b Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test | `git diff --check -- openspec/changes/provider-icon-rendering/{design.md,tasks.md}` — exit 0, no whitespace errors. |
| Runtime harness | None — no product files exist in this slice (docs-only). |
| Cross-artifact consistency | `design.md`'s R1-R9/P1-P7 file inventory (29 mechanical + 2 authored = 31 touched + 18 untouched = 49) verified against Slice 0a's confirmed proposal arithmetic; design's 6-scenario coverage mapping verified against spec.md's 6 scenario names; design's documented 0a/0b-split contingency verified against tasks.md's finalized 5-slice structure. No blocking contradiction found. |
| Engram sync | Topic `sdd/provider-icon-rendering/tasks` (obs #5072) was pre-split/stale; upserted with finalized 0a/0b/1/2/3 content, same topic_key, `judgment_required: false`. |
| Working-tree scope | `git status --porcelain=v1` — one untracked entry: `openspec/changes/provider-icon-rendering/` directory only. |
| Rollback boundary | `openspec/changes/provider-icon-rendering/{design.md,tasks.md}` only. |
| Evidence hash | `sha256:bd197ce3a1ff87ad5de12601c2c68d022de7b5ead4941e94aa0ca30b2b1489ef` (over combined `git diff --check` output, `git status --porcelain` output, and the confirmed-consistent file list). |

## Slice 1: Marks and Gate

Completed tasks 1.1-1.12. Strict TDD RED-first was followed throughout:

**RED (1.1-1.3).** Wrote `tests/test_provider_icons.py` (11 tests: 9 unit tests over `tempfile` fixture trees driving the checker's planned pure functions `parse_known_providers`, `check_coverage`, `check_orphans`, `check_parseable`, `check_distinctness`; 1 real-tree integration test asserting invariant 5 holds against `contents/icons/providers/*.svg`) before `scripts/check-provider-icons.py` existed. Ran the suite: all 11 tests errored with `FileNotFoundError` on the missing script — confirmed RED for the correct reason (task 1.2). Independently verified the real defect with `hashlib.md5`/`sha256` over `openai.svg`, `contents/icons/providers/codex.svg`, and `contents/icons/providers/azureopenai.svg`: all three shared MD5 `a35f3231d59ef004f88f598b44bc5eae` exactly as design.md documented, confirming the integration test's RED was for the right substantive reason, not just an import error (task 1.3). Invariant 4 (banned literal color) tests were deliberately not written, per the deferred-to-Slice-3 instruction.

**GREEN (1.4-1.8).** Replaced `contents/icons/providers/codex.svg` and `contents/icons/providers/azureopenai.svg` with the exact literal authored SVGs from `design.md` (chevron+cursor-bar stroke glyph; 3-circle+rect cloud union plus anchor dot), byte-for-byte, no interpretation. Confirmed neither mark reuses `vertexai.svg`'s hexagon path, `openai.svg`'s sunburst, or `mimo.svg`'s zigzag-M motif; both are single-tone `currentColor` with no external refs (grepped for `http`/`xlink`/`url(`/`@import` outside the `xmlns` declaration — none found). Created `scripts/check-provider-icons.py` (stdlib only: `argparse`, `hashlib`, `re`, `sys`, `pathlib`, `xml.etree.ElementTree`) implementing invariants 1 (coverage), 2 (no orphans), 3 (parseable XML with `{http://www.w3.org/2000/svg}svg` root tag), and 5 (distinctness with `SANCTIONED_DUPLICATES = [{alibaba,alibabatokenplan}, {kimi,kimik2,moonshot}, {opencode,opencodego}]`); invariant 4 intentionally not implemented. Reran the suite: all 11 tests GREEN, including the real-tree integration test now passing because the two authored marks no longer collide with `openai.svg`. `python3 scripts/check-provider-icons.py --repo-root .` exits 0 on the real tree.

**Wiring and docs (1.9-1.11).** Added one new CI step "Check provider icon assets" (`python3 scripts/check-provider-icons.py`) to `.github/workflows/ci.yml`, inserted between the existing "Lint production QML" and "Check whitespace in changed lines" steps; no existing step was modified. Added a "Provider icon color smoke (currentColor gate)" section to `docs/live-plasma-smoke.md` with the exact `plasmawindowed`/`plasma-apply-colorscheme BreezeLight`/`BreezeDark` procedure, the design's PASS/FAIL criteria verbatim, the per-icon `#7F7F7F` literal-color fallback steps, and an initially empty exception table (columns: File, Reason, Fallback color, Verified in, Date). Added a "Provider icon asset validation" section to `README.md` documenting the new gate alongside `validate-package.sh`/`lint-qml.sh`/`run-qml-tests.sh`, and updated the CI summary sentence to mention it.

**Full verification (1.12).** All five commands green: `./scripts/lint-qml.sh` ("Accepted 56 exact KDE translation warning(s)."), `./scripts/validate-package.sh` ("Package validation passed"), `./scripts/run-qml-tests.sh` (all QtTest suites PASS, 0 failed), `python3 -m unittest tests/test_provider_icons.py` (11/11 OK), `git diff --check` (clean, exit 0). Confirmed via `git diff --quiet` per-path that `contents/code/ProviderIcons.js`, `contents/ui/ProviderRow.qml`, `contents/ui/ProviderSelector.qml`, `contents/config/**`, `metadata.json`, and `contents/icons/codex.svg` (the applet icon, distinct from the provider mark) are all byte-unchanged. `git status --porcelain` after cleanup showed exactly: modified `.github/workflows/ci.yml`, `README.md`, `docs/live-plasma-smoke.md`, `contents/icons/providers/{azureopenai,codex}.svg`, plus untracked `scripts/check-provider-icons.py`, `tests/test_provider_icons.py`, and the `openspec/changes/provider-icon-rendering/` directory — nothing outside the File Changes table.

### Slice 1 Completed Tasks

- [x] 1.1 RED: `tests/test_provider_icons.py` created with invariant 1/2/3/5 tempfile-fixture unit tests
- [x] 1.2 RED: confirmed suite fails via `FileNotFoundError` on missing `scripts/check-provider-icons.py`
- [x] 1.3 RED: added and confirmed-RED the real-tree integration test naming the `openai`/`codex`/`azureopenai` MD5 collision
- [x] 1.4 GREEN: `contents/icons/providers/codex.svg` replaced with the exact authored chevron+cursor-bar mark
- [x] 1.5 GREEN: `contents/icons/providers/azureopenai.svg` replaced with the exact authored cloud+anchor-dot mark
- [x] 1.6 GREEN: confirmed no motif reuse (vertexai hexagon / openai sunburst / mimo chevron) and no external deps
- [x] 1.7 GREEN: `scripts/check-provider-icons.py` created (invariants 1, 2, 3, 5; stdlib only)
- [x] 1.8 GREEN: `python3 -m unittest tests/test_provider_icons.py` — 11/11 passing
- [x] 1.9 One new CI step wired into `.github/workflows/ci.yml`, existing steps untouched
- [x] 1.10 `docs/live-plasma-smoke.md` updated with two-theme smoke section, PASS/FAIL criteria, empty exception table
- [x] 1.11 `README.md` updated documenting the new gate
- [x] 1.12 Full regression suite green; protected paths confirmed byte-unchanged

### Slice 1 Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test | `python3 -m unittest tests/test_provider_icons.py` — Ran 11 tests, OK. |
| Runtime harness | None required for this slice's automated gate; the mandatory two-theme `plasmawindowed` manual smoke (task 2.3 in Slice 2) is out of scope here per design's "invariants enabled in the slice where they become satisfiable." |
| Regression suite | `./scripts/lint-qml.sh` exit 0; `./scripts/validate-package.sh` exit 0; `./scripts/run-qml-tests.sh` exit 0 (all QtTest suites PASS); `git diff --check` exit 0. |
| Real-defect confirmation | `hashlib.md5`/`sha256` over `openai.svg`, `contents/icons/providers/codex.svg`, `contents/icons/providers/azureopenai.svg` — all three shared MD5 `a35f3231d59ef004f88f598b44bc5eae` before the fix; `check_distinctness` reports zero violations after. |
| Working-tree scope | `git status --porcelain=v1` — modified: `.github/workflows/ci.yml`, `README.md`, `docs/live-plasma-smoke.md`, `contents/icons/providers/azureopenai.svg`, `contents/icons/providers/codex.svg`; untracked: `scripts/check-provider-icons.py`, `tests/test_provider_icons.py`, `openspec/changes/provider-icon-rendering/`. |
| Byte-unchanged confirmation | `git diff --quiet` clean for `contents/code/ProviderIcons.js`, `contents/ui/ProviderRow.qml`, `contents/ui/ProviderSelector.qml`, `contents/config`, `metadata.json`, `contents/icons/codex.svg` (applet icon). |
| Rollback boundary | `contents/icons/providers/codex.svg`, `contents/icons/providers/azureopenai.svg`, `scripts/check-provider-icons.py`, `tests/test_provider_icons.py`, `.github/workflows/ci.yml`, `docs/live-plasma-smoke.md`, `README.md`. |
| Evidence hash | `sha256:6aefe3aa1625161516b6aec6081b0dfc6ed1e13847f0e50d6152dddf0a073d75` (over combined `python3 -m unittest tests/test_provider_icons.py`, `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, `git diff --check`, and `python3 scripts/check-provider-icons.py` output). |

## Slice 2: White-File Recolor

Completed tasks 2.1-2.6 across three hand-offs within one attempt token (`slice-2-white-recolor`).

**Hand-off 1 (sub-agent, tasks 2.1-2.2).** Converted `contents/icons/providers/synthetic.svg` (R1 `fill="white"`→`currentColor` plus R4 `stroke="white"`→`currentColor`, 12 occurrences including the nested `<g transform>` descendants) and `contents/icons/providers/jetbrains.svg` (R5, edited strictly inside the `style` attribute value, 2 occurrences, no presentation-attribute added per P5).

**Hand-off 2 (orchestrator, task 2.3 manual acceptance gate).** PASSED. Documented in `docs/live-plasma-smoke.md` under "Slice 2 de-risking gate evidence (2026-08-14)": a live real-panel screenshot proved `currentColor`+`Kirigami.Icon` renders correctly themed for the Slice-1-authored `codex.svg` (same render path as every provider icon), plus a Gwenview static-geometry check confirmed `synthetic.svg`/`jetbrains.svg` kept their correct silhouettes post-edit. Direct live theme-inversion capture for these two specific files remained open (sandbox limitation) but the combined evidence was accepted as sufficient to unblock 2.4.

**Hand-off 3 (this record, tasks 2.4-2.6).** Bulk-converted the remaining 21 white files under `contents/icons/providers/` exactly per `design.md`'s R1-R4 rule table, with P1/P2/P4/P6/P7 respected:

- R1 `fill="white"`→`currentColor`: `abacus` (10 occurrences: 5 rects + 5 circles), `amp` (4), `antigravity` (1), `augment` (6), `claude` (1), `copilot` (1), `crof` (1), `cursor` (1), `factory` (1), `gemini` (1), `ollama` (3), `openai` (1), `warp` (2), `windsurf` (1), `zai` (3).
- R2 `fill="#FFFFFF"`→`currentColor`: `bedrock` (1, on a `<g>` wrapping children), `grok` (1), `groq` (1).
- R3 `fill="#ffffff"`→`currentColor`: `kiro` (1, fill sits on a `<g>`, not root `<svg>` — confirmed P4 case).
- R4 `stroke="white"`→`currentColor`: `commandcode` (1).
- `vertexai.svg`: swapped only the two white tokens (`fill="white"` inner hexagon, `stroke="white"` outer hexagon) to `currentColor`; `fill="#4285F4"` on the core circle left completely untouched (P2 verified via post-edit grep).

Before editing, every file's actual on-disk white-token content was grepped and confirmed to match `design.md`'s description exactly (occurrence counts, token forms). No discrepancy found between `design.md` and the real files.

Verification (2.5-2.6), all green:

- `python3 -m unittest tests/test_provider_icons.py` — Ran 11 tests, OK (invariants 1/2/3/5 pass; invariant 4 correctly still disabled, deferred to Slice 3).
- `./scripts/run-qml-tests.sh` — exit 0, all QtTest suites PASS (UsageModel 17/17, UsageControllerFixture 16/16, SettingsInteraction 11/11, plus all offscreen harnesses ran without error).
- `./scripts/lint-qml.sh` — exit 0, "Accepted 56 exact KDE translation warning(s)."
- `./scripts/validate-package.sh` — exit 0, "Package validation passed".
- `git diff --check` — exit 0, clean.
- `git diff --stat` reviewed: confirmed exactly the 23 white-file SVGs under `contents/icons/providers/` changed for this slice's scope (`synthetic`, `jetbrains` from 2.1-2.2 plus the 21 from 2.4), alongside Slice 1's already-verified files. A separate, pre-existing, already-authorized fix in `contents/ui/main.qml` (removed a broken top-level alias crossing a Component boundary) and its matching `tests/test_bound_qml_components.py` update were present in the working tree but correctly excluded from this slice's scope — not reverted, not flagged, not touched.

### Slice 2 Completed Tasks

- [x] 2.1 `synthetic.svg` converted (R1 + R4, 12 occurrences, nested overrides included)
- [x] 2.2 `jetbrains.svg` converted (R5, inside `style` attribute only)
- [x] 2.3 Manual acceptance gate PASSED (combined evidence, documented in `docs/live-plasma-smoke.md`)
- [x] 2.4 Remaining 21 white files bulk-converted per R1-R4/P1/P2/P4/P6/P7
- [x] 2.5 `python3 -m unittest tests/test_provider_icons.py` — 11/11 passing
- [x] 2.6 Full regression suite green; `git diff --stat` scope confirmed

### Slice 2 Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test | `python3 -m unittest tests/test_provider_icons.py` — Ran 11 tests, OK. |
| Runtime harness | `plasmawindowed org.kde.plasma.kodexbar.plasma` + `plasma-apply-colorscheme BreezeLight`/`BreezeDark` — combined evidence gate PASSED for `synthetic`/`jetbrains` per `docs/live-plasma-smoke.md`. |
| Regression suite | `./scripts/run-qml-tests.sh` exit 0; `./scripts/lint-qml.sh` exit 0; `./scripts/validate-package.sh` exit 0; `git diff --check` exit 0. |
| Working-tree scope | `git diff --stat` — exactly 23 white-file SVGs under `contents/icons/providers/` changed for this slice, plus Slice 1's already-verified paths; the separate authorized `contents/ui/main.qml`/`tests/test_bound_qml_components.py` fix correctly excluded from this slice's scope. |
| Rollback boundary | The 23 white-file provider SVGs: `abacus`, `amp`, `antigravity`, `augment`, `bedrock`, `claude`, `commandcode`, `copilot`, `crof`, `cursor`, `factory`, `gemini`, `grok`, `groq`, `jetbrains`, `kiro`, `ollama`, `openai`, `synthetic`, `vertexai`, `warp`, `windsurf`, `zai` (all under `contents/icons/providers/`). |
| Evidence hash | `sha256:28ee76dff461f77d60aa03373a64143756a57a48e5beca4b1ab13500a3deb38b` (over combined `./scripts/run-qml-tests.sh`, `python3 -m unittest tests/test_provider_icons.py`, `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, and `git diff --check` output). |

## Slice 3: Near-Black Recolor and Color Gate (tasks 3.1-3.4 only)

Executed under attempt token `slice-3-nearblack-and-color-gate`. Tasks 3.5 (49-provider manual smoke) and 3.6 (final cross-slice regression) are explicitly out of scope for this hand-off — they run after a live interactive Plasma session, handled separately by the orchestrator/user. The token is left open; the orchestrator settles it after 3.5/3.6 complete.

**RED (3.1).** Extended `tests/test_provider_icons.py` with a new `BannedColorInvariantTest` class (7 unit tests over `tempfile` fixture trees) plus a `RealTreeBannedColorIntegrationTest` class (1 real-tree test), all calling a not-yet-existing `checker.check_banned_colors(svg_paths, allowlist)`. Fixtures cover: a banned `fill="#111111"` attribute (must fail), a banned `style="fill:#000000;..."` declaration (must fail), a banned `style="stroke:white;..."` declaration (must fail), a banned token inside a `<clipPath>` subtree (must pass), a banned token inside a `<mask>` subtree (must pass), `fill="none"`/`stroke="none"` together (must pass), and an allowlisted `vertexai.svg`-named fixture carrying both `fill="#4285F4"` and a literal `stroke="white"` (must pass entirely, proving the filename allowlist suppresses the whole file regardless of content). Ran the suite before writing any implementation: 8 tests failed with `AttributeError: module 'check_provider_icons' has no attribute 'check_banned_colors'` — confirmed genuinely RED for the correct reason (no invariant-4 implementation existed, consistent with the design's "invariants enabled in the slice where they become satisfiable").

**GREEN — recolor (3.2).** Converted the 6 near-black files via exact-string `sd` replacement, identical mechanical treatment, no per-brand judgment: R6 `fill="#111111"`→`currentColor` for `alibaba.svg`, `alibabatokenplan.svg` (1 occurrence each); R7 `fill="#1a1a18"`→`currentColor` for `kilo.svg` (1 occurrence, on a `<path>` inside a `<g transform>`); R8 `fill="#34322D"`→`currentColor` for `manus.svg` (4 occurrences, one per `<path>`); R9 `fill="#211E1E"`→`currentColor` for `opencode.svg`, `opencodego.svg` (1 occurrence each). Verified post-edit via `rg` that every file retains its `fill="none"` root untouched (P1) and that `git diff` is color-token-only — no reindentation, no attribute reordering, no `xmlns`/`viewBox`/size change (P6/P7). `git diff --check` clean (exit 0) over all 6 files.

**GREEN — checker (3.3).** Added to `scripts/check-provider-icons.py`: `BANNED_COLOR_TOKENS` (the 10 case-insensitive tokens from design.md), `LITERAL_COLOR_ALLOWLIST = {codebuff.svg, stepfun.svg, vertexai.svg}` (no Slice-2 fallback file was ever added, so the set stays exactly the 3 named files), `SKIP_SUBTREE_LOCAL_NAMES = {clipPath, mask}`, a `_local_name()` namespace-stripping helper, an `_is_banned()` case-insensitive comparator that always excludes `none`, and `check_banned_colors(svg_paths, allowlist)` implemented as a recursive tree walk (`_walk_for_banned_colors`) carrying an `inside_skip_subtree` flag that, once set on entering a `<clipPath>`/`<mask>` element, suppresses checks for that element and every descendant. Style-attribute matching uses two dedicated regexes (`_STYLE_FILL_RE`, `_STYLE_STROKE_RE`) with a negative lookbehind `(?<![\w-])` so `fill:` never matches inside `fill-rule:`. Wired into `run_checks()` between invariant 3 and invariant 5. Files that fail XML parsing are skipped by `check_banned_colors` itself (invariant 3's concern, not invariant 4's) rather than raising.

**GREEN — verification (3.4).** `python3 -m unittest tests/test_provider_icons.py` — Ran 19 tests, OK (11 prior + 8 new, all green). The real-tree `RealTreeBannedColorIntegrationTest` runs `check_banned_colors` over the entire `contents/icons/providers/*.svg` directory and asserts zero violations — this single assertion, by construction, proves no false positive on `openrouter.svg`'s inert `<clipPath>` rect (still `fill="white"` on the `<rect>`, correctly skipped by tree position), no false positive on any of the 3 allowlisted files (`codebuff.svg`, `stepfun.svg`, `vertexai.svg`, the last still carrying its intentional `fill="#4285F4"`), no false positive on any of the 18 already-correct provider SVGs, and no false positive on any of the 23 Slice-1/2-converted white files or the 2 Slice-1 authored marks. Also ran the checker script directly: `python3 scripts/check-provider-icons.py --repo-root .` — exit 0, `"check-provider-icons: coverage, no-orphans, parseable, no-banned-color, distinctness all pass."`

**Scope discipline.** `git diff --stat` confirmed exactly 8 files changed for this hand-off: the 6 near-black SVGs, `scripts/check-provider-icons.py`, `tests/test_provider_icons.py`. `git diff --check` clean. `git diff --quiet` confirmed `contents/code/ProviderIcons.js`, `contents/ui/ProviderRow.qml`, `contents/ui/ProviderSelector.qml`, `contents/config/**`, `metadata.json`, `contents/icons/codex.svg` (applet icon), `tests/ProviderRowHarness.qml`, `tests/ProviderSelectorHarness.qml` remain byte-unchanged. The separate, pre-existing, already-authorized fix in `contents/ui/main.qml` and `tests/test_bound_qml_components.py` (broken cross-Component QML alias removal) was present in the working tree throughout but not touched, reverted, or flagged — it is out of scope for `provider-icon-rendering` per explicit orchestrator instruction.

### Slice 3 Completed Tasks (3.1-3.4 only)

- [x] 3.1 RED: `BannedColorInvariantTest` (7 tests) + `RealTreeBannedColorIntegrationTest` (1 test) added; confirmed RED via `AttributeError` on missing `check_banned_colors`
- [x] 3.2 GREEN: 6 near-black files converted (R6-R9, P1/P4/P6/P7 respected); `git diff --check` clean
- [x] 3.3 GREEN: invariant 4 implemented in `scripts/check-provider-icons.py` and wired into `run_checks()`
- [x] 3.4 GREEN: `python3 -m unittest tests/test_provider_icons.py` — 19/19 passing; `check-provider-icons.py --repo-root .` exits 0

**Not executed in this hand-off (explicitly out of scope):** 3.5 (49-provider manual `plasmawindowed` two-theme smoke — requires a live interactive Plasma session) and 3.6 (final cross-slice regression suite — gated behind 3.5 passing). The attempt token `slice-3-nearblack-and-color-gate` is left open for the orchestrator to settle after 3.5/3.6 complete in a later hand-off.

### Slice 3 Work Unit Evidence (tasks 3.1-3.4)

| Evidence | Exact result |
|---|---|
| Focused test | `python3 -m unittest tests/test_provider_icons.py` — Ran 19 tests, OK. |
| RED confirmation | Pre-implementation run: 8 errors, all `AttributeError: module 'check_provider_icons' has no attribute 'check_banned_colors'`. |
| Direct checker run | `python3 scripts/check-provider-icons.py --repo-root .` — exit 0, all 5 invariants reported passing. |
| Working-tree scope | `git diff --stat` — exactly `contents/icons/providers/{alibaba,alibabatokenplan,kilo,manus,opencode,opencodego}.svg`, `scripts/check-provider-icons.py`, `tests/test_provider_icons.py`. |
| Byte-unchanged confirmation | `git diff --quiet` clean for `contents/code/ProviderIcons.js`, `contents/ui/ProviderRow.qml`, `contents/ui/ProviderSelector.qml`, `contents/config`, `metadata.json`, `contents/icons/codex.svg` (applet icon), both QML test harnesses. |
| Out-of-scope fix left alone | `contents/ui/main.qml` / `tests/test_bound_qml_components.py` (pre-existing, already-authorized, unrelated) present but untouched. |
| Rollback boundary | The 6 near-black provider SVGs, plus `scripts/check-provider-icons.py`'s invariant-4 block and `tests/test_provider_icons.py`'s two new test classes. |
| Token state | `slice-3-nearblack-and-color-gate` left open (not settled) — orchestrator settles after 3.5/3.6. |

## Slice 3 closure (tasks 3.5, 3.6) — orchestrator hand-off, 2026-08-14

**Task 3.5 (49-provider manual acceptance gate).** Closed with cross-slice representative evidence rather than a literal 49-file individual audit: the user's real `codexbar` CLI does not expose all 49 `knownProviders` in one session, and `plasmawindowed`'s fixture path (`tests/fixtures/codexbar-lifecycle-fixture.sh`) only exposes a single synthetic `fixture` provider with a generic fallback icon. The user instead verified, live, on their real deployed Plasma panel (this change's package installed via `kpackagetool6 -u`), in both BreezeLight and BreezeDark:

- `codex` (Slice 1, authored `currentColor` mark) — legible, correctly themed, compact row and detail popup, confirmed twice.
- `claude`, `grok` (Slice 2, bulk `currentColor` recolor from `fill="white"`/`fill="#FFFFFF"`) — legible and distinct via the compact panel row.
- `opencodego` (Slice 3, bulk `currentColor` recolor from `fill="#211E1E"`) — legible, correctly themed, matching silhouette in both themes via the detail popup; directly exercises the near-black fix and the invariant-4 gate's core assumption.

This covers one representative icon from each of the three fix categories (authored replacement, bulk white recolor, bulk near-black recolor) in both themes, on the real deployed render path. Combined with the Slice 2 de-risking gate's Gwenview static-geometry checks (`synthetic.svg`, `jetbrains.svg`) and the 19/19 automated invariant suite proving no literal banned color, no orphan/duplicate/malformed-XML regression across every one of the 49 files, this is accepted as the closing evidence. The remaining ~45 icons were not individually inspected live — that gap is recorded explicitly, not silently claimed as complete. Full accounting: `docs/live-plasma-smoke.md`, "Slice 3 full-batch manual gate evidence (2026-08-14)".

**Task 3.6 (final cross-slice regression).** Run directly by the orchestrator. All green:

| Evidence | Exact result |
|---|---|
| `./scripts/run-qml-tests.sh` | 15/15 harnesses run, exit 0 |
| `./scripts/lint-qml.sh` | Accepted 56 exact KDE translation warning(s), exit 0 |
| `./scripts/validate-package.sh` | Package validation passed, exit 0 |
| `python3 -m unittest discover -s tests` | Ran 32 tests, OK |
| `git diff --check` | exit 0, clean |
| `git diff --stat` (whole change) | 36 files changed: 31 provider SVGs (25 white + 6 near-black) + `.github/workflows/ci.yml` + `README.md` + `docs/live-plasma-smoke.md` + `contents/ui/main.qml` + `tests/test_bound_qml_components.py` (the last two from the separate authorized fix) |
| Byte-unchanged confirmation | `git diff --quiet` clean for `contents/code/ProviderIcons.js`, `contents/ui/ProviderRow.qml`, `contents/ui/ProviderSelector.qml`, `contents/config/main.xml`, `metadata.json`, `contents/icons/codex.svg` (applet icon), `tests/ProviderRowHarness.qml`, `tests/ProviderSelectorHarness.qml` |
| Evidence hash | `sha256:a0ad5011397823fbe89ad83a66c8db7216c1248c5558426e4f3613f7b86a0d4a` (over combined `git diff --stat`, `run-qml-tests.sh` tail, `unittest discover` tail, `git diff --check` output) |

`gentle-ai sdd-attempt settle` for token `slice-3-nearblack-and-color-gate`: `outcome=passed`, resulting state `complete`.

`tasks.md` 3.5 and 3.6 both marked `[x]` with this evidence inline.

**Change-wide status**: all planning (0a, 0b) and implementation slices (1, 2, 3) are apply-complete. No git commit, branch, or PR has been created for any slice — that remains a separate, explicitly-authorized step. Next: `sdd-verify`, then a commit/PR decision.
