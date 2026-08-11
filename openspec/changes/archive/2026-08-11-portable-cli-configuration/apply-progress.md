# Apply Progress: Portable CLI Configuration

## Delivery Context

- Strategy: `auto-chain`; chain strategy: `stacked-to-main`.
- Current slice: 3 — Documentation and final proof.
- The final-proof attempt was blocked on a maintainer decision; the maintainer authorized a separate harness-only remediation, after which a fresh native attempt was reset and acquired for this bounded work unit.
- Slice 1 native authored delta: 251 lines (under its 300-line attempt bound; OpenSpec evidence excluded).
- Slice 2 remains within the supplied 300-line native attempt bound; OpenSpec and unrelated historical/untracked artifacts were excluded.

## Completed Tasks

- [x] 1.1 RED resolver order and source contract harness.
- [x] 1.2 RED adversarial resolver input and fail-closed coverage.
- [x] 1.3 GREEN pure `CodexBarPathResolver` implementation.
- [x] 1.4 RED controller recovery, snapshot retention, and preflight harness coverage.
- [x] 1.5 GREEN controller discovery state and preserved usage lifecycle integration.
- [x] 2.1 RED settings coverage for an empty default, no author fallback, empty persistence, and accessible setup guidance.
- [x] 2.2 GREEN empty `codexbarCommand` KConfig default without changing existing stored values.
- [x] 2.3 GREEN main persistence of validated discoveries, duplicate-refresh suppression, and native `configurationRequired` binding.
- [x] 2.4 GREEN native Kirigami configuration-first guidance without dialogs or automation.
- [x] 2.5 REFACTOR focused resolver, controller, settings, and executable path-check coverage.
- [x] 3.2 README configuration-first setup and recovery guidance.
- [x] 3.3 Live Plasma smoke recovery, keyboard, and Breeze evidence guidance.
- [x] 3.1 Register the resolver harness, align legacy controller harnesses with discovery fallback, and pass the full runner.
- [x] 3.4 Verify the portability non-goals against the final diff.

## Work Unit Evidence

