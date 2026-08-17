# UI parity checklist

Manual craft checklist for the KodexBar Plasma popup and compact representation. Use this with [live-plasma-smoke.md](live-plasma-smoke.md) after layout or polish changes.

Deterministic offscreen selected-provider pixel checks are documented in [visual-regression.md](visual-regression.md); they supplement, but do not replace, this manual sign-off.

**Authority:** structure and information hierarchy may follow CodexBar (Linux/macOS) as a **wireframe**. Styling must remain Plasma 6 + Kirigami + Breeze (`Kirigami.Units`, `Kirigami.Theme`). Do not copy macOS glass, fixed brand blues, or web dashboard cards.

Load `skills/plasma-kirigami-ui/SKILL.md` before implementing UI changes.

## Compact representation

- [ ] Panel control shows usage summary or phase text without layout thrash
- [ ] Compact mark is theme-adaptive (no black/white square under Light/Dark)
- [ ] Click / keyboard activation toggles the popup

## Provider tabs

- [ ] `All` plus usable providers in CLI response order
- [ ] Tab content is **icon + short provider name** only (no email, no `· source` in the label)
- [ ] Full `source` remains available via accessible name/description
- [ ] Horizontal overflow scrolls; no clipped tab row without affordance
- [ ] Keyboard: Tab into bar, arrows/Home/End as native, activation matches selection

## Selected-provider header

- [ ] Provider display name is prominent
- [ ] `Updated …` appears when `usage.updatedAt` is valid; omitted when absent
- [ ] Plan / `loginMethod` shown when valid (no empty placeholder)
- [ ] Account **email** shown only when CLI supplies a valid email
- [ ] **Organization** shown only when human-readable (omit UUID / long hex / opaque tokens)
- [ ] Header enrichment is **absent** in `All` summary rows

## Usage windows

- [ ] Session / Weekly / Monthly rows only when the CLI supplies that window
- [ ] Finite `usedPercent` shows bar + used text; non-finite does not invent a bar
- [ ] Reset text prefers CLI `resetDescription` / raw reset fields; no fabricated durations in QML
- [ ] Dense, readable layout in both Breeze Light and Breeze Dark

## Pace

- [ ] Valid `pace.primary|secondary|tertiary` attaches to the matching window only
- [ ] Missing or malformed pace is omitted (no empty pace row)

## Credits and reset credits

- [ ] Finite non-negative `credits.remaining` may show when present
- [ ] Reset-credit block is **hidden** when `availableCount` is 0 or invalid
- [ ] When `availableCount` > 0: count visible; expirations behind keyboard-reachable disclosure
- [ ] No Redeem / mutate / account action controls

## Cost (selected provider only)

- [ ] Cost section only for selected `codex` or `claude` when CLI cost snapshot is valid
- [ ] Never shown for `All` or unsupported providers
- [ ] Values match CLI fields only (`sessionCostUSD`, tokens, last-30-day fields); no QML pricing
- [ ] Local-estimate labeling / `source: local` intent preserved (not billed-as-subscription copy)
- [ ] Cost failure, timeout, or empty result **hides** the section and does not disturb Usage

## Details and errors

- [ ] `usage.details[]` remains collapsed by default; expandable by pointer and keyboard
- [ ] Free-form details still reject email/org/pace/credit/cost/token-shaped content in titles/rows
- [ ] Global error summary stays bounded and after provider content

## Footer / chrome

- [ ] Refresh reachable and does not replace Usage snapshot incorrectly on failure
- [ ] Settings via Plasma configure action only (no in-popup Auth / Add Account / Quit)

## Theme and accessibility

- [ ] Breeze Light: text, bars, icons, focus rings readable
- [ ] Breeze Dark: same
- [ ] Focus order matches visual order; disclosures announce expand/collapse
- [ ] No hardcoded colors that break one theme

## Anti-patterns (fail if present)

- [ ] No HTML/CSS layout metaphors, web breakpoints, or emoji-as-icon
- [ ] No glassmorphism / fixed macOS accent styling
- [ ] No second request that blocks or clears Usage when Cost fails

## Sign-off

| Field | Value |
|---|---|
| PR / change | visual-parity-polish (PR6 D1-D30, PR7 goldens) |
| Date | 2026-08-16/17 |
| Breeze Light | pass |
| Breeze Dark | pass |
| Notes | Live `plasmawindowed` smoke (task 8.11) on both themes: Overview single-line bars, custom tab chip strip (icons/underline/arrows, no doubled paint), full-length titles, codex/commandcode/mimo icons legible, detail header shows name+Updated+badge only, CLI-verbatim resets, Cost section correct. Offscreen visual-regression goldens (Phase 7) regenerated and converge 0/180000 in all 4 scenarios; `breeze-light-*` goldens inherit a pre-existing (pre-dates this change) black-background/purple-text rendering defect in the Docker/offscreen theme-injection pipeline — confirmed via the prior committed golden, tracked separately (Engram `backlog/visual-regression-light-theme-injection-bug`), not blocking, does not reflect live Plasma Light rendering (which is correct per the live smoke above). |
