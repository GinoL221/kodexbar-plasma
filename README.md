# KodexBar Plasma

> All-provider CodexBar usage in your KDE Plasma panel.

[![Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6-1d99f3?style=flat-square)](https://kde.org/plasma-desktop/)
[![CodexBar CLI](https://img.shields.io/badge/powered%20by-CodexBar%20CLI-0a0a0c?style=flat-square)](https://github.com/steipete/CodexBar)
[![License: MIT](https://img.shields.io/badge/license-MIT-6e5aff?style=flat-square)](LICENSE)

KodexBar Plasma is a native KDE Plasma widget that displays all-provider usage returned by the external [CodexBar](https://github.com/steipete/CodexBar) CLI. It renders the CLI response in a compact panel view and a Plasma-native popup.

The CLI is the boundary: KodexBar Plasma runs one configured executable with `usage --provider all --format json --json-only`. CodexBar remains responsible for provider configuration, credentials, API access, and its own data acquisition.

![KodexBar Plasma widget screenshot](screenshot.png)

## MVP scope

- **All-provider usage.** Shows usable CLI providers in response order with available Session, Weekly, and Monthly windows.
- **Trustworthy compact summary.** Shows the highest valid percentage without remapping CLI fields.
- **Plasma-native UI.** Uses Plasma 6 and Kirigami controls with a compact panel item and one scrollable popup.

## Requirements

- KDE Plasma 6
- `kpackagetool6`
- Upstream `codexbar` CLI at an executable absolute path

Install the upstream CLI with Homebrew on Linux:

```sh
brew install steipete/tap/codexbar
/home/ginopc/.local/bin/codexbar usage --provider all --format json --json-only
```

Or download a Linux CLI tarball from the [CodexBar releases](https://github.com/steipete/CodexBar/releases/latest).

Configure credentials through CodexBar and the relevant provider tools before using the widget. For OpenCode Go, run this prerequisite manually after completing the external sign-in flow:

```sh
codexbar-sync-opencodego-cookie
```

KodexBar Plasma never runs this command or automates cookie synchronization.

## Install

From this repository root, install the applet:

```sh
kpackagetool6 -t Plasma/Applet -i .
```

Then add **KodexBar Plasma** to a Plasma panel.

For development reloads:

```sh
kpackagetool6 -t Plasma/Applet -u .
plasmashell --replace
```

## Usage

- Click the panel item to open the popup.
- Use the refresh button in the popup to query the CLI immediately.
- Open widget settings to configure the absolute CLI path, refresh interval, and request timeout.

The popup renders supported CLI fields:

- Session, Weekly, and Monthly usage windows when present
- raw source and reset values when present
- bounded per-provider CLI/runtime errors

## MVP exclusions

KodexBar Plasma deliberately does not implement cost data, charts, provider or source switching, authentication or cookie automation, provider implementations, fallback probing, or reset/account actions. Use CodexBar and provider tools for those responsibilities.

## Settings

| Setting | Purpose |
| --- | --- |
| CLI path | Executable absolute path. The default is `/home/ginopc/.local/bin/codexbar`. |
| Refresh interval | Positive polling interval from 1 to 3600 seconds. |
| Request timeout | All-provider watchdog: presets 60, 120, or 180 seconds, or a custom whole number from 30 to 600. Missing or invalid values use 60 seconds and do not change refresh. |

## Test the CLI

Run this before debugging the widget:

```sh
/home/ginopc/.local/bin/codexbar usage --provider all --format json --json-only | python3 -m json.tool
```

If the widget shows a CLI error, configure the external CLI and credentials, then set its executable absolute path in widget settings.

## Run QtTest

The repository runner resolves `qmltestrunner` from `PATH` and from the common Arch Linux Qt 6 locations `/usr/lib/qt6/bin/qmltestrunner` and `/usr/lib64/qt6/bin/qmltestrunner`:

```sh
./scripts/run-qml-tests.sh
```

The runner uses `QT_QPA_PLATFORM=offscreen` and `QT_QUICK_BACKEND=software`. The remaining executable QML harnesses can be run directly, for example:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/CompactUsageButtonHarness.qml
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/ErrorSummaryHarness.qml
```

## Live Plasma smoke test

For the manual real-desktop checklist, including keyboard traversal and Breeze theme checks, see [docs/live-plasma-smoke.md](docs/live-plasma-smoke.md). It must be run with `plasmawindowed` without offscreen rendering; it is not automated.

## How it works

1. Plasma runs the applet from `metadata.json` and `contents/ui/main.qml`.
2. The applet shells out to the configured path with `usage --provider all --format json --json-only`.
3. The JSON payload is normalized into provider rows, usage windows, errors, and compact panel text.
4. A timer refreshes the data at the configured interval.
5. Provider icons are loaded from `contents/icons/providers/`.

## Troubleshooting

| Symptom | Likely fix |
| --- | --- |
| Widget says `No data` | Run the all-provider CLI command above and verify it returns usable data. |
| Widget shows a CLI/runtime error | Install and configure `codexbar`, then set its executable absolute path. |
| Widget reports that all-provider usage did not return within its request timeout | Check enabled providers in CodexBar, temporarily disable one that hangs, then use the widget Refresh button to retry. The timeout is separate from refresh. |
| Provider works in terminal but not in the widget | Use the same absolute command path in settings if Plasma does not inherit your shell `PATH`. |

## License

MIT. See [LICENSE](LICENSE).
