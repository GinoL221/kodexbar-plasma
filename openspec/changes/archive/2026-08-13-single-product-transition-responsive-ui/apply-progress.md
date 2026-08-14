# Apply Progress: Single-Product Transition and Responsive UI

## Status

- Attempt: maintainer-approved generation-2 retry (`sha256:2beef03efaea6ad758e9102145f3525d33073f6b641ea71acfde5dd3f15f0dec`)
- Mode: Strict TDD
- Delivery: `ask-on-risk`, single bounded work unit; 111 authored changed lines, below the 400-line budget.
- Completed tasks: 1.1–4.2. Task 4.2 is complete only for the maintainer-approved current-product dark-session narrow/wide live evidence; unobserved checks are tracked below as non-blocking follow-ups.

## TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 1.1–1.3 | Documentation review | Documentation | N/A | ✅ Guidance written before no production behavior change | ✅ Verified by diff and package-boundary checks | ➖ Structural guidance | ➖ None needed |
| 2.1–2.2 | `tests/ProviderRowHarness.qml` | QML integration harness | ✅ Baseline `./scripts/run-qml-tests.sh` passed: QtTest 44/44 plus all executable harnesses | ✅ Added direct, summary, and provider-composed constrained/wider assertions; suite failed at `ProviderRowHarness.qml` before layout change | ✅ Full suite passed after layout change | ✅ Direct, summary, and provider-composed rows at 120→180 widths | ✅ Removed broad recursive bound assertion in favor of concrete row geometry checks |
| 3.1–3.2 | `tests/ProviderRowHarness.qml` | QML integration harness | ✅ Baseline above | ✅ Existing vertical progress placement failed new positive-width/growth assertions | ✅ `./scripts/run-qml-tests.sh` passed; lifecycle argv guard stayed green | ✅ Same three row compositions and wider allocation | ✅ Kept geometry change only in `UsageWindowRow.qml` |
| 4.1 | Repository commands | Static/package verification | ✅ Full suite green | ➖ Verification task | ✅ Lint, package validation, and diff checks passed | ➖ N/A | ➖ None needed |

## Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test command | `./scripts/run-qml-tests.sh` — exit 0. QtTest: UsageModel 17/17, UsageControllerFixture 16/16, SettingsInteraction 11/11; all executable QML harnesses, including `ProviderRowHarness.qml` and lifecycle argv guard, passed. |
| RED command | `./scripts/run-qml-tests.sh` — exit 1 at `tests/ProviderRowHarness.qml` after responsive assertions were added, before `UsageWindowRow.qml` changed. |
| Runtime harness | `plasmawindowed org.kde.plasma.kodexbar.plasma` — started with no immediate error but remained interactive beyond the 30-second automation limit. Manual narrow/wider and Breeze Light/Dark observations remain required. |
| Static/package checks | `./scripts/lint-qml.sh` exit 0 (existing unqualified-access warnings only); `./scripts/validate-package.sh` exit 0; `git diff --check` exit 0. |
| Rollback boundary | Revert `README.md`, `docs/live-plasma-smoke.md`, `tests/ProviderRowHarness.qml`, and `contents/ui/UsageWindowRow.qml`; no packages, panel state, metadata, configuration, controller, compact UI, legacy UI, CLI, provider, auth/fetch, or lifecycle behavior was changed. |

## Files Changed

- `README.md` — coexistence, current-only install/update, add-new-widget, and optional manual per-instance `General` settings guidance.
- `docs/live-plasma-smoke.md` — safe coexistence and responsive narrow/wider live-check guidance.
- `tests/ProviderRowHarness.qml` — constrained and wider finite-percentage row coverage for direct, summary, and provider-composed rows.
- `contents/ui/UsageWindowRow.qml` — native `RowLayout` allocation reserves the percentage, makes label shrinkable, and lets the bar consume remaining width.

## Limitations

