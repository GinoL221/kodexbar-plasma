# Product: usage monitoring in Plasma

KodexBar Plasma is a KDE Plasma 6 widget for monitoring usage returned by an external CodexBar-compatible CLI. It displays reported data; provider setup, authentication, credentials and API access remain outside the widget. See the [README](../README.md) for setup and the [roadmap](../ROADMAP.md) for deferred work, not commitments about current behavior.

## Current experience

- The panel control is icon-only. Its tooltip and accessible name carry usage or status; scrolling cycles the panel's provider target. Click to open the popup.
- The popup starts on Overview (all visible usable providers). A selection is retained across close/reopen within the running widget, subject to reconciliation if a provider disappears; it is not promised across a restart.
- Provider rows show available usage windows. A selected provider can show validated details such as pace, credits and identity; Overview remains compact. For selected `codex` or `claude`, a separate optional cost result may show CLI-reported estimates, not prices calculated by the widget.
- Refresh runs on a timer or on demand. The last valid snapshot is cached locally; rate-limit backoff and optional quota notifications help with monitoring.

Settings include the CLI path, refresh interval, timeout, representative window, notifications, hidden provider IDs and interface language. See [settings definitions](../contents/config/main.xml) and the [settings UI](../contents/ui/config/configGeneral.qml).

## Boundary and privacy

The widget does not manage accounts, credentials, cookies, provider switching, credit redemption or reset actions. The optional [NaN adapter](nan-adapter.md) is a separate wrapper with its own external API and key handling. The widget can display validated account identity in selected-provider detail and stores normalized provider snapshots locally in SQLite, including retained raw provider data; treat that cache as potentially sensitive. Hiding a provider affects presentation, not the CLI request or necessarily notifications.

## Source-of-truth notes

The [usage controller](../contents/ui/UsageController.qml) currently invokes `usage --format json --json-only`, without `--provider all`. The CLI's behavior when that option is omitted is not established here. The README describes a different invocation, first-provider default selection, and visible compact summary; those statements do not match the current implementation. It also omits hidden providers and language from its settings table. See [design](design.md) for the data flow and [UI checklist](ui-parity-checklist.md) for review guidance; checklist items may lag implementation.
