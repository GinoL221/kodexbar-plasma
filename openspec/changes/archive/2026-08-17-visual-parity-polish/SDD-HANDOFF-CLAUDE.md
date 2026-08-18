# SDD Handoff — visual-parity-polish (for Claude closeout)

**Date:** 2026-08-17
**Branch:** `visual-parity-polish/pr6-overview-and-icon-fix` (stacked on PR1–PR5 commits)
**Working tree:** large uncommitted polish on top of PR5 tip — **do not commit without explicit user OK**
**Goal of this doc:** let Claude finish SDD (sync artifacts → verify → archive / PR) without inventing UI that was already rejected live.

---

## 1. What you must do (closeout checklist)

1. Read this file + updated `design.md` (D21–D30) + `tasks.md` Phase 8 + delta `specs/provider-usage-display/spec.md`.
2. Confirm `./scripts/run-qml-tests.sh` is green (already was at handoff).
3. Optionally run icon checker: `python3 -m unittest tests.test_provider_icons`.
4. Align any remaining stale sentences in design Data Flow / Open Questions with D21–D30.
5. Phase 7 (goldens + smoke checklist) is still open unless user defers goldens.
6. Propose commit split / PR only when user asks — **do not commit by default**.
7. Do **not** reintroduce: percent-in-tab-text, native QQC2 TabBar for providers, ErrorSummary in popup, email/version/org in detail header, credits when 0, Overview 2-line title/percent layout, fixed popup height = max.

---

## 2. Boundary (non-negotiable)

| Allowed | Forbidden |
|---------|-----------|
| Plasma 6 / Kirigami / Breeze only | Glass macOS, fixed brand colors, web CSS |
| `Kirigami.Units` / `Kirigami.Theme` | Hardcoded hex except D19 allowlist SVGs |
| Cost only via existing `codexbar cost` | Price math in QML |
| Usage CLI unchanged | Auth / Add Account / Quit / redeem |
| Plasmoid popup | Tray-app conversion |

**Usage argv (unchanged):**
`usage --provider all --format json --json-only`

---

## 3. Final UI state (source of truth = code + live smoke)

### 3.1 Tabs (`ProviderSelector.qml`) — **custom strip, not QQC2.TabBar**

- Vertical chip: **icon (medium)** / **name only** / **thin underline bar**.
- Percent is **not** in visible tab text. Finite representative % → underline bar + `Accessible.name` only (D6 data source kept: `selectRepresentative` + `preferredWindowKey`).
- Overview tab: `view-grid` + "Overview".
- Overflow: **side arrows** (`go-previous` / `go-next`), one-tab step + short animation; selection ensure-visible is instant.
- No horizontal scrollbar under tabs.
- Icons: `Kirigami.Icon { isMask: true; color: Theme… }` (theme-adaptive). Stroke-only SVG fallback D19 still applies for codex/commandcode/mimo (`#9a9a9a`).
- Underline bar insets: `sideInset` / `nameGap` (left/right/top margin under name).
- Display names via `ProviderIcons.displayName` (e.g. `opencodego` → **OpenCode Go**).

**Why not TabButton contentItem:** Breeze paints icon+text in `background` (`contentItem: null`). Override doubles paint (D18 lesson). Custom strip is the real fix.

### 3.2 Overview body (`ProviderRow` summary)

- **2-column card:** left `summaryProviderIcon` (medium, VCenter); right name (bold) + 0–N thin bars.
- Each bar = **single line:** `Session | ████ | 30% used` (not title/percent above bar).
- Window set = `UsageModel.selectOverviewWindows`: **all finite** among Session, Weekly, Monthly **in that order** (up to 3).
  - Example: OpenCode Go with all three finite → **three bars**.
  - Supersedes old D10 exclusive “Session+Weekly OR Monthly-only”.
- No email/org/pace/credits/cost/reset in Overview.
- Card separators between providers.

### 3.3 Detail body (selected provider)

