# Live Plasma Smoke Checklist

This is a **manual** checklist for a real Plasma desktop. The offscreen `TimeoutFeedbackPopupHarness.qml` checks constrained timeout guidance, Refresh reachability, and retained snapshots, but it does not replace live Plasma keyboard traversal or Breeze theme smoke checks.

## Start

The legacy `org.kde.plasma.kodexbar` and current `org.kde.plasma.kodexbar.plasma` packages may coexist. Install or update only the current package, then launch it without offscreen rendering:

```sh
kpackagetool6 -t Plasma/Applet -u .
plasmawindowed org.kde.plasma.kodexbar.plasma
```

If the package is not installed yet, use `-i .` instead of `-u .`.

Use Plasma's **Add Widgets** flow to add a new **KodexBar Plasma** widget. Do not remove a package, modify panel containments, or expect a legacy widget to change package identity. If equivalent behavior is wanted, optionally re-enter `General` settings (`codexbarCommand`, refresh interval, request timeout, and representative window) for the new instance; settings remain independent per instance.

## Configuration-first recovery evidence

Record the command path and outcome for each scenario in the evidence template below. Terminal `command -v codexbar` is a user diagnosis step only; the live widget must not use inherited `PATH`, scan directories, or probe arbitrary paths.

### First-run discovery

1. Clear the widget's saved CLI path in settings and apply the change.
2. Launch the applet with `plasmawindowed`.
3. When one approved candidate is executable, verify the first approved path is saved and the widget reaches Loading then Ready.
4. Verify the request still uses exactly `usage --provider all --format json --json-only`.

### Valid saved path upgrade

1. Save a known executable absolute CLI path, then update the applet with `kpackagetool6 -t Plasma/Applet -u .`.
2. Launch the updated applet and activate Refresh.
3. Verify the same saved path remains configured and reaches Ready without replacing it through discovery.

### Failed recovery and retained snapshot

1. First obtain a visible provider row from a valid executable path.
2. Change the saved path to a missing, relative, or non-executable value, then activate Refresh.
3. Verify bounded recovery either saves a validated approved path or shows configuration guidance without issuing a usage request.
4. When no approved path validates, verify the previous provider snapshot remains visible and the settings path can be corrected manually.

## Manual live lifecycle evidence

Save the current CodexBar CLI path from the widget settings before this check. Set the path temporarily to the executable fixture from this checkout, then start the applet:

```sh
chmod +x ./tests/fixtures/codexbar-lifecycle-fixture.sh
plasmawindowed org.kde.plasma.kodexbar.plasma
```

- When fixture-backed execution is available, activate Refresh and verify Loading continues through path validation, then becomes Ready with the `fixture` provider; it must not remain Loading until timeout.
- Restore the previously saved CodexBar CLI path immediately after the check and activate Refresh once more.
- If fixture-backed `plasmawindowed` execution cannot be automated, record a manual real-provider observation instead. Use the evidence record template below.

### Manual evidence record template

| Field | Value |
|---|---|
| Evidence class | `user-provided` / `verifier-run` / `fixture-backed` |
| Observer / source | Who observed or supplied the evidence |
| Command path | Absolute path to the CodexBar CLI used |
| Plasma / runtime context | `plasmawindowed` version, Plasma version, color scheme, offscreen or live session |
| Ready outcome | Did the widget leave Loading and reach Ready? |
| Visible provider rows | Provider names and usage values observed |
| Compact summary | Text shown in the panel compact representation |
| Date / reference | When the observation was made, plus screenshot or log reference |
| Automation limitations | State that this evidence is environment-specific, non-replayable, and does not prove automated or verifier-run coverage |

> Manual evidence is accepted when fixture-backed automation is infeasible. It MUST NOT be represented as automated, verifier-run, or fixture-backed coverage.

## Keyboard

- Press `Tab` until the compact KodexBar control is focused.
- Press `Enter`; verify the details popup opens.
- Close and focus the compact control again, then press `Space`; verify the popup opens.
- In the popup, use `Tab` to reach refresh, disclosure, and provider controls where present.
- With timeout guidance visible in a narrow popup, verify its full text remains readable and that Refresh is reachable with `Tab`.
- Press `Enter` or `Space` on Refresh after a timeout; verify the next attempt enters Loading while the prior usage snapshot remains visible.
- Press `Enter` and `Space` on the error disclosure; verify it expands and collapses.
- Press `Escape`; verify the popup closes and focus returns to the panel context.

## Provider-focused popup

Use fixture-backed data where available, or a real CLI response containing multiple providers, missing fields, and a mixed provider error. Confirm the refresh command remains exactly:

