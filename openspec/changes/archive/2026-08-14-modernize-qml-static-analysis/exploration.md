## Exploration: modernize-qml-static-analysis

### Current State
The project is a Plasma 6 QML package with no `CMakeLists.txt`. Qt 6.11.1 is installed (`qmlls6` and `/usr/lib/qt6/bin/qmllint`), and Qt/KDE QML modules resolve from `/usr/lib/qt6/qml`. There is no `.qmlls.ini` or `.qmllint.ini`.

`./scripts/lint-qml.sh` is the production-QML lint entry point; it promotes import, missing-property, unresolved-alias, uncreatable-type, incompatible-type, required, and read-only-property diagnostics to errors. Its current run exits successfully but reports 88 warnings, all in the `unqualified` category. `./scripts/run-qml-tests.sh` is the authoritative QML test runner, not a CMake target; it passed with Qt 6.11.1.

The warning causes are distinct:

- **Plasma context properties:** `i18n`/`i18np` are injected by the Plasma runtime rather than declared QML members, so `qmllint` cannot resolve them. These calls must remain to retain KDE translation extraction; replacing them with `root.i18n`, `qsTr`, or a global suppression would be incorrect.
- **Fixable component structure:** nested delegates access outer IDs, properties, and functions (`root`, `controller`, `providerSelector`, `_selectAll`, `_selectProviderAt`) without bound-component semantics. Qt recommends `pragma ComponentBehavior: Bound` plus qualified outer access.
- **Fixable delegate context:** `ProviderSelector.qml` uses injected `index`; Qt 6.11.1 specifically requests `required property int index` for its `Repeater` delegate.

`contents/config/config.qml` also calls Plasma `i18n`, but it is outside the current lint glob and therefore is not included in the 88-warning count.

### Affected Areas
- `.qmlls.ini` — new root configuration: `no-cmake-calls=true` and the real `/usr/lib/qt6/qml` Qt/KDE import root for editor language-server analysis.
- `.qmllint.ini` — new explicit diagnostic policy, preserving strict errors and keeping `UnqualifiedAccess` visible rather than disabled.
- `scripts/lint-qml.sh` — align the authoritative lint command with the policy and decide whether `contents/config/config.qml` joins its lint target.
- `contents/ui/main.qml` — bind representation components and qualify outer `root`, `controller`, and `providerSelector` accesses.
- `contents/ui/ProviderSelector.qml` — add bound behavior, qualify root-owned helper calls, and declare the delegate `index` as required.
- `contents/ui/ProviderRow.qml`, `contents/ui/UsageWindowRow.qml`, `contents/ui/ErrorSummary.qml` — bind delegates/components and retain direct Plasma translation calls.
- `contents/ui/CompactUsageButton.qml`, `contents/ui/config/configGeneral.qml`, `contents/config/config.qml` — documented intentional `i18n`/`i18np` context-property diagnostics; no translation API substitution.
- `tests/MainCompactHarness.qml`, `tests/ProviderSelectorHarness.qml`, `tests/ProviderRowHarness.qml`, `tests/ErrorSummaryHarness.qml`, `tests/SettingsInteractionTest.qml` — execute unchanged behavioral coverage after component-context changes; extend only if a Bound/required-property regression is not already observable.
- `README.md` — update the lint/tooling guidance with the language-server setup, policy, intentional Plasma context warnings, and `./scripts/run-qml-tests.sh` as the test authority.

### Approaches
1. **Tooling configuration only** — add `.qmlls.ini` and leave current lint output unchanged.
   - Pros: Smallest diff; enables editor import resolution.
   - Cons: Leaves 88 warnings, obscuring future actionable diagnostics and does not adopt Qt 6 delegate guidance.
   - Effort: Low.

2. **Bound components with a narrow, explicit lint policy** — add non-CMake language-server configuration; introduce `.qmllint.ini` that retains existing error-level structural diagnostics and leaves only `UnqualifiedAccess` as visible warnings; fix every non-context unqualified access with `ComponentBehavior: Bound`, required delegate properties, and outer-ID qualification.
   - Pros: Removes actionable warnings without hiding Plasma runtime context diagnostics; improves delegate type safety; retains KDE translation extraction; keeps the existing runner authoritative.
   - Cons: Bound components change delegate context rules, so all affected harnesses must be run; some intentional `i18n`/`i18np` warnings remain visible.
   - Effort: Medium.

3. **Disable `unqualified` globally** — suppress the category in `.qmllint.ini`.
   - Pros: Quiet lint output.
   - Cons: Hides actual architecture and delegate regressions together with Plasma context-property limitations; contradicts the requested diagnostic discipline.
   - Effort: Low; rejected.

### Recommendation
Choose approach 2. Add `.qmlls.ini` with `no-cmake-calls=true` and `importPaths=/usr/lib/qt6/qml`; no build directory or CMake integration belongs here. Introduce a small `.qmllint.ini` that makes the current error policy explicit, keeps `UnqualifiedAccess=warning` (never `disable`), and documents the Plasma context-property exception in the policy/README.

Add `pragma ComponentBehavior: Bound` only to affected QML documents, declare `required property int index` in the `ProviderSelector` repeater delegate, and qualify all outer IDs/functions. Do not convert or wrap away `i18n`/`i18np`: their unresolved-context warnings are legitimate in standalone static analysis and their call shape is required for KDE translation extraction. Once the fixable subset is gone, visible `unqualified` diagnostics become a small, reviewable Plasma-context baseline rather than blanket noise.

Keep `./scripts/run-qml-tests.sh` unchanged as the test authority and run it with `./scripts/lint-qml.sh` after each structural slice. The expected implementation should fit the 400 changed-line review budget, but split configuration/docs from QML structural edits if the forecast exceeds it.

### Risks
- `ComponentBehavior: Bound` removes implicit delegate context; every model role used by a delegate must be declared as a required property, or runtime behavior can change.
- A broad `.qmllint.ini` suppression would hide future unqualified accesses; the policy must keep the category visible and document the specific Plasma context limitation.
- Changing `i18n`/`i18np` to silence static analysis can break KDE translation extraction or runtime localization.
- Expanding the lint glob to `contents/config/config.qml` adds an intentional context warning unless the baseline/documentation is updated at the same time.
- No CMake project metadata exists; CMake-oriented qmlls configuration would create false editor assumptions.

### Ready for Proposal
Yes — propose a tooling-and-structural-modernization change only. State explicitly that provider behavior, the external CLI integration and exact command, package identity, icon work, and the archived `single-product-transition-responsive-ui` change are out of scope.