- Header chrome: **name (bold large)** + **Updated:** + **login badge** right.
  **Hidden from primary chrome:** version, email, organization (nodes remain `visible: false` for objectName harnesses; values still validated).
- Credits line only if `credits.remaining` is a finite number **> 0**.
- Windows: title (DemiBold) → thin full-width bar → band `% used` | reset (verbatim `resetDescription` or `Reset: {resetsAt}`).
- Pace under matching window; Cost section when snapshot exists; ResetCredits when count > 0; ProviderDetails disclosure unchanged.
- No Add Account / Quit / Settings / About in popup.

### 3.4 Popup chrome (`main.qml`)

- Outer margin + `bodyInset` on provider content.
- Height: **content-driven** with `minPopupHeight` / `maxPopupHeight` (not fixed max always).
- Vertical scroll: **overlay** `ScrollBar` (no reserved grey gutter).
- Refresh: text+icon **below** scroll.
- StatusFooter: phase only; loading text = **Loading usage…**
- Body phase label: **noData / error only** (loading does not grow the scroll body).
- **ErrorSummary not mounted** in popup (CLI returns dozens of unsupported providers on Linux). Component + `ErrorSummaryHarness` remain for unit coverage / future debug surfaces. `committedErrors` still populated on controller.

### 3.5 Progress bars

- Theme thin bars (`Rectangle` track + fill with `Kirigami.Theme`), not fat QQC2.ProgressBar chrome.
- Overview: `summaryUsageProgressBar`; detail host: `detailUsageProgressBar` inside fillWidth host.
- **Never** `width: root.width` as a Layout child of ColumnLayout (zero-size circular bind).

---

## 4. Architecture decisions — final map

| ID | Status | One-line truth |
|----|--------|----------------|
| D1–D5, D7–D9, D11, D13 | Still active (with later refinements) | Base structure |
| D6 | **Refined** | Representative % still from `selectRepresentative`; **visual** is underline bar + a11y, **not** tab text |
| D10 | **Superseded by D21** | All finite Session/Weekly/Monthly, not exclusive Monthly fallback |
| D12 | **Superseded by D22/D23** | Overview is 2-col card Loader; detail header is name+updated+badge only |
| D14–D15 | **Superseded by D24** | Overview = single-line label\|bar\|%; not 2-line title/percent |
| D16 | Dead | contentItem TabButton override |
| D18 | Historical | Revert D16; then **D25** left native TabBar entirely |
| D19 | Active | Literal `#9a9a9a` on 3 stroke SVGs |
| D20 | Refined | Fixed maxWidth still relevant for summary labels; layout evolved |
| **D21** | **Final** | `selectOverviewWindows` = all finite primary/secondary/tertiary in order |
| **D22** | **Final** | Overview card = icon column \| name + bars (Loader summary vs detail) |
| **D23** | **Final** | Detail header hides version/email/org; credits only if > 0 |
| **D24** | **Final** | Summary single-line bars; thin theme bars; detail title→bar→band |
| **D25** | **Final** | Custom tab strip (ItemDelegate chips + arrows + underline) |
| **D26** | **Final** | `ProviderIcons.displayName` map + capitalize fallback |
| **D27** | **Final** | Popup: content height, bodyInset, overlay v-scroll, loading in footer only |
| **D28** | **Final** | ErrorSummary omitted from popup UI |
| **D29** | **Final** | Tab underline insets (`sideInset`/`nameGap`); tab icons medium |
| **D30** | **Final** | Tests: ProviderIconsHarness + extended row/selector harnesses |

Full prose for D21–D30 is in `design.md` section **Post-PR5 live polish**.

---

## 5. Files changed (uncommitted at handoff)