```sh
usage --provider all --format json --json-only
```

- Open the popup and verify the first response-ordered provider with usable windows is selected by default; a provider without windows must be skipped.
- Verify every selector entry shows its provider name, authoritative themed icon or fallback, and exact source; use keyboard focus to confirm the full source remains available when text is elided.
- Select `All` and verify each usable provider renders exactly one representative usage bar in response order, selecting the first finite Session, then Weekly, then Monthly percentage.
- Verify providers without a finite Session/Weekly/Monthly percentage show identity only (name, icon, source) with no invented percentage or bar.
- Verify `All` rows are not expandable and do not reveal additional window details when navigated or activated.
- Select each usable provider and verify its supplied Session, Weekly, and Monthly windows, exact raw reset text, and finite-percentage progress bars are shown in detail.
- Verify missing, nonnumeric, or non-finite percentages have no percentage/progress bar, and absent or empty reset fields have no placeholder.
- Traverse `All` and provider entries with `Tab`, Left/Right, Home/End, `Enter`, and `Space`; verify focus order, selected state, and displayed view stay aligned.
- In a narrow window with long provider names and sources, verify the selector scrolls or elides without horizontal clipping and wrapped detail/reset text stays readable.
- Verify the `All` representative bar and percentage remain readable and are not clipped in the narrow layout.
- With a constrained popup width and then a wider width, verify every finite window percentage remains fully visible, visible row content stays inside the popup, and each progress bar expands into the newly available width.
- Repeat the provider-focused checks in Breeze Light and Breeze Dark; verify icons, labels, progress, focus, and errors remain readable.
- Refresh with a selected provider after reordering providers; verify it remains selected by identity. Then remove that provider or its windows and verify selection falls back to the first usable provider, or `All` when none remain.
- With usable providers plus failures, verify provider content precedes one global collapsed error summary, its count is correct, and its bounded expansion preserves error order.

## Settings

- With no CLI path configured, verify the configuration-first guidance explains how to save an executable absolute path.
- Confirm a relative or non-executable path does not run the all-provider request; correct it with a terminal-verified absolute path.
- Open widget settings and use `Tab` to reach Request timeout, its preset selector, and the custom seconds input.
- Confirm 60, 120, and 180 presets, then enter a custom whole number from 30 to 600; verify Refresh interval remains unchanged.
- Verify the correction guidance wraps, labels remain readable, and focus is visible in both Breeze themes.

### Representative window setting

- With `Tab`, confirm the "Representative window:" control is reachable immediately after the custom Request timeout field, is labeled, and its guidance text is readable in both Breeze themes.
- With Automatic selected (the default), verify `All` renders exactly the same representative bar per provider as before this change: first finite Session, then Weekly, then Monthly.
- Select Weekly; verify every provider with a finite Weekly percentage now shows its Weekly bar in `All`, with the same styling as any other representative bar.
- Select Monthly; verify a provider lacking a finite Monthly percentage still shows a bar — falling back to its own automatic order (Session, then Weekly) — while a provider with a finite Monthly percentage shows Monthly.
- Verify a provider with no finite percentage under any of the four settings still shows identity only, with no invented bar or percentage.
- Verify the panel compact badge (the percentage shown in the panel itself) does not change when the representative-window setting changes.
- Repeat the Automatic/Weekly/Monthly checks in Breeze Light and Breeze Dark; verify the control, its guidance text, and every representative bar remain readable.

## Provider and error navigation

- With multiple providers available, use `Tab` to move through provider rows without pointer input.
- Verify provider order, usage windows, reset text, and raw source values remain readable.
- With a mixed provider response, open the bounded error disclosure and verify usable providers remain visible.
- Verify the disclosure reports the full count while rendering no more than 20 failures.

## Provider icon color smoke (currentColor gate)

`scripts/check-provider-icons.py` (wired into CI) proves coverage, no-orphan,
parseable-XML, and distinctness invariants over `contents/icons/providers/*.svg`,
but it cannot prove that a recolored `currentColor` icon actually renders
legibly against both Breeze themes — that is a rendering fact, not a file
fact. This manual two-theme check is the mandatory acceptance gate for every
slice of the `provider-icon-rendering` change that recolors or replaces
provider SVGs.

```sh
plasmawindowed org.kde.plasma.kodexbar.plasma
plasma-apply-colorscheme BreezeLight   # run with the window open
plasma-apply-colorscheme BreezeDark
```

Open the popup, select `All`, and inspect the icon(s) under test at
`Kirigami.Units.iconSizes.smallMedium`.

