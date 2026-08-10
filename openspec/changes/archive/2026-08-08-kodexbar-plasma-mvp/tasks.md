# Tasks: KodexBar Plasma MVP

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | 2,000–2,500 (including legacy deletions) |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 → PR 2 → PR 3 → PR 4 → PR 5, each ≤800 lines |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision needed before apply: No — `stacked-to-main` selected by maintainer
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Model fixtures and normalization | PR 1 | `qmltestrunner -input tests` | Fixture payload suite | `UsageModel.js`, model fixtures |
| 2 | Safe CLI controller and acquisition | PR 2 | `qmltestrunner -input tests` | DataSource termination fixture | `UsageController.qml`, controller fixtures |
| 3 | Compact surface and provider rows | PR 3 | `qmltestrunner -input tests` | `plasmawindowed` narrow-panel smoke | compact/row QML and wiring |
| 4 | Popup/errors and legacy removal | PR 4 | `qmltestrunner -input tests` | keyboard/theme popup smoke | popup QML and removed legacy UI |
| 5 | Configuration and documentation | PR 5 | `kpackagetool6 --type Plasma/Applet --install .` | configuration dialog smoke | config files and README |

## Phase 1: Contract Fixtures and Data Model

- [x] 1.1 Create `tests/UsageModelTest.qml` RED fixtures for singleton/array, nullable fields, mixed errors, empty data, raw source/reset preservation, omitted windows, finite values, and compact tie ordering.
- [x] 1.2 Create `tests/UsageControllerFixture.qml` RED cases for spaces/quotes/metacharacters, missing/relative/non-executable paths, timeout, coalescing, and stale completion; prove `DataSource.disconnectSource()` terminates a long-running executable process before accepting watchdog containment.
- [x] 1.3 Create `contents/code/UsageModel.js` to normalize only `usage.primary|secondary|tertiary`, preserve order/raw values, separate errors, and select the strictly greatest finite percentage.

## Phase 2: Acquisition and Native Surfaces

- [x] 2.1 Create `contents/ui/UsageController.qml` with POSIX-quoted absolute path followed exactly by `usage --provider all --format json --json-only`, one request-scoped DataSource/generation, queued refresh, and non-committing failures.
- [x] 2.2 Replace incrementally in `contents/ui/main.qml` with `PlasmoidItem` lifecycle, timer/manual refresh, committed-snapshot states, and native compact representation; retain data while refresh fails.
- [x] 2.3 Create `contents/ui/ProviderRow.qml` for CLI-order provider windows, raw source/reset text, themed fallback icon, accessible labels, and compact elision.
- [x] 2.4 Create `contents/ui/ErrorSummary.qml` with keyboard-operable counted disclosure, at most 20 rendered failures, and omitted-count text; wire one scrollable popup in `main.qml`.

## Phase 3: Configuration, Verification, and Scope Gate

- [x] 3.1 Reduce `contents/config/main.xml` and `contents/ui/config/configGeneral.qml` to `/home/ginopc/.local/bin/codexbar` absolute-path validation and positive refresh interval; remove provider/source/cost/display controls.
- [x] 3.2 Update `README.md` with external CLI boundary and manual OpenCode Go cookie-sync prerequisite; state exclusions: cost, charts, switching, auth/cookie automation, provider implementation, probing, reset/account actions.
- [x] 3.3 Run fixtures plus `kpackagetool6` and `plasmawindowed` when available; record malformed/exit/timeout/no-data/mixed, narrow keyboard, light/dark, and exact-command results. Stop and reassess if the termination gate fails.
- [x] 3.4 Audit `contents/ui/`, `contents/config/`, and `README.md` for no provider/auth/fallback/reset implementation, no source remapping, and unchanged `metadata.json`, `contents/config/config.qml`, and provider assets.
