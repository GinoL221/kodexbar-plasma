# Design: Architecture, Data Flow & Native Plasma UI System

KodexBar Plasma is structured as a thin, reactive QML/Kirigami presentation layer over pure `.pragma library` JavaScript domain modules and an external CLI boundary. For product scope and settings, see [product.md](product.md); for mandatory QML craft gates, see [skills/plasma-kirigami-ui/SKILL.md](../skills/plasma-kirigami-ui/SKILL.md) and [popup-and-layout-invariants.md](../skills/plasma-kirigami-ui/references/popup-and-layout-invariants.md).

## Architecture & Data Flow

```text
codexbar / codexbar-nan CLI (stdout JSON)
  ├── UsageController.qml ──► UsageModel.js / RateLimitPolicy.js ──► SnapshotStorage.js (id: "latest")
  │         │
  │         ├──► NotificationController.qml ──► NotificationPolicy.js
  │         └──► main.qml (visibleProviders via ProviderFilterPolicy.js)
  │                ├── CompactUsageButton.qml (ProviderCycle.js + ProviderIcons.js)
  │                └── Popup (ProviderSelector.qml + ProviderRow.qml)
  └── CostController.qml  ──► CostModel.js / CostRequestPolicy.js ──► SnapshotStorage.js (id: "cost:<provider>")
```

1. **Command resolution & usage polling ([UsageController.qml](../contents/ui/UsageController.qml), [CodexBarPathResolver.js](../contents/code/CodexBarPathResolver.js)):**
   - Validates a configured absolute executable path (`test -x`) or probes bounded discovery locations (`~/.local/bin/codexbar-nan`, `~/.local/bin/codexbar`, `/usr/local/bin/codexbar`, `/usr/bin/codexbar`, `~/.cargo/bin/codexbar`, `/snap/bin/codexbar`, `PATH`), then executes `usage --format json --json-only`.
   - Requests are serialized with `generation`, `activeGeneration`, and a watchdog timer (`timeoutMs`). Stale callbacks and destroyed components disconnect their `Plasma5Support.DataSource` cleanly.
2. **Normalization & rate-limit resilience ([UsageModel.js](../contents/code/UsageModel.js), [RateLimitPolicy.js](../contents/code/RateLimitPolicy.js)):**
   - `UsageModel.normalizeProvider` maps `primary` (`Session`), `secondary` (`Weekly`), and `tertiary` (`Monthly`) windows, applies `rateWindowLabels` overrides, and promotes scoped extra windows (Antigravity `gemini-argon` -> `Argon`; Claude `claude-weekly-scoped-fable` -> `Fable` on `tertiary`).
   - If a poll reports rate-limit errors, `RateLimitPolicy` retains previously committed provider data and stretches the next refresh delay exponentially.
3. **Multi-instance SQLite persistence ([SnapshotStorage.js](../contents/code/SnapshotStorage.js)):**
   - Stores the latest usage snapshot under `id = "latest"` and per-provider cost snapshots under `id = "cost:<provider>"` with `saved_at` timestamps.
   - Both `UsageController` and `CostController` hydrate from SQLite on `Component.onCompleted` so the panel and popup render immediately on cold start.
4. **Bounded cost prefetch & cross-instance cache sharing ([CostController.qml](../contents/ui/CostController.qml), [CostRequestPolicy.js](../contents/code/CostRequestPolicy.js)):**
   - When `committedGeneration` advances, `main.qml` prefetches cost only for supported providers (`codex`, `claude`) targeted by that widget instance (`CostRequestPolicy.prefetchTargets(pinnedProvider, visibleIds)`).
   - Before spawning `cost --provider <id> --format json --json-only`, `CostController` checks SQLite for a record younger than `sharedFreshnessMs` (90% of `refreshInterval`). Fresh records written by another widget instance are adopted in memory without rewriting `saved_at`.
5. **Filtering, cycling & notifications ([ProviderFilterPolicy.js](../contents/code/ProviderFilterPolicy.js), [ProviderCycle.js](../contents/code/ProviderCycle.js), [NotificationPolicy.js](../contents/code/NotificationPolicy.js)):**
   - `ProviderFilterPolicy.filterAndSortProviders` applies `excludedProviders` and `providerOrder`.
   - `ProviderCycle` resolves the compact panel target (`All` or a specific provider, honoring `pinnedProvider`).
   - `NotificationController` evaluates quota thresholds and rate-limit state transitions on each committed generation.

## Native Plasma / Kirigami Design System

Implementation authority resides in [SKILL.md](../skills/plasma-kirigami-ui/SKILL.md) and [ui-parity-checklist.md](ui-parity-checklist.md).