### Production
- `contents/code/UsageModel.js` — D21 `selectOverviewWindows`
- `contents/code/ProviderIcons.js` — D26 `displayName` + map
- `contents/ui/ProviderSelector.qml` — D25/D29 custom tabs
- `contents/ui/ProviderRow.qml` — D22/D23 overview card + credits gate
- `contents/ui/ProviderHeader.qml` — D23 clean detail header
- `contents/ui/UsageWindowRow.qml` — D24 thin bars / layouts
- `contents/ui/main.qml` — D27/D28 chrome
- `contents/ui/CostSection.qml` — density / Cost copy
- `contents/ui/StatusFooter.qml` — Loading usage…
- `contents/icons/providers/{codex,commandcode,mimo}.svg` — D19
- `scripts/check-provider-icons.py` — D19 allowlist

### Tests
- `tests/ProviderIconsHarness.qml` — **new**
- `tests/ProviderRowHarness.qml`, `ProviderSelectorHarness.qml`, `ProviderDetailsIntegrationTest.qml`, `UsageModelTest.qml`, `MainCompactHarness.qml`, `test_provider_icons.py`

### SDD
- `openspec/changes/visual-parity-polish/design.md`
- `openspec/changes/visual-parity-polish/tasks.md`
- `openspec/changes/visual-parity-polish/specs/provider-usage-display/spec.md`
- this handoff

---

## 6. Verification commands

```bash
./scripts/run-qml-tests.sh
python3 -m unittest tests.test_provider_icons
# optional live:
kpackagetool6 -t Plasma/Applet -u .
plasmawindowed org.kde.plasma.kodexbar.plasma
```

**Known deferred (not this change):**
- Threshold-colored bars
- Footer Settings/About
- `selectCompact` ignoring `preferredRepresentativeWindow` (pre-existing)
- Phase 7 goldens unless user wants them now

---

## 7. Suggested commit story (only if user asks to commit)

Keep PR6 scope reviewable; optional split:

1. `fix(ui): restore theme-safe provider tab icons (D19)` — SVGs + checker
2. `feat(ui): overview cards, custom tabs, detail chrome polish` — main QML/JS
3. `test(ui): harnesses for displayName, overview, tabs, detail chrome`
4. `docs(sdd): record D21–D30 live polish for visual-parity-polish`

Or one commit if user prefers a single PR6 blob.

**Commit style:** conventional commits, **no** Co-Authored-By / AI attribution.

---

## 8. Prompt to paste into Claude (closeout)

```
SDD closeout for kodexbar-plasma change visual-parity-polish.

Read first (authoritative):
- openspec/changes/visual-parity-polish/SDD-HANDOFF-CLAUDE.md
- openspec/changes/visual-parity-polish/design.md (section Post-PR5 live polish, D21–D30)
- openspec/changes/visual-parity-polish/tasks.md (Phase 8 done; Phase 7 open)
- openspec/changes/visual-parity-polish/specs/provider-usage-display/spec.md

Branch: visual-parity-polish/pr6-overview-and-icon-fix
Working tree has the full polish UNCOMMITTED. Do not commit unless I say so.

Your job:
1. Verify ./scripts/run-qml-tests.sh green.
2. Fix any remaining SDD doc inconsistency with D21–D30 (no inventing new UI).
3. Tell me what's left for Phase 7 (goldens) vs archive.
4. If I ask to commit/PR, use conventional commits only, no AI co-author.

Do NOT reintroduce percent-in-tab-text, QQC2 TabBar for providers, ErrorSummary in popup,
email/version/org in detail header, or Overview 2-line bar layout.
```

---

## 9. Gotchas for the next agent

1. **Breeze TabButton** = paint in background; never contentItem-only icon fix.
2. **ColumnLayout + `width: root.width` on child** = often zero-size bars.
3. **`item.Layout.leftMargin` from outside** = undefined; use plain props on the item.
4. **Live smoke beats offscreen** for tab/icon density.
5. **User owns commit**; PR6 was explicitly “leave uncommitted until I decide”.
6. **ErrorSummary** still unit-tested; absence is popup wiring only (`main.qml`).
