# Design: Single-Product Transition and Responsive UI

## Technical Approach

Deliver one bounded work unit: clarify the parallel-package transition, establish constrained-width behavior through RED tests, then change only the current product's reusable usage-window layout. `ProviderRow.qml` remains the composition boundary; `UsageWindowRow.qml` alone owns label/bar/percentage geometry. Runtime identity, settings, data selection, lifecycle, and command execution remain untouched.

## Architecture Decisions

| Option | Tradeoff | Decision |
|---|---|---|
| Single responsive row using QtQuick Layouts | Requires relocating the existing bar, but gives one width allocator | Chosen: an elidable window-label slot and native `QQC2.ProgressBar` yield space; the percentage reserves its full implicit width and never elides. |
| Width arithmetic or breakpoints | Adds fragile font/theme assumptions | Rejected; rely on `RowLayout`, zero shrink minimum for elidable text, `Layout.fillWidth`, and Kirigami spacing. |
| Change `ProviderRow` or popup sizing | Broadens impact across provider identity and scrolling | Rejected; width continues to flow through the existing fill-width composition. |
| Automatic legacy migration | Could reduce manual steps but requires unsafe Plasma containment/config mutation | Rejected; document coexistence and adding a new widget manually. |

## Component Boundaries and Data Flow

    main.qml popup width
      → ProviderRow (identity + window composition; unchanged)
        → UsageWindowRow (responsive geometry only)
          → label | progress fills remainder | full percentage

`UsageModel`, `UsageController`, `CompactUsageButton`, configuration QML/XML, metadata, and legacy package/UI are outside this unit. The finite-value predicate and raw displayed value remain unchanged.

## File Changes

| File | Action | Description |
|---|---|---|
| `README.md` | Modify | Identify legacy/current IDs; document install/update, add-new-widget, coexistence, and optional manual settings copy. |
| `docs/live-plasma-smoke.md` | Modify | Add transition and narrow-popup live checks without package removal or panel mutation. |
| `tests/ProviderRowHarness.qml` | Modify | Add fail-first constrained and wider geometry assertions for direct, summary, and provider-composed rows. |
| `contents/ui/UsageWindowRow.qml` | Modify | Use native layout constraints to reserve percentage width and let the progress bar consume the remainder. |

## Interfaces / Contracts

- Current package ID remains `org.kde.plasma.kodexbar.plasma`; legacy `org.kde.plasma.kodexbar` may coexist.
- Users add a new **KodexBar Plasma** widget. Optional copying is manual, per instance, for `codexbarCommand`, refresh interval, request timeout, and representative window; destination `General` settings remain independent.
- Execution remains exactly `usage --provider all --format json --json-only`.
- For each finite percentage: `paintedWidth <= label.width`, all visible children stay within row bounds, bar width is positive at the admitted constrained fixture width, and increasing row width increases bar width by the available delta. Non-finite and compact behavior remain unchanged.

## Testing Strategy and Validation Order

| Stage | Evidence |
|---|---|
| Baseline | Run `./scripts/run-qml-tests.sh`; record unrelated historical lifecycle status without changing it. |
| RED | Add constrained-width fixtures and bounds/painted-width/bar-growth assertions; the same command must fail on responsive assertions. |
| GREEN | Apply only `UsageWindowRow.qml` geometry constraints; rerun the same command to green. Existing command-argv coverage must still pass. |
| Static/package | Run `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, then `git diff --check`; confirm protected metadata, config, controller, and legacy files are unchanged. |
| Live | Run `plasmawindowed org.kde.plasma.kodexbar.plasma`; check narrow/wider popup geometry in Breeze Light/Dark and verify both package instances remain independent. |

The planned authored diff is expected below 400 lines. Under `ask-on-risk`, stop for a delivery decision before implementation if task planning forecasts exceeding that budget.

## Threat Matrix

N/A — this unit does not change routing, shell commands, subprocesses, VCS/PR automation, executable classification, or process integration. Existing command behavior is regression-checked only.

## Migration / Rollout and Rollback

No automated migration. Documentation leads with the safe path: install/update the current package, add a new widget, optionally re-enter four settings, verify, and leave legacy packages/instances untouched. Roll back by reverting the four file changes; no stored data, package identity, or panel containment requires restoration.

## Open Questions

None.
