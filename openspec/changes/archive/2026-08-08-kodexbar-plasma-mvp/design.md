# Design: KodexBar Plasma MVP

## Technical Approach

Replace the 1,429-line controller/view with a native `PlasmoidItem`, request controller, and pure model functions. Execute only the configured CLI and render only committed normalized snapshots; never infer providers, credentials, sources, or reset times.

## Architecture Decisions

| Option | Tradeoff | Decision and rationale |
|---|---|---|
| Retain executable `DataSource` | Requires strict quoting | Reuse proven Plasma integration with an absolute path and fixed arguments. |
| Keep one QML file | Poor reviewability | Extract pure model logic and two focused delegates. |
| Clear data during refresh | Flicker/data loss | Retain the committed snapshot; malformed/stale output cannot mutate it. |
| Map source/reset values | Invents semantics | Preserve raw values exactly. |

## Components and File Changes

| File | Action | Responsibility |
|---|---|---|
| `contents/ui/main.qml` | Modify | Lifecycle, representations, timer, wiring. |
| `contents/ui/UsageController.qml` | Create | CLI lifecycle, watchdog, coalescing, generations. |
| `contents/code/UsageModel.js` | Create | Normalization and compact selection. |
| `contents/ui/ProviderRow.qml` | Create | Accessible provider/window row. |
| `contents/ui/ErrorSummary.qml` | Create | Counted disclosure; render at most 20 errors plus omitted count. |
| `contents/config/main.xml` | Modify | Keep path/interval; remove obsolete settings. |
| `contents/ui/config/configGeneral.qml` | Modify | Validated native two-field form. |
| `README.md` | Modify | Scope, path, manual OpenCode Go prerequisite. |

`metadata.json`, `contents/config/config.qml`, and provider assets remain unchanged; unknown providers use a themed fallback icon.

## Data Flow and State Machine

    Timer/manual/config → UsageController → quoted CLI command → stdout/status
                               ↓                         ↓
                       coalesced follow-up       UsageModel.normalize
                                                         ↓
                         compact ← committed snapshot → popup

States are `idle → loading → ready | noData | error`. Refresh retains the last successful snapshot. Success atomically replaces providers/errors; valid empty data becomes `noData`; timeout, nonzero exit, empty output, or malformed JSON becomes recoverable `error` without committing output.

## Interfaces / Contracts

The executed command contains only the POSIX-quoted configured absolute path followed by `usage --provider all --format json --json-only`. Shell comments, prefixes, and additional arguments are forbidden. Generation and DataSource identity remain entirely out-of-band in controller state and request-scoped object properties. Relative paths are blocked; missing/non-executable paths return actionable errors.

Normalization accepts an array or singleton, preserving order, nullable raw `provider`/`source`, and raw `resetsAt`/`resetDescription`. Only `usage.primary|secondary|tertiary` map to Session/Weekly/Monthly. Missing windows are omitted. Only finite JSON numbers qualify as `usedPercent`; errors are separated from usable rows.

Compact selection scans providers in CLI order and windows in priority order, replacing only for a strictly greater finite percentage. Ties therefore retain both priorities. Without a candidate, phase determines Loading, Error, or No data.

Only one request-scoped DataSource object and generation are active. Overlapping triggers set one boolean `refreshQueued`; completion starts at most one follow-up. Callbacks compare the object's generation with controller state. A watchdog disconnects and invalidates the object, so late callbacks cannot commit.

## Native UI and Verification

Use Plasma/Kirigami controls, system units/theme/fonts/icons, visible focus, accessible names/states, and text plus color for status. Compact content elides; the popup has one vertical scroll surface and keyboard-operable disclosure.

No runner exists. Use fixture-driven `qmltestrunner` if available; otherwise use a temporary QML harness and record results. Cover malformed/nullable/mixed/empty payloads, ties, non-finite values, path quoting, exit/timeout, coalescing, stale callbacks, narrow geometry, keyboard order, and both themes. Smoke-check with `kpackagetool6` and `plasmawindowed` where available.

## Threat Matrix

| Boundary | Applicability | Safe/failure behavior and planned RED test |
|---|---|---|
| Documentation-like paths | N/A — no file classification or execution by extension. | None. |
| Git repository selection | N/A — no VCS integration. | None. |
| Commit state | N/A — no VCS integration. | None. |
| Push state | N/A — no VCS integration. | None. |
| PR commands | N/A — no PR automation. | None. |
| Executable command | Applicable | Literal absolute path plus fixed args; reject invalid paths. RED fixtures use spaces, quotes, shell metacharacters, missing/non-executable files, timeout, and stale completion. |

## Explicit Exclusions

Excluded: cost, charts, provider/source switching, authentication or cookie automation, provider implementation, fallback probing, and reset/account actions.

## Migration / Rollout

No data migration. Existing relative `codexbarCommand` values become visibly invalid and must be replaced; default targets `/home/ginopc/.local/bin/codexbar`. Roll back by reverting/reinstalling the prior fork; package identity remains distinct and no credentials are changed.

To protect the 800-line budget, plan independently reviewable units: (1) model/controller and acquisition switch, (2) compact/popup delegates and legacy UI removal, (3) settings/documentation cleanup. Forecast is high because deletions count; `ask-on-risk` requires delivery-splitting approval before apply.

## Open Questions

- [ ] Confirm during the first integration slice that disconnecting an executable DataSource terminates its process; otherwise stop and reassess timeout containment rather than adding an unreviewed helper dependency.
