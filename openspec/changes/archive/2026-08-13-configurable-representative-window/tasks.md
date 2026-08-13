# Tasks: Configurable Representative Window

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 290–340 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | single PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Resolver + selector + component + settings surface + `main.qml` wiring + docs | PR 1 | `./scripts/run-qml-tests.sh` | Manual live-Plasma smoke per `docs/live-plasma-smoke.md` (plasmawindowed6 / `QT_QUICK_BACKEND=software`) | `contents/code/{PreferredWindow,UsageModel}.js`, `contents/ui/{ProviderRow,main,config/configGeneral}.qml`, `contents/config/main.xml`, modified/new test files, `docs/live-plasma-smoke.md` — revert together; `selectCompact`, provider tabs, CLI/lifecycle boundary unaffected |

## Phase 1: Resolver (RED → GREEN → REFACTOR)

- [x] 1.1 RED: Create `tests/PreferredWindowHarness.qml` (mirrors `tests/RequestTimeoutHarness.qml`) asserting `parse` accepts `"automatic"`, `"session"`, `"weekly"`, `"monthly"` and rejects everything else; `keyOrDefault` maps `undefined`, `null`, `""`, `"Weekly"`, `"WEEKLY"`, `" weekly"`, `"yearly"`, `123`, `NaN`, `["weekly"]` to `"automatic"`; `DEFAULT_KEY === "automatic"` — run and confirm it fails (module missing)
- [x] 1.2 GREEN: Create `contents/code/PreferredWindow.js` with `.pragma library`, `DEFAULT_KEY`, `VALID_KEYS`, `parse(value)`, `keyOrDefault(value)` exactly per design contract
- [x] 1.3 GREEN: Register `PreferredWindowHarness \` in the `qml6 -f` harness list in `scripts/run-qml-tests.sh`, next to `RequestTimeoutHarness` (no QtTest-list change needed)
- [x] 1.4 Run `./scripts/run-qml-tests.sh` and confirm `PreferredWindowHarness` passes

## Phase 2: Selector (RED → GREEN → REFACTOR)

- [x] 2.1 RED: Add `test_selectRepresentativeHonoursExplicitPreferredWindow` to `tests/UsageModelTest.qml` (weekly key → Weekly window; spec: "Explicit preferred window with a finite value")
- [x] 2.2 RED: Add `test_selectRepresentativeFallsBackWhenPreferredWindowIsNotFinite` (monthly key, non-finite Monthly → Session; spec: "Representative fallback order" generalized)
- [x] 2.3 RED: Add `test_selectRepresentativePerProviderFallbackIsIndependent` (one provider falls back, another keeps Monthly, same call key; spec: "Per-provider fallback under an explicit preference", "Preference is global, not per-provider")
- [x] 2.4 RED: Add `test_selectRepresentativeAutomaticMatchesLegacySingleArgument` asserting `selectRepresentative(w) === selectRepresentative(w, "automatic") === selectRepresentative(w, undefined) === selectRepresentative(w, "yearly")` by object identity across finite/non-finite/empty fixtures — highest-value backward-compat proof (spec: "Automatic preserves current default behavior")
- [x] 2.5 RED: Add `test_selectRepresentativeReturnsNullForNoFiniteWindowUnderAnyPreference` (spec: "Provider has no finite percentage", any preference value)
- [x] 2.6 RED: Add `test_selectCompactIsUnaffectedByPreferredWindow` asserting `selectCompact` output is byte-identical for the same fixtures regardless of preferred key — confirms `selectCompact` is never called/read/modified
- [x] 2.7 RED: Confirm the 3 pre-existing `selectRepresentative` (1-arg) cases are unmodified and currently pass; run the suite and confirm the 6 new cases fail (functions missing)
- [x] 2.8 GREEN: Add `preferredWindowKeys` map to `contents/code/UsageModel.js` (`session→primary`, `weekly→secondary`, `monthly→tertiary`)
- [x] 2.9 GREEN: Add `definitionForPreferred(preferredKey)`, `matchesDefinition(window, definition)`, `preferredFiniteWindow(windows, definition)` to `contents/code/UsageModel.js` exactly per design contract
- [x] 2.10 GREEN: Extend `selectRepresentative(windows, preferredKey)` in `contents/code/UsageModel.js` — optional 2nd param, falls through to unmodified `firstFiniteWindow` when no preferred finite match; `selectCompact` untouched
- [x] 2.11 Run `./scripts/run-qml-tests.sh`; confirm all `UsageModelTest.qml` cases (new and the 3 pre-existing 1-arg cases) pass green

## Phase 3: Component (RED → GREEN → REFACTOR)

- [x] 3.1 RED: Add `preferredWeeklyRow` to `tests/ProviderRowHarness.qml` — Session+Weekly finite, `preferredWindowKey: "weekly"` → exactly one bar, `representativeWindow.label === "Weekly"`
- [x] 3.2 RED: Add `preferredFallbackRow` — `preferredWindowKey: "monthly"`, Monthly non-finite → `label === "Session"`, still exactly one bar
- [x] 3.3 RED: Add `preferredIdentityOnlyRow` — `preferredWindowKey: "weekly"`, no finite window → zero `UsageWindowRow`s, zero `ProgressBar`s
- [x] 3.4 RED: Assert default `summaryRow.preferredWindowKey === "automatic"` and unchanged `summaryRow` rendering (backward-compat)
- [x] 3.5 RED: Add reactivity assertion — mutate `preferredWeeklyRow.preferredWindowKey = "session"` at runtime and re-assert the rendered label updates
- [x] 3.6 RED: Add styling-parity assertion — `preferredFallbackRow` and `preferredWeeklyRow` expose the same visible-detail count via `countVisibleUsageDetails` (spec: "Fallback bar has no special visual treatment")
- [x] 3.7 Run `./scripts/run-qml-tests.sh`; confirm `ProviderRowHarness` fails (property missing)
- [x] 3.8 GREEN: Add `property string preferredWindowKey: "automatic"` to `contents/ui/ProviderRow.qml`
- [x] 3.9 GREEN: Update `representativeWindow` binding in `contents/ui/ProviderRow.qml` to `UsageModel.selectRepresentative(root.windows, root.preferredWindowKey)` when `root.summary`; leave `displayedWindows`, accessibility, icon, elision, non-expansion untouched
- [x] 3.10 Run `./scripts/run-qml-tests.sh`; confirm `ProviderRowHarness` passes, including reactivity and styling-parity assertions

## Phase 4: Settings Surface (RED → GREEN → REFACTOR)

- [x] 4.1 RED: Add `test_preferredWindowControlIsDiscoverableAndDefaulted` to `tests/SettingsInteractionTest.qml` — pass `"cfg_preferredRepresentativeWindow": "automatic"` in `createObject`; assert control findable by `objectName: "preferredRepresentativeWindow"`, `currentIndex === 0`, `cfg_preferredRepresentativeWindow === "automatic"`, guidance label visible with non-empty `Accessible.name`
- [x] 4.2 RED: Add `test_preferredWindowSelectionPersistsKeys` — keyboard/mouse-select each option → `cfg_preferredRepresentativeWindow` becomes `"session"`/`"weekly"`/`"monthly"`
- [x] 4.3 RED: Add `test_preferredWindowIsIndependentFromTimeout` — changing the new control leaves `cfg_requestTimeout`/`cfg_refreshInterval` untouched
- [x] 4.4 RED: Extend `test_tabTraversalUsesNativeFocus` with one appended `keyClick(Qt.Key_Tab)` → `preferredWindowControl.activeFocus` (tab order: CLI path → refresh interval → timeout preset → custom timeout → representative window)
- [x] 4.5 RED: Note the `cfg_preferredRepresentativeWindow` alias binds to a custom child property (`preferredWindow.selectedKey`), not a native control property — flagged design risk #1; confirm all 4 new cases fail before any GREEN edit (control missing)
- [x] 4.6 GREEN: Add `<entry name="preferredRepresentativeWindow" type="String"><default>automatic</default></entry>` to `contents/config/main.xml`, inside `<group name="General">`, immediately after the `requestTimeout` entry
- [x] 4.7 GREEN: Add `cfg_preferredRepresentativeWindow` alias, `cfg_preferredRepresentativeWindowDefault`, `preferredWindowControl` alias, `preferredWindowGuidance` alias, `preferredWindowKeys` readonly array, `preferredWindowIndex(key)`, `preferredWindowKeyAt(index)` to `contents/ui/config/configGeneral.qml`, alongside the existing `requestTimeout*` members
- [x] 4.8 GREEN: Add the `QQC2.ComboBox` (`id: preferredWindow`, `objectName: "preferredRepresentativeWindow"`, `selectedKey` property, labeled `"Representative window:"`, `Accessible.name`/`Accessible.description`, `onActivated`/`onSelectedKeyChanged`/`Component.onCompleted` sync) to `contents/ui/config/configGeneral.qml`'s `Kirigami.FormLayout`, appended immediately after the `requestTimeout` `SpinBox`
- [x] 4.9 GREEN: Add the `PlasmaComponents.Label` guidance (`id: preferredWindowGuidanceLabel`, `objectName: "preferredWindowGuidance"`) to `contents/ui/config/configGeneral.qml`, appended after `requestTimeoutGuidanceLabel`
- [x] 4.10 Run `./scripts/run-qml-tests.sh`; confirm all 4 new `SettingsInteractionTest.qml` cases pass, with explicit re-check that the `cfg_preferredRepresentativeWindow` custom-alias binding round-trips (design risk #1 confirmed closed, not assumed)

## Phase 5: Plumbing (GREEN)

- [x] 5.1 GREEN: Add `import "../code/PreferredWindow.js" as PreferredWindow` to `contents/ui/main.qml`
- [x] 5.2 GREEN: Add `property string preferredWindowKey: PreferredWindow.keyOrDefault(Plasmoid.configuration.preferredRepresentativeWindow)` to `contents/ui/main.qml`, declared next to `requestTimeoutMs`
- [x] 5.3 GREEN: Wire `preferredWindowKey: root.preferredWindowKey` into the `All` `Repeater` delegate's `ProviderRow { summary: true, ... }` only in `contents/ui/main.qml`; leave the detail `ProviderRow` (`summary: false`) untouched
- [x] 5.4 Run `./scripts/run-qml-tests.sh` end-to-end; confirm full green with no regressions in `MainCompactHarness`, provider tabs, or CLI/lifecycle harnesses

## Phase 6: REFACTOR

- [x] 6.1 Add/confirm a cross-consistency assertion (in `PreferredWindowHarness.qml` or `UsageModelTest.qml`) that `PreferredWindow.VALID_KEYS`, the keys of `UsageModel.preferredWindowKeys` (plus `"automatic"`), and `configGeneral.qml`'s `preferredWindowKeys` array stay in agreement, to catch future key-list drift
- [x] 6.2 Update `docs/live-plasma-smoke.md`: setting reachable by keyboard and labeled; Automatic reproduces prior `All` rendering; Weekly/Monthly change every eligible row; a provider lacking the window still shows a bar with its own label; panel badge unchanged; Breeze Light/Dark readability
- [x] 6.3 Run `./scripts/run-qml-tests.sh` full suite one final time; confirm all green
- [x] 6.4 Run `git diff --check`; verify no whitespace errors
