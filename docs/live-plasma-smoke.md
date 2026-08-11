# Live Plasma Smoke Checklist

This is a **manual** checklist for a real Plasma desktop. The offscreen `TimeoutFeedbackPopupHarness.qml` checks constrained timeout guidance, Refresh reachability, and retained snapshots, but it does not replace live Plasma keyboard traversal or Breeze theme smoke checks.

## Start

Install or update the applet, then launch it without offscreen rendering:

```sh
kpackagetool6 -t Plasma/Applet -u .
plasmawindowed org.kde.plasma.kodexbar.plasma
```

If the package is not installed yet, use `-i .` instead of `-u .`.

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

## Settings

- With no CLI path configured, verify the configuration-first guidance explains how to save an executable absolute path.
- Confirm a relative or non-executable path does not run the all-provider request; correct it with a terminal-verified absolute path.
- Open widget settings and use `Tab` to reach Request timeout, its preset selector, and the custom seconds input.
- Confirm 60, 120, and 180 presets, then enter a custom whole number from 30 to 600; verify Refresh interval remains unchanged.
- Verify the correction guidance wraps, labels remain readable, and focus is visible in both Breeze themes.

## Provider and error navigation

- With multiple providers available, use `Tab` to move through provider rows without pointer input.
- Verify provider order, usage windows, reset text, and raw source values remain readable.
- With a mixed provider response, open the bounded error disclosure and verify usable providers remain visible.
- Verify the disclosure reports the full count while rendering no more than 20 failures.

## Breeze themes

Run each command while the live window is open and repeat the keyboard checks:

```sh
plasma-apply-colorscheme BreezeLight
plasma-apply-colorscheme BreezeDark
```

Verify text, icons, focus indication, negative error text, timeout guidance, settings labels, Refresh, and disabled text remain readable in both themes.