`plasmawindowed` is interactive and could not produce automated visual evidence within 30 seconds. The documented manual smoke procedure remains required for live Breeze Light/Dark, narrow/wider geometry, and independent installed instances.

## Maintainer-Approved Correction — Generation 4

- Scope: current-product provider-composition width propagation only; provider icon rendering remains explicitly out of scope under `backlog/provider-icon-rendering`.
- Diagnosis: `UsageWindowRow` already allocated its internal label, bar, and percentage responsively, but the `Repeater` delegate created by `ProviderRow` did not explicitly participate in the parent `ColumnLayout` width allocation. A real provider-composed popup could therefore leave the child at an implicit/narrow width while its percentage remained visible.
- Fix: `contents/ui/ProviderRow.qml` sets `Layout.fillWidth: true` and `Layout.minimumWidth: 0` on the `UsageWindowRow` delegate. This makes the delegate consume the provider composition's available width while preserving shrinkability in constrained popups.

### Correction TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| Provider-composed width propagation | `tests/ProviderRowHarness.qml` | QML integration harness | ✅ Baseline `./scripts/run-qml-tests.sh` passed: QtTest 44/44 and all executable harnesses | ✅ Added a provider-composed assertion requiring the child row to opt into parent width allocation; runner failed/hung at `ProviderRowHarness.qml` before production correction because the test did not complete | ✅ Added only delegate `Layout.fillWidth: true` and `Layout.minimumWidth: 0`; `./scripts/run-qml-tests.sh` exit 0 | ✅ Existing direct and summary rows retain constrained 120→180 width checks; provider-composed row now asserts parent-width equality and bar growth | ✅ No further refactor needed; the correction is two native layout properties at the composition boundary |

### Correction Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test command | `./scripts/run-qml-tests.sh` — exit 0. QtTest: UsageModel 17/17, UsageControllerFixture 16/16, SettingsInteraction 11/11; all executable QML harnesses, including `ProviderRowHarness.qml` and exact lifecycle argv guard, passed. |
| Runtime harness command/scenario | `./scripts/run-qml-tests.sh` executes the offscreen provider composition harness. It proves direct, summary, and provider-composed 120→180 geometry, including provider-child width equality and progress-bar growth. |
| Static/package checks | `./scripts/lint-qml.sh` exit 0 (pre-existing unqualified-access warnings only); `./scripts/validate-package.sh` exit 0; `git diff --check` exit 0. |
| Rollback boundary | Revert the correction hunks in `contents/ui/ProviderRow.qml` and `tests/ProviderRowHarness.qml`; no icon assets, legacy UI, package/configuration, panel state, lifecycle, CLI, provider model, auth, or fetch behavior is affected. |

### Correction Files Changed

- `contents/ui/ProviderRow.qml` — give each composed `UsageWindowRow` native layout fill-width participation with a zero minimum width.
- `tests/ProviderRowHarness.qml` — place the provider row in a real `ColumnLayout` and assert its child row and progress bar use and grow with the parent width.

## Maintainer-Approved Final Responsive Correction — Active Native Attempt Generation 5

- Scope: current-product `UsageWindowRow` distribution only. The generation-4 provider-composed delegate width propagation remains unchanged.
- Diagnosis: the label and progress `Loader` both accepted extra `RowLayout` width. At wider popup sizes that divided residual space and left the bar starting farther right than intended; at 120px the percentage could be pushed outside the row.
- Fix: the label now has an explicit implicit-width preferred and maximum bound plus a zero minimum so it elides only under constraint. `Layout.fillWidth` is retained solely to let QtQuick shrink that bounded label below its preferred width; it cannot consume width beyond `implicitWidth`. The `Loader` therefore receives every residual pixel after label, percentage, and spacing.
- Boundaries: no change to `ProviderRow.qml`, icon rendering, qmlls configuration, legacy UI, package identity, panel configuration, CLI, providers, auth/fetch, or lifecycle.

