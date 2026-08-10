# Live Plasma Smoke Checklist

This is a **manual** checklist for a real Plasma desktop. The offscreen `TimeoutFeedbackPopupHarness.qml` checks constrained timeout guidance, Refresh reachability, and retained snapshots, but it does not replace live Plasma keyboard traversal or Breeze theme smoke checks.

## Start

Install or update the applet, then launch it without offscreen rendering:

```sh
kpackagetool6 -t Plasma/Applet -u .
plasmawindowed org.kde.plasma.kodexbar.plasma
```

If the package is not installed yet, use `-i .` instead of `-u .`.

## Manual live lifecycle evidence

Save the current CodexBar CLI path from the widget settings before this check. Set the path temporarily to the executable fixture from this checkout, then start the applet:

```sh
chmod +x ./tests/fixtures/codexbar-lifecycle-fixture.sh
plasmawindowed org.kde.plasma.kodexbar.plasma
```

- When fixture-backed execution is available, activate Refresh and verify Loading continues through path validation, then becomes Ready with the `fixture` provider; it must not remain Loading until timeout.
- Restore the previously saved CodexBar CLI path immediately after the check and activate Refresh once more.
- If fixture-backed `plasmawindowed` execution cannot be automated, record a manual real-provider observation instead: visible provider rows, compact summary, Ready transition, command path provenance, observer, and whether the verifier executed it. This is accepted live evidence but does not claim automated fixture coverage.

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
