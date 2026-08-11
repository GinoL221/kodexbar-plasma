# Tasks: Portable CLI Configuration

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | 500–700 authored lines |
| 400-line budget risk | High |
| 800-line project budget risk | Low |
| Chained PRs recommended | No (within approved 800-line budget) |
| Suggested split | Single PR; commit work units 1–3 independently |
| Delivery strategy | auto-chain (resolved for slice 1) |
| Chain strategy | stacked-to-main |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: stacked-to-main
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Resolver and controller recovery | Single PR | `qml6 --software -f tests/CodexBarPathResolverHarness.qml` | `qml6 --software -f tests/UsageControllerPathCheckHarness.qml` | Resolver/controller changes only |
| 2 | KConfig and native setup UX | Single PR | `qmltestrunner -input tests/SettingsInteractionTest.qml -import .` | `plasmawindowed org.kde.plasma.kodexbar.plasma` | Schema/main/KCM changes only |
| 3 | Documentation and final proof | Single PR | `./scripts/run-qml-tests.sh` | `docs/live-plasma-smoke.md` checklist | README/smoke guidance only |

## Phase 1: Resolver and Safe Recovery

- [x] 1.1 **RED** Create `tests/CodexBarPathResolverHarness.qml`: assert exact candidate order, first winner, no `PATH`/scan, and `test -x` source.
- [x] 1.2 **RED** Add adversarial cases: spaces, metacharacters, line breaks, undefined/relative Homebrew prefix, non-executable candidates, and no winner fail closed.
- [x] 1.3 **GREEN** Create `contents/code/CodexBarPathResolver.js` with `validateAbsolutePath`, `pathCheckCommand`, and constant `discoveryCommand`.
- [x] 1.4 **RED** Extend `tests/UsageControllerFixture.qml` and preflight/path-check harnesses: saved valid skips discovery; empty/invalid discovers; no match blocks usage and retains snapshots.
- [x] 1.5 **GREEN** Update `UsageController.qml` `requestRefresh`, `startPathCheck`, `handlePreflight`, `configurationRequired`, `effectiveCommandPath`, `pathDiscovered`, and test hooks; preserve exact usage argv, watchdog, coalescing, and stale guards.

## Phase 2: Configuration-first Plasma UX

- [x] 2.1 **RED** Update `tests/SettingsInteractionTest.qml` for empty default, no author placeholder/reset, accessible manual setup guidance, and empty input persistence.
- [x] 2.2 **GREEN** Set `contents/config/main.xml` `codexbarCommand` default empty without altering stored values.
- [x] 2.3 **GREEN** Update `contents/ui/main.qml`: remove fallback; persist only validated `pathDiscovered`; suppress its self-induced duplicate refresh; bind `Plasmoid.configurationRequired` and retained-snapshot guidance.
- [x] 2.4 **GREEN** Update `contents/ui/config/configGeneral.qml` for empty discovery state and native Kirigami accessible setup text; do not add dialogs or CLI automation.
- [x] 2.5 **REFACTOR** Run resolver/controller/settings focused tests; remove duplicated quoting/validation only where behavior remains identical.

## Phase 3: Evidence and Documentation

- [x] 3.1 Register `CodexBarPathResolverHarness.qml` in `scripts/run-qml-tests.sh`; run `./scripts/run-qml-tests.sh` and `git diff --check`.
- [x] 3.2 Update `README.md` with configuration-first setup, terminal-only `command -v codexbar`, absolute-path verification, external credentials/OpenCode Go, and invalid-path/timeout recovery.
- [x] 3.3 Update `docs/live-plasma-smoke.md` with first-run discovery, valid-path upgrade, failed recovery/snapshot, keyboard, and BreezeLight/BreezeDark evidence.
- [x] 3.4 Verify non-goals: no provider/auth/setup automation, inherited `PATH`, scanning, arbitrary probes, CLI argv, lifecycle, timeout, or refresh semantic changes.

## Rollback Boundary

Revert Units 1–2 together to remove discovery and configuration-required UX while retaining the empty schema default; valid saved absolute paths and the exact CLI contract remain compatible. Unit 3 documentation reverts independently.

## Correction Continuation Evidence

- Task 2.3 remains complete: `main.qml` now persists a discovered path through `Plasmoid.configuration.codexbarCommand` only, preserving the live `root.codexbarCommand` binding and existing duplicate-refresh suppression.
- Tasks 1.1–1.2 now have runtime evidence: the resolver harness executes the approved resolver command with bounded temporary fixtures, proving the earliest of two executable fixture candidates wins and undefined or relative `HOMEBREW_PREFIX` values fail closed.
- Task 1.4 now has runtime evidence: the same harness executes real shell `test -x` checks against missing bounded fixture paths and proves they fail closed without a candidate.
- `./scripts/run-qml-tests.sh` and `git diff --check` both exit 0 for this continuation. The known offscreen `i18n`/`i18np` warnings remain non-blocking.