### Final Correction TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| Current-product responsive distribution | `tests/ProviderRowHarness.qml` | Offscreen QML integration harness | ✅ `./scripts/run-qml-tests.sh` exit 0 before the new assertions; QtTest 44/44 and all executable harnesses passed | ✅ Added direct, summary, and provider-composed assertions for visible finite percentages, bounded children, positive narrow bar width, preferred-width labels, and residual bar growth. The focused harness exited 1 before the layout correction: `direct constrained row: visible content must stay within row bounds`. | ✅ Added label preferred/maximum implicit-width constraints; focused `qml6 --software -f tests/ProviderRowHarness.qml` exit 0, then full runner exit 0. | ✅ Exercises direct, summary, and provider-composed rows at 120px then 600px, proving full percentages and bar growth in each composition. | ✅ Removed temporary diagnostic coordinates; final assertions remain behavioral geometry checks. |

### Final Correction Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test command | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/ProviderRowHarness.qml` — RED exit 1 before production change; GREEN exit 0 after the production change. |
| Full test command | `./scripts/run-qml-tests.sh` — exit 0. QtTest: UsageModel 17/17, UsageControllerFixture 16/16, SettingsInteraction 11/11; all executable harnesses including `ProviderRowHarness.qml` and the exact lifecycle argv guard passed. |
| Runtime harness command/scenario | The focused offscreen QML harness renders direct, summary, and `ProviderRow`-composed finite rows at narrow 120px and wider 600px allocations. It verifies visible percentages, bounded content, and progress-bar growth. |
| Static/package checks | `./scripts/lint-qml.sh` exit 0 with existing unqualified-access warnings only; `./scripts/validate-package.sh` exit 0; `git diff --check` exit 0. |
| Rollback boundary | Revert only the final-correction hunks in `contents/ui/UsageWindowRow.qml` and `tests/ProviderRowHarness.qml`; generation-4 provider delegate propagation and every excluded boundary remain intact. |

### Final Correction Files Changed

- `contents/ui/UsageWindowRow.qml` — bound the elidable label to its implicit width while retaining zero-minimum shrinkability, leaving residual row width to the progress loader.
- `tests/ProviderRowHarness.qml` — require visible percentages and residual progress-bar growth for direct, summary, and provider-composed rows from 120px to 600px.

## Maintainer-Approved Real Popup Correction — Active Native Attempt Generation 6

- Scope: current-product popup width chain and `UsageWindowRow` allocation only. Provider icon rendering remains separate under `backlog/provider-icon-rendering`; legacy UI, package identity, settings, CLI, providers, auth/fetch, lifecycle, and qmlls6 remain unchanged.
- Diagnosis: the real `ScrollView -> ColumnLayout -> ProviderRow -> UsageWindowRow` chain let the column follow the internal content item's implicit width instead of the `ScrollView` viewport. The provider row therefore did not receive the constrained popup width. Once the viewport chain was correctly constrained, the label could still claim more width than the progress bar at medium width.
- Fix: `main.qml` binds the popup `ScrollView` content width and child `ColumnLayout` width to the named scroll view's `availableWidth`. `UsageWindowRow.qml` bounds the elidable label with native Kirigami grid units and reserves a two-grid-unit minimum for the progress loader, preserving finite percentage width and usable bar space.

### Generation 6 TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| Real popup responsive composition | `tests/ProviderRowHarness.qml` | Offscreen QML integration harness | ✅ Existing focused harness exited 0 before the new real-popup assertions. | ✅ Added the real `ScrollView -> ColumnLayout -> ProviderRow -> UsageWindowRow` fixture. It exited 1 before production changes: `narrow popup composition: popup content must use the ScrollView viewport width`; after the viewport correction it exposed the real medium-width allocation failure (`bar=53, label=98`). | ✅ `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/ProviderRowHarness.qml` exited 0 after the minimum-bar and bounded-label correction. | ✅ Exercises narrow 120px, medium 220px, and wide 600px popup widths; each stage asserts viewport propagation, label/bar/percentage bounds, full percentage paint, positive bar width, and monotonic bar growth. Direct and summary responsive assertions remain active. | ✅ Removed only temporary debugging through failed-run output; final assertions remain geometry contracts. |