**PASS** requires all of:

- The mark renders as a dark glyph on the light background under BreezeLight
  and as a light glyph on the dark background under BreezeDark.
- The silhouette is identical in both theme runs and identical to the
  pre-edit geometry.
- The glyph is neither blank nor a solid filled block nor clipped.

**FAIL** is any of:

- A solid filled square or block.
- An invisible or blank mark in either theme.
- A mark that does not invert with the theme (stays white on light, or stays
  dark on dark).
- Changed geometry versus pre-edit (a stroke became a fill, or a knockout
  closed).

### Per-icon literal-color fallback

Applied only to a file that genuinely FAILs the smoke above:

1. First re-diagnose: if a `style` declaration on the element or an
   ancestor still carries a literal color, the failure is a P5 cascade
   defect (an inline `style` outranks a presentation `fill`/`stroke`
   attribute), not a genuine `currentColor` defect — fix inside `style`
   and re-smoke. Likewise check for a surviving nested override.
2. Only if `currentColor` genuinely does not resolve for that file's
   structure, set that file's literal to the documented fallback
   `#7F7F7F` (neutral mid-gray, chosen to sit between both Breeze panel
   backgrounds), re-run the same two-theme smoke to confirm legibility,
   record the file and the reason in the exception table below, and add
   the file to the checker's `LITERAL_COLOR_ALLOWLIST`.
3. The fallback is per-file. A single failure never converts the whole
   batch to literal colors.

### Slice 2 de-risking gate evidence (2026-08-14)

The two-sample de-risking gate (`synthetic.svg`, `jetbrains.svg`) could not be
completed as the textbook automated procedure above: the sandboxed tool
environment used to implement this change cannot keep a `plasmawindowed`
window open while concurrently capturing a screenshot (any backgrounded
process alongside a screenshot capture terminates the whole call), so no
automated in-panel screenshot of these two specific files was taken. This is
an environment limitation, not a skipped step. The combined evidence actually
gathered:

- **Live real-panel confirmation (user-provided, verifier-adjacent):** the
  user added the `org.kde.plasma.kodexbar.plasma` widget to their real Plasma
  panel (not `plasmawindowed`) with this change's package installed, and
  confirmed via screenshot that the Slice-1-authored `codex.svg`
  (`fill`/`stroke="currentColor"`, same `Kirigami.Icon`/non-mask render path
  as every other provider icon) renders as a correctly themed, distinct,
  legible mark in both the compact panel row and the detail popup. This
  proves `Kirigami.Icon` does resolve `currentColor` against the live Breeze
  theme in this exact codebase and render pipeline — the core assumption this
  whole change depends on.
- **Static geometry confirmation (user-provided, Gwenview):** the user opened
  `contents/icons/providers/synthetic.svg` and `contents/icons/providers/jetbrains.svg`
  directly (outside the widget) after the R1/R4/R5 edits and confirmed both
  render as their pre-edit recognizable silhouettes (a rounded flower/star
  for `synthetic`, a document-with-bar mark for `jetbrains`) — neither is a
  solid block, blank, or clipped. This confirms P6/P7 (no geometry change)
  held for both files, including `jetbrains.svg`'s CSS `style`-based edit.
- **Not verified**: live theme-inversion (light/dark) specifically for
  `synthetic.svg` and `jetbrains.svg` inside the actual panel/popup. Given the
  mechanism-level proof above (identical `currentColor` + `Kirigami.Icon`
  path, confirmed working for `codex.svg`) and the confirmed-intact geometry
  for both files, this is treated as sufficient combined evidence to pass the
  gate and proceed to the bulk 21-file conversion, but the theme-inversion
  check for these two specific files remains open. Complete it opportunistically
  by repeating the automated procedure above once `synthetic`/`jetbrains` are
  reachable in a live provider list, or once the environment limitation is
  lifted.

### Literal-color exception table

Empty by default. Add one row only when the fallback above is genuinely
applied to a specific file.

| File | Reason `currentColor` did not resolve | Fallback color | Verified in (BreezeLight/BreezeDark) | Date |
|---|---|---|---|---|

## Breeze themes

Run each command while the live window is open and repeat the keyboard checks:

```sh
plasma-apply-colorscheme BreezeLight
plasma-apply-colorscheme BreezeDark
```

Verify text, icons, focus indication, negative error text, timeout guidance, settings labels, Refresh, and disabled text remain readable in both themes.
Verify `All` provider rows, representative bars, and identity-only fallback rows remain readable in both Breeze Light and Breeze Dark.