| Work unit | Focused test command and exact result | Runtime harness command/scenario and exact result | Rollback boundary |
|---|---|---|---|
| Slice 1 — Resolver and controller recovery | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/CodexBarPathResolverHarness.qml` → exit 0; resolver order, quoting, path validation, and no-scan assertions passed. `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software /usr/lib/qt6/bin/qmltestrunner -input tests/UsageControllerFixture.qml -import .` → exit 0; 15 passed, 0 failed. | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/UsageControllerPreflightHarness.qml` and `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/UsageControllerPathCheckHarness.qml` → both exit 0; invalid/non-executable paths completed discovery failure without usage requests. | Revert `contents/code/CodexBarPathResolver.js`, `contents/ui/UsageController.qml`, and the four focused harnesses; this removes discovery/recovery behavior without touching settings UX, schema, main UI, documentation, or historical lifecycle work. |
| Slice 2 — KConfig and native setup UX | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software /usr/lib/qt6/bin/qmltestrunner -input tests/SettingsInteractionTest.qml -import .` → exit 0; 8 passed, 0 failed. `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software /usr/lib/qt6/bin/qmltestrunner -input tests/UsageControllerFixture.qml -import .` → exit 0; 16 passed, 0 failed. Resolver and real executable path-check harnesses also exited 0. `git diff --check` → exit 0. | `plasmawindowed org.kde.plasma.kodexbar.plasma` → launched successfully (`qml: 0`) and stayed in its expected event loop for 20 seconds; the bounded interactive smoke process was then stopped by its harness timeout, with no crash output. | Revert `contents/config/main.xml`, `contents/ui/main.qml`, `contents/ui/config/configGeneral.qml`, `tests/SettingsInteractionTest.qml`, and the callback-dispatch additions to `contents/ui/UsageController.qml` / `tests/UsageControllerFixture.qml`; this removes configuration-first persistence and KCM guidance while preserving slice 1 resolver behavior and unrelated lifecycle work. |
| Slice 3 — Documentation and final proof | Documentation acceptance: RED 10 failures → GREEN 12 checks passed. Resolver harness direct run → exit 0. `git diff --check` → exit 0. Full `./scripts/run-qml-tests.sh` → exit 0 after the approved harness-only remediation. | `timeout 20s plasmawindowed org.kde.plasma.kodexbar.plasma` → launched and remained in the expected event loop; bounded smoke stopped without crash output. Full runner passed all listed QtTest and QML harnesses. Settings tests still emit the known offscreen `i18n`/`i18np` warnings while passing. | Revert `README.md`, `docs/live-plasma-smoke.md`, `scripts/run-qml-tests.sh`, and the resolver registration; leave slices 1–2 intact. The two harness-only updates revert independently as remediation. |

## TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 1.1–1.2 | `tests/CodexBarPathResolverHarness.qml` | Unit | N/A (new) | ✅ Missing resolver import exited 2 | ✅ `qml6` exit 0 | ✅ Valid absolute path plus relative, line-break, metacharacter, bounded-order/no-scan cases | ➖ None needed |
| 1.3 | `tests/CodexBarPathResolverHarness.qml` | Unit | N/A (new) | ✅ Missing resolver import exited 2 | ✅ `qml6` exit 0 | ✅ 10 behavioral assertions across valid and invalid paths/source | ➖ None needed |
| 1.4 | `tests/UsageControllerFixture.qml`, `tests/UsageControllerPreflightHarness.qml`, `tests/UsageControllerPathCheckHarness.qml` | Integration | ✅ 12 fixture tests plus both harnesses exited 0 | ✅ New properties/scenarios failed: fixture 3 failures | ✅ Fixture: 15 passed, 0 failed; both harnesses exit 0 | ✅ Valid saved, empty/invalid discovery, and no-match retained-snapshot paths | ➖ None needed |
| 1.5 | `tests/UsageControllerFixture.qml` | Integration | ✅ 12 fixture tests plus both harnesses exited 0 | ✅ New controller recovery scenarios failed before implementation | ✅ Fixture: 15 passed, 0 failed; both harnesses exit 0 | ✅ Saved-path skip, recovered path usage boundary, and fail-closed no-match behavior | ➖ None needed |
| 2.1 | `tests/SettingsInteractionTest.qml` | Integration | ✅ 7 passed, 0 failed before changes | ✅ New test could not discover the old author-path placeholder | ✅ 8 passed, 0 failed | ✅ Empty persistence, relative rejection, author-placeholder absence, and setup-guidance accessibility | ➖ None needed |
| 2.2 | `tests/SettingsInteractionTest.qml` | Integration | ✅ 7 passed, 0 failed before changes | ✅ Empty-default settings scenarios failed before schema/KCM changes | ✅ 8 passed, 0 failed | ✅ Empty default plus invalid relative reset to empty behavior | ➖ Structural schema default; no refactor needed |
| 2.3 | `tests/UsageControllerFixture.qml` | Integration | ✅ 15 passed, 0 failed before changes | ✅ New preflight callback dispatch test failed because `deliverPreflightDataForTest` did not exist | ✅ Fixture: 16 passed, 0 failed | ✅ Failed saved preflight transitions to discovery; validated discovered path starts its existing preflight path-check | ✅ Centralized shared DataSource dispatch without changing generation/source guards |
| 2.4 | `tests/SettingsInteractionTest.qml` | Integration | ✅ 7 passed, 0 failed before changes | ✅ Setup-guidance discovery assertion failed before KCM guidance | ✅ 8 passed, 0 failed | ✅ Guidance visibility and accessible name under empty configuration | ➖ None needed |
| 2.5 | Focused resolver/controller/settings harnesses | Integration | ✅ Prior focused tests passed | ✅ N/A — refactor task used approval coverage | ✅ Resolver harness, controller fixture, settings fixture, and real path-check harness all passed | ✅ Existing quoting/validation ownership remains in `CodexBarPathResolver`; callback dispatch extracted with behavior retained | ➖ None needed |
| 3.1 | `scripts/run-qml-tests.sh`, `tests/CodexBarPathResolverHarness.qml`, legacy controller harnesses | Integration | ✅ Full runner passed after bounded harness remediation | ✅ Resolver harness registration was absent before slice 3 | ✅ Full runner exit 0; resolver harness included | ✅ Legacy harnesses now assert discovery fallback and configuration-required behavior | ➖ Harness-only alignment; no production behavior change |
| 3.2–3.3 | `README.md`, `docs/live-plasma-smoke.md` | Documentation | ✅ Existing docs remained readable | ✅ Documentation acceptance initially found 10 missing checks | ✅ 12 acceptance checks passed | ✅ Recovery, keyboard, Breeze, credentials, and external setup evidence documented | ➖ None needed |
| 3.4 | Final source diff and full runner | Integration | ✅ Full runner and `git diff --check` passed | ✅ N/A — non-goal review | ✅ No provider/auth automation, PATH lookup, scanning, arbitrary probes, CLI argv, lifecycle, timeout, or refresh semantic changes found | ✅ Diff review plus full runner | ➖ None needed |

## Preserved Boundaries

- Usage remains exactly `usage --provider all --format json --json-only`.
- The existing `UsageController` remains the sole process owner and retains DataSource stages, generation guards, watchdog, coalescing, timeout, provider, auth, and snapshot handling.
- Discovery remains a single constant shell probe limited to approved candidates; it performs no `PATH` lookup, `command -v`, scanning, or arbitrary executable probing.
- Phase 2 adds no dialogs, provider/auth/setup automation, documentation, harness registration, or lifecycle changes.
- Phase 3 adds only documentation, resolver-harness registration, smoke guidance, and non-goal checks; it does not change provider/auth automation, inherited `PATH`, scanning, arbitrary probes, CLI argv, lifecycle, timeout, or refresh semantics.

## Remaining Tasks

- No remaining implementation tasks in the current 14-task change; proceed to independent verification.

## Next Recommended Slice

- Run the independent SDD verification phase; preserve the known offscreen i18n warnings as non-blocking evidence unless the verifier finds a regression.

## Correction Continuation: Verification Blockers

### Completed Correction Scope

- Preserved the live `root.codexbarCommand` KConfig binding by removing the imperative assignment in `onPathDiscovered`. The handler now persists only through `Plasmoid.configuration.codexbarCommand` while keeping duplicate-refresh suppression unchanged.
- Extended `CodexBarPathResolverHarness.qml` with deterministic executable-DataSource scenarios that run the resolver's exact approved command. Temporary fixtures prove: two executable candidates select the first (`$HOME/.local/bin/codexbar` before Homebrew); undefined and relative `HOMEBREW_PREFIX` values produce no candidate; and missing fixture paths cause real shell `test -x` failures and fail closed.
- No production discovery, CLI argv, lifecycle, timeout, refresh, provider, authentication, PATH lookup, scanning, or arbitrary probing behavior changed.

## Correction Work Unit Evidence

| Work unit | Focused test command and exact result | Runtime harness command/scenario and exact result | Rollback boundary |
|---|---|---|---|
| Verification-blocker correction | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/CodexBarPathResolverHarness.qml` → exit 0. `./scripts/run-qml-tests.sh` → exit 0: UsageModel 8 passed, UsageControllerFixture 16 passed, SettingsInteraction 8 passed, and all registered harnesses completed. `git diff --check` → exit 0. | The resolver harness uses `Plasma5Support.DataSource` to execute `Resolver.discoveryCommand()` inside a bounded `mktemp -d` fixture. It proves two real executable fixture paths choose `$HOME/.local/bin/codexbar`; undefined and relative Homebrew prefixes exit non-zero with no output; and missing fixture paths exercise real shell `test -x` failure and exit non-zero with no output. | Revert the single persistence assignment removal in `contents/ui/main.qml` and the runtime fixture scenarios in `tests/CodexBarPathResolverHarness.qml`; this leaves resolver production behavior, controller lifecycle, CLI argv, settings UX, and prior slices intact. |