### Generation 6 Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test command | `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/ProviderRowHarness.qml` — RED exit 1; GREEN exit 0. |
| Full test command | `./scripts/run-qml-tests.sh` — exit 0. QtTest: UsageModel 17/17, UsageControllerFixture 16/16, SettingsInteraction 11/11; every executable harness, including `ProviderRowHarness.qml` and the exact lifecycle argv guard, passed. |
| Runtime harness command/scenario | The focused offscreen real-popup harness renders `ScrollView -> ColumnLayout -> ProviderRow -> UsageWindowRow` at 120px, 220px, and 600px. It proves the composed row uses viewport width; its label, progress bar, and percentage stay bounded; finite percentage text is fully painted; and the progress bar grows across both width increases. |
| Static/package checks | `./scripts/lint-qml.sh` exit 0 with existing unqualified-access warnings only; `./scripts/validate-package.sh` exit 0; `git diff --check` exit 0. |
| Rollback boundary | Revert generation-6 hunks in `contents/ui/main.qml`, `contents/ui/UsageWindowRow.qml`, and `tests/ProviderRowHarness.qml`; no package state, metadata, configuration, provider semantics, CLI, lifecycle, legacy UI, or icon behavior is affected. |

### Generation 6 Files Changed

- `contents/ui/main.qml` — constrain popup content and its layout column to the `ScrollView` viewport width.
- `contents/ui/UsageWindowRow.qml` — cap the elidable label with native grid-unit constraints and reserve a usable progress-bar minimum.
- `tests/ProviderRowHarness.qml` — add the real popup-chain offscreen integration fixture and narrow/medium/wide behavioral geometry assertions.

## Maintainer-Approved Scope Clarification — Active Native Attempt Generation 8

- Scope: task 4.2 is complete for the observed current-product dark-session responsive smoke only. The maintained live evidence shows the full `42% used` text at narrow and wider popup allocations, bounded row content and progress bar, and progress-bar growth at wider allocation.
- Evidence source: maintainer-provided live Plasma observation for `plasmawindowed org.kde.plasma.kodexbar.plasma`. This evidence round did not observe Breeze Light or independent installed legacy/current instances.
- Boundaries: this is an evidence-only artifact update. No product source, installed package, panel configuration, icon backlog, qmlls6 configuration, proposal, spec, or design artifact changed. No native attempt was acquired, begun, reset, or settled.

### Generation 8 TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 4.2 current-product dark-session live smoke | N/A — evidence-only task | Manual Plasma runtime observation | ✅ Existing focused and full QML evidence remains recorded above; no code was modified | N/A — no production behavior was added or changed | ✅ Maintainer-confirmed live observation: full `42% used`, bounded bar/content, and wider-allocation bar growth | ✅ Narrow and wider allocations were both observed in the dark session | N/A — no code refactor |

### Generation 8 Work Unit Evidence

| Evidence | Exact result |
|---|---|
| Focused test command | N/A — this authorized scope clarification changes only task/evidence artifacts and runs no code. Existing focused QML evidence remains preserved above. |
| Runtime harness command/scenario | `plasmawindowed org.kde.plasma.kodexbar.plasma` — maintainer-provided live dark-session observation at narrow and wider popup allocations confirmed full `42% used`, bounded row/bar content, and progress-bar growth at wider allocation. |
| Rollback boundary | Revert only the generation-8 entries in `openspec/changes/single-product-transition-responsive-ui/tasks.md` and `openspec/changes/single-product-transition-responsive-ui/apply-progress.md`; no product behavior changes. |

## Non-Blocking Follow-Ups (Not Claimed as PASS)

- Breeze Light live smoke was not observed in this evidence round and is not claimed as PASS.
- Independent legacy/current installed-instance verification was not observed in this evidence round and is not claimed as PASS.
