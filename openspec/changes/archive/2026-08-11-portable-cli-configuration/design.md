# Design: Portable CLI Configuration

## Technical Approach

Keep `UsageController` as the sole process/lifecycle owner and add a pure resolver helper. Empty or invalid configuration enters bounded discovery through the existing executable `DataSource`; a valid saved path is checked first and remains authoritative. `main.qml` persists a discovered executable before the unchanged `usage --provider all --format json --json-only` request. Failure sets Plasma's configuration-required state and retains snapshots.

## Architecture Decisions

| Option | Tradeoff | Decision |
|---|---|---|
| PATH lookup or filesystem scan | Convenient but environment-dependent and unbounded | Reject; evaluate only the four specified candidates in order. |
| Read all environment values in QML | Requires a new bridge or broad exposure | Reject; one constant shell probe expands only `${HOME-}` and `${HOMEBREW_PREFIX-}` in double quotes, checks absolute form, and never interpolates their values into command source. |
| Separate discovery process API | Cleaner abstraction but adds a process owner | Reject; reuse `preflightDataSource`, generation guards, watchdog, and disconnect behavior. |
| Controller writes KConfig | Couples process logic to Plasma | Emit `pathDiscovered(path)`; `main.qml` validates/persists it and suppresses the resulting duplicate refresh. |
| Custom setup dialog | More UI and tests | Use `Plasmoid.configurationRequired`, actionable popup text, and the native KCM form. |

## Data Flow

    saved KConfig path -> absolute check -> test -x
          valid ---------------------------> unchanged usage request
          invalid/empty -> ordered probe -> first valid -> persist -> usage request
                                  no match -> configurationRequired + retained snapshot

The constant probe checks `$HOME/.local/bin/codexbar`, `/usr/local/bin/codexbar`, `/usr/bin/codexbar`, then `$HOMEBREW_PREFIX/bin/codexbar` only for a defined absolute prefix. Every candidate passes `test -x`; `printf` returns only the winner. Plasma runs no `env`, `printenv`, `command -v`, `findExecutable`, PATH lookup, or directory enumeration.

## File Changes

| File | Action | Description |
|---|---|---|
| `contents/code/CodexBarPathResolver.js` | Create | Pure absolute-path validation, shell quoting, and constant ordered probe construction. |
| `contents/config/main.xml` | Modify | Change `codexbarCommand` default to empty; existing KConfig values remain intact. |
| `contents/ui/UsageController.qml` | Modify | Update `requestRefresh`, `startPathCheck`, and `handlePreflight`; add discovery stage, `configurationRequired`, and `pathDiscovered(path)` without changing command/lifecycle semantics. |
| `contents/ui/main.qml` | Modify | Remove author fallback, persist discovered paths, suppress self-induced refresh, and bind native configuration-required feedback. |
| `contents/ui/config/configGeneral.qml` | Modify | Remove author placeholder/reset, allow empty discovery state, and add accessible setup guidance. |
| `tests/CodexBarPathResolverHarness.qml` | Create | Deterministic resolver/order/adversarial contract tests. |
| `tests/UsageControllerFixture.qml`, `tests/UsageControllerPreflightHarness.qml`, `tests/UsageControllerPathCheckHarness.qml`, `tests/SettingsInteractionTest.qml`, `scripts/run-qml-tests.sh` | Modify | Cover migration, fallback, persistence signal, snapshots, settings, and register the harness. |
| `README.md`, `docs/live-plasma-smoke.md` | Modify | Progressive setup, external auth/OpenCode Go, terminal-only `command -v`, verification, invalid-path/timeout recovery, and live migration checks. |

## Interfaces / Contracts

`CodexBarPathResolver` exposes `validateAbsolutePath(path)`, `pathCheckCommand(path)`, and `discoveryCommand()`. `UsageController` adds read-only `configurationRequired`, internal `effectiveCommandPath`, signal `pathDiscovered(string path)`, and test-only `discoveredPathForTest`. Discovery output requires exit zero and one absolute line-break-free path from the `test -x` probe. CLI argv, provider model, timeout, coalescing, stale-response, and snapshots do not change.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit | Exact order; undefined/relative prefixes; quoting; first winner | RED resolver harness with injected probe outcomes and exact source assertions. |
| Integration | Valid saved path skips discovery; invalid/empty falls back; no match blocks usage; snapshots survive | Extend QtTest/controller harnesses and executable preflight fixtures. |
| UI/E2E | Empty default, accessible guidance, automatic persistence, live upgrade recovery | Settings QtTest plus documented `plasmawindowed` smoke in both Breeze themes. |

## Threat Matrix

| Boundary | Applicability | Safe/failure behavior | Planned RED tests |
|---|---|---|---|
| CodexBar shell/process discovery | Applicable | Constant command, quoted variable expansion, absolute plus `test -x`; malformed/undefined/non-executable values skip and ultimately fail closed | Metacharacters, spaces, line breaks, relative/undefined prefixes, multiple winners, no winner |
| Documentation-like paths | N/A: docs are never classified or executed | — | — |
| Git repository selection | N/A: no VCS commands | — | — |
| Commit state | N/A: no commit automation | — | — |
| Push state | N/A: no push automation | — | — |
| PR commands | N/A: no PR automation | — | — |

## Migration / Rollout

Changing the schema default affects only absent keys. Valid saved paths remain unchanged; invalid saved paths are replaced only after successful discovery and remain visible when discovery fails. Prior snapshots are never cleared. Roll out as one backward-compatible change; rollback disables resolver/UI behavior while retaining the empty default, restoring manual configuration without reintroducing the author path.

## Review Workload

Forecast 500–700 authored changed lines: low risk under the approved 800-line budget and suitable for one PR. With `ask-on-risk`, tasks/apply must pause if scope grows beyond 800 lines.

## Open Questions

None.
