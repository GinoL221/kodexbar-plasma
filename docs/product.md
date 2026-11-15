# Product: Native AI Usage Monitoring for KDE Plasma 6

KodexBar Plasma (`org.kde.plasma.kodexbar.plasma`) is a native KDE Plasma 6 panel widget that surfaces quota windows, reset countdowns, pace telemetry, and optional local token-cost estimates from an external `codexbar`-compatible CLI. It acts strictly as a read-oriented desktop presentation layer: provider authentication, credentials, API polling, and cost calculation remain outside the widget. See the [README](../README.md) for installation, [design.md](design.md) for architecture and UI invariants, and [ROADMAP.md](../ROADMAP.md) for deferred work.

## Users & Positioning

| Dimension | Definition |
|-----------|------------|
| **Target user** | Developers and power users on KDE Plasma 6 who track rate limits and token spend across multiple AI providers (`codex`, `claude`, `antigravity`, `grok`, `nan`, and other CLI-reported providers) from the desktop panel. |
| **Core value** | Zero-friction glanceability on the Plasma panel (single multi-provider widget or dedicated per-provider pinned widgets) paired with a structured Kirigami popup for detailed quota windows, reset timers, and local cost history. |
| **CLI boundary** | Consumes `codexbar` (or the bundled [NaN Cloud wrapper](nan-adapter.md) `codexbar-nan`) over stdout JSON (`usage --format json --json-only` and `cost --provider <id> --format json --json-only`). |

## Product Commitments & Non-Goals

1. **Read-only CLI consumer:** The widget never stores API keys, manages cookies, switches accounts, redeems credits, or triggers remote resets.
2. **Native Plasma ergonomics first:** Every surface uses Plasma 6 and Kirigami primitives, `Kirigami.Theme` palettes, and `Kirigami.Units` spacing—never web-dashboard cards or macOS glass clones.
3. **Flexible panel topology:** Users can run one unified widget cycling across all visible providers, or pin multiple independent widget instances (`pinnedProvider`) to specific providers with configurable panel labels (`iconOnly`, `iconAndPercent`, `iconNameAndPercent`).
4. **Resilient local state:** Startup hydrates immediately from local SQLite (`SnapshotStorage.js`). Timeouts, CLI errors, or rate-limit responses preserve the last committed snapshot and apply exponential rate-limit backoff (`RateLimitPolicy.js`).
5. **Isolated optional cost:** Local token-cost queries (`codex` and `claude`) run on an independent controller (`CostController.qml`), share cached results across widget instances within the refresh window, and fail closed without affecting usage state.

## Current Experience

### Panel Representation (`CompactUsageButton.qml`)

- **Display styles (`panelDisplayStyle`):**
  - `iconOnly` (default): provider or KodexBar SVG mark with optional accent tint (`tintPanelIcon`).
  - `iconAndPercent`: icon plus representative window percentage (e.g., `42%`).
  - `iconNameAndPercent`: icon, provider display name, and percentage (e.g., `Claude 42%`).
- **Wheel cycling:** Scrolling over an unpinned panel button cycles between `All` (highest-usage window across visible providers) and individual visible providers, updating the panel icon, inline text, and tooltip live.
- **Pinned mode (`pinnedProvider`):** Locks the panel button and popup to a single provider, hiding the multi-provider tab bar and disabling wheel cycling.

### Popup Representation (`main.qml`)

- **Overview (`All` tab):** Compact list of all visible usable providers (`ProviderRow.qml` in summary mode). Each card renders the provider icon, display name, and single-line usage bars (`Session`, `Weekly`, `Monthly`, or mapped tertiary windows such as Antigravity `Argon` and Claude `Fable`).
- **Provider detail (Selected tab or Pinned mode):**
  - **Header (`ProviderHeader.qml`):** Provider name, relative update timestamp, and plan/login badge.
  - **Usage windows (`UsageWindowRow.qml`):** Full-width progress bars, threshold-colored usage percentages, standardized reset countdowns (`ResetTimeFormatter.js`), and optional pace summaries (`ProviderDetails.js`).
  - **Credits & resets (`ResetCreditsSection.qml`):** Remaining credits and expandable reset-credit expiration inventory when reported.
  - **Cost section (`CostSection.qml` & `CostHistogram.qml`):** Shown for `codex` or `claude` when a valid CLI cost snapshot exists; renders a 2x2 summary grid (Today / 30 Days cost and tokens), a 14-day right-aligned daily bar histogram, and the primary model label.
  - **Collapsible metadata (`ProviderDetails.qml`):** Sanitized additional provider details, collapsed by default.
- **Desktop notifications (`NotificationController.qml`):** Optional native Plasma notifications for quota warning/critical thresholds and rate-limit backoff transitions (`NotificationPolicy.js`).

## Settings Reference

Defined in [main.xml](../contents/config/main.xml) and exposed in [configGeneral.qml](../contents/ui/config/configGeneral.qml):

| Key (`kcfg`) | Default | Purpose |
|--------------|---------|---------|
| `codexbarCommand` | `""` (auto-discover) | Custom absolute executable path; when empty, `CodexBarPathResolver.js` probes `~/.local/bin/codexbar-nan` and standard `codexbar` locations. |
| `refreshInterval` | `600` s (1–3600) | Polling interval for usage updates (and `sharedFreshnessMs` cost cache window at 90% of interval). |
| `requestTimeout` | `60` s (30–600) | Watchdog timeout for `UsageController` CLI stages. |
| `preferredRepresentativeWindow` | `"automatic"` | Window used on the panel and tab badges (`automatic`, `primary`, `secondary`, `tertiary`). |
| `enableQuotaNotifications` | `true` | Enables native Plasma notifications on quota threshold crossings and rate limits. |
| `tintPanelIcon` | `true` | Tints the compact panel icon with the active provider's brand accent color. |
| `pinnedProvider` | `""` (All / unpinned) | Pins the widget instance to a single provider ID. |
| `panelDisplayStyle` | `"iconOnly"` | Panel button layout (`iconOnly`, `iconAndPercent`, `iconNameAndPercent`). |
| `excludedProviders` | `""` | Comma-separated provider IDs hidden from presentation. |
| `providerOrder` | `""` | Custom ordering of visible providers (reorderable via settings or tab bar). |
| `language` | `"auto"` | UI translation override (`auto`, `en`, `es` via `Translation.js` and `SpanishDictionary.js`). |

## Privacy & Trust Boundaries

- **UI & SQLite redaction:** `ProviderDetails.js` and `ProviderHeader.qml` filter sensitive free-form detail rows and keep raw email/organization strings off primary chrome, and `SnapshotStorage.js` strips `accountEmail` and `accountOrganization` before persisting snapshots to local SQLite (`QtQuick.LocalStorage`) while validating cached cost numeric fields on read.
- **Presentation filtering:** Adding a provider to `excludedProviders` hides it from the panel and popup (`ProviderFilterPolicy.js`), but `UsageController.qml` still runs a single `usage --format json --json-only` query and `NotificationController.qml` evaluates `committedProviders`.
- **External NaN adapter:** [scripts/codexbar-nan](../scripts/codexbar-nan) reads `NAN_API_KEY` from the environment or `~/.config/codexbar/nan-api-key` (requiring `0600` permissions) and merges NaN Cloud quotas with upstream `codexbar` output.