| Surface / Token | Native Rule |
|-----------------|-------------|
| **Spacing & density** | Exclusively `Kirigami.Units` (`smallSpacing`, `largeSpacing`, `gridUnit`, `iconSizes.*`). Never hardcode pixel tokens from web tools. |
| **Typography** | `Kirigami.Theme.defaultFont` and ` Kirigami.Theme.smallFont` with semantic weights (`Font.DemiBold`, `Font.Medium`) and `TabularNumbers` on numeric readouts. |
| **Colors & contrast** | `Kirigami.Theme.textColor`, `disabledTextColor`, `neutralTextColor`, `negativeTextColor`, `highlightColor`. Threshold percentages use `UsageStatusThreshold.js` semantic bands; progress bars and histogram bars use `ProviderIcons.accent(provider)` with `Kirigami.Theme.highlightColor` fallback. |
| **Controls** | `org.kde.plasma.components` (`Label`, `ProgressBar`, `ToolButton`), `QtQuick.Controls` (`ScrollView`, `TabBar`), and `Kirigami.FormLayout` in settings. |
| **Icons** | Bundled vector SVGs under `contents/icons/providers/` rendered via `ProviderIcon.qml` (tinted mask or multi-color SVG); never emojis or web icon fonts. |

## Popup Information Hierarchy & Anatomy

### 1. Vertical Stack Order (`main.qml` & `ProviderRow.qml`)

1. **Terminal status banner:** Shown only when `phase === "noData"` or `phase === "error"`.
2. **Provider selector (`ProviderSelector.qml`):** Hidden when `pinnedProvider` is set; otherwise displays `All` plus usable visible providers with wheel scroll and keyboard reorder (`Alt+Left` / `Alt+Right`).
3. **Overview list (`Repeater` of `ProviderRow` with `summary: true`):** Active only when unpinned and `All` is selected.
4. **Detail view (`ProviderRow` with `summary: false`):** Active when a provider tab is selected or `pinnedProvider` is configured:
   - `ProviderHeader.qml` (provider title, relative updated time, plan/login badge)
   - `creditsRemainingLabel` (when finite and `> 0`)
   - `UsageWindowRow.qml` repeater (window title, standardized reset countdown, threshold-colored percentage, full-width progress bar, optional pace summary)
   - `ResetCreditsSection.qml` (when `availableCount > 0`)
   - `CostSection.qml` + `CostHistogram.qml` (when a valid cost snapshot exists for the selected provider)
   - `ProviderDetails.qml` (collapsed-by-default disclosure for sanitized `usage.details[]`)
5. **Pinned bottom footer (`bottomChromeRow`):** Refresh action (`Loading` indicator while active) and Configure button.

### 2. `UsageWindowRow` Layout Contract

- **Overview (`summary: true`):** Single-line row (`windowLabel | summaryBar | summaryPercentageLabel`) using `TextMetrics` to align label and percentage columns across sibling rows.
- **Detail (`summary: false`):** Two-line header + bar stack (`windowLabel` + `detailResetContainer` + `bandPercentageLabel` above full-width `detailBarHost`, followed by optional `paceSummaryLabel`).
- **Standardized resets ([ResetTimeFormatter.js](../contents/code/ResetTimeFormatter.js)):** Future ISO `resetsAt` timestamps format as `Resets in Xd Yh` / `Resets in Xh Ym` (or Spanish equivalents via `Translation.js`), ticked every 60 seconds while visible.

### 3. Cost Grid & Histogram Contract

- **2x2 metric grid ([CostSection.qml](../contents/ui/CostSection.qml)):** Pairs Today Cost / Today Tokens and 30-Day Cost / 30-Day Tokens inside subtle `Kirigami.Theme` cards.
- **14-day right-aligned bar chart ([CostHistogram.qml](../contents/ui/CostHistogram.qml)):** Slices up to the 14 most recent daily entries (`validDaily.slice(-14)`), anchors the latest day to the right edge with bounded bar widths (`10–18px`), and scales homogeneously in either USD (`isCostMode`) or tokens so units are never mixed.

## Component & Test Invariants

- **Stateless domain logic:** Every file in `contents/code/*.js` starts with `.pragma library` and receives external dependencies (`LocalStorage`, translator functions, clock timestamps) as arguments.
- **Bound QML scopes:** Presentational QML components use `pragma ComponentBehavior: Bound` with explicit `required property var modelData` in delegates.
- **Static & runtime verification gates:**
  - `./scripts/validate-package.sh` and `python3 scripts/check-provider-icons.py` verify package structure and SVG assets.
  - `./scripts/lint-qml.sh` enforces `qmllint` and `scripts/check-qml-unqualified-baseline.py` (including tracked `LAYOUT_POSITIONING_EXCEPTIONS`).
  - `./scripts/run-qml-tests.sh` runs offscreen QtTest suites (`tests/*Test.qml`), component harnesses (`tests/*Harness.qml`), and Python contract tests.
  - `./scripts/run-visual-tests.sh` verifies Breeze Light/Dark offscreen visual goldens (`tests/visual/goldens/*.png`).

## Anti-Patterns & Hard Rejections

- **No web-generic styling:** Never introduce HTML/CSS layouts, fixed hex palettes for surfaces/text, hardcoded `px` spacing tokens, pill-badge clutter, or nested card-in-card borders.
- **No CLI coupling in UI components:** Presentational QML components (`ProviderRow`, `UsageWindowRow`, `CostSection`, `CostHistogram`) consume normalized JS objects; they must never spawn processes or parse raw CLI stdout.
- **No PII leakage on primary chrome:** Raw account emails and organization identifiers stay off the Overview and primary header chrome, and free-form detail rows are scrubbed by `ProviderDetails.js`.