## Correction TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 1.1–1.2, 1.4 | `tests/CodexBarPathResolverHarness.qml` | Integration | ✅ Existing resolver, real path-check, and compact harnesses exited 0 before edits. This is not a claimed pre-change safety net for the new runtime cases. | ⚠️ The correction adds missing executable coverage to already-correct resolver production behavior; its new scenarios passed on first execution, so there is no honest failing production RED result. | ✅ Focused harness exit 0; the exact resolver command ran against bounded fixtures. | ✅ Multiple executable candidates, undefined prefix, relative prefix, and real missing-path `test -x` failure each exercise distinct runtime outcomes. | ➖ None needed. |
| 2.3 | `tests/CodexBarPathResolverHarness.qml` plus full QML runner | Integration | ✅ Existing resolver, real path-check, and compact harnesses exited 0 before edits; no claim is made that a pre-change harness covered the live Plasma binding. | ✅ The reported defect was reproduced by the imperative assignment that overwrote the binding; the correction removes only that assignment before GREEN verification. | ✅ Full runner exit 0 with protected lifecycle and controller contracts unchanged. | ➖ Live KConfig mutation requires Plasma package context; the code preserves the declarative binding by construction and the full runner protects the surrounding controller behavior. | ➖ Minimal one-line correction; no refactor needed. |

## Correction Notes

- The prior slice evidence above is retained unchanged. This continuation supersedes only its incomplete runtime-coverage claims.
- Known offscreen `i18n`/`i18np` `ReferenceError` warnings continue during SettingsInteraction while all 8 cases pass.
- No task checkbox was changed: the existing tasks were already marked complete, and this evidence now genuinely satisfies the verifier's missing runtime coverage requirements.
