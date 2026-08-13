# Design: Configurable Representative Window

## Technical Approach

Keep normalization, the controller, the `codexbar` boundary, and `selectCompact` untouched. Add an optional second parameter to the pure `UsageModel.selectRepresentative` that names a preferred window; absent, `"automatic"`, or unrecognized reproduces today's Session → Weekly → Monthly first-finite order byte-for-byte. Persist the choice as one kcfg String, resolve it through a new `.pragma library` module mirroring `RequestTimeout.js`, thread it from `main.qml` into each `All` summary `ProviderRow` as one new string property, and expose it in the existing General page as a `cfg_`-aliased `QQC2.ComboBox` following the proven `requestTimeoutPreset` template.

Strict RED-GREEN-REFACTOR. Estimated 290–340 changed lines, within the 400-line review budget.

## Architecture Decisions

| Option | Tradeoff | Decision |
|---|---|---|
| Optional 2nd param on `selectRepresentative` | One signature change, but keeps ordering rules pure and unit-testable, and 1-arg callers are unaffected | **Chosen**: `selectRepresentative(windows, preferredKey)`; `preferredKey` omitted/`undefined` is identical to today. |
| New `selectPreferredRepresentative` function | No signature churn, but forks domain ordering across two functions and forces every call site to branch | Rejected. |
| Branch inside `ProviderRow.qml` | Fewer model lines, but duplicates ordering in QML layout code and is untestable via `UsageModelTest` | Rejected (same rationale as the archived compact-bars design). |
| Persisted values `"automatic"/"session"/"weekly"/"monthly"` | Needs a small key→definition map, but is self-describing in the plasma config file and stable if internal `primary/secondary/tertiary` keys are ever renamed | **Chosen**. |
| Persist raw `"primary"/"secondary"/"tertiary"` | Zero mapping code, but opaque to anyone reading the persisted config and couples storage to internal naming | Rejected. |
| Match a window by `key` **or** `label` | Slightly looser match, but `windowDefinitions` guarantees a 1:1 key↔label mapping, and existing harness fixtures supply label-only windows | **Chosen**: both are accepted identifiers for the same window. |
| Dedicated `PreferredWindow.js` resolver | One extra 20-line file, but matches the established `RequestTimeout.js`/`RefreshInterval.js` convention and is independently harness-testable | **Chosen**. |
| Inline validation in `main.qml` | No new file, but breaks the resolver-module convention and cannot be tested without instantiating the plasmoid | Rejected. |
| ComboBox appended after the custom-timeout SpinBox | Existing tab-order assertions keep passing unchanged; only one appended assertion | **Chosen** over inserting mid-form. |

## Data Flow

```text
Plasmoid.configuration.preferredRepresentativeWindow  (kcfg String, default "automatic")
                    │
     PreferredWindow.keyOrDefault(value) → "automatic"|"session"|"weekly"|"monthly"
                    │
        main.qml root.preferredWindowKey
                    │
   All Repeater → ProviderRow{ summary: true, preferredWindowKey }
                    │
   UsageModel.selectRepresentative(windows, preferredWindowKey)
        │                         │
  preferred finite?          no → firstFiniteWindow(windows)   ← unchanged automatic order
        │                         │
        └──────→ zero or one UsageWindowRow (identical styling either way)

CompactUsageButton → UsageModel.selectCompact(providers)   ← untouched, never reads the setting
```

## File Changes

| File | Action | Description |
|---|---|---|
| `contents/code/PreferredWindow.js` | Create | Pure resolver: valid key set, everything else → `"automatic"`. |
| `contents/code/UsageModel.js` | Modify | Add `preferredWindowKeys` map + `definitionForPreferred`/`matchesDefinition`/`preferredFiniteWindow`; extend `selectRepresentative`. `selectCompact` untouched. |
| `contents/ui/ProviderRow.qml` | Modify | New `preferredWindowKey` property; pass it into the selector. |
| `contents/ui/main.qml` | Modify | Import resolver, expose `preferredWindowKey`, pass it to `All` summary rows. |
| `contents/config/main.xml` | Modify | New String entry in group `General`. |
| `contents/ui/config/configGeneral.qml` | Modify | `cfg_`-aliased ComboBox, key/index helpers, guidance label, test aliases. |
| `tests/PreferredWindowHarness.qml` | Create | Resolver harness mirroring `tests/RequestTimeoutHarness.qml`. |
| `tests/UsageModelTest.qml` | Modify | Preference, per-provider fallback, and 1-arg-equivalence cases. |
| `tests/ProviderRowHarness.qml` | Modify | Property-to-render assertions for preferred/fallback/identity-only rows. |
| `tests/SettingsInteractionTest.qml` | Modify | Discoverability, default value, selection, tab traversal. |
| `scripts/run-qml-tests.sh` | Modify | Register `PreferredWindowHarness`. |
| `docs/live-plasma-smoke.md` | Modify | Manual checks for the new control and fallback rendering. |

## Interfaces / Contracts

### `contents/code/UsageModel.js`

```javascript
var preferredWindowKeys = {
    "session": "primary",
    "weekly": "secondary",
    "monthly": "tertiary"
}

function definitionForPreferred(preferredKey) {
    if (typeof preferredKey !== "string"
        || !Object.prototype.hasOwnProperty.call(preferredWindowKeys, preferredKey)) {
        return null
    }
    var definitionKey = preferredWindowKeys[preferredKey]
    for (var i = 0; i < windowDefinitions.length; i++) {
        if (windowDefinitions[i].key === definitionKey) {
            return windowDefinitions[i]
        }
    }
    return null
}

function matchesDefinition(window, definition) {
    return window.key === definition.key || window.label === definition.label
}

function preferredFiniteWindow(windows, definition) {
    var rows = windows instanceof Array ? windows : []
    for (var i = 0; i < rows.length; i++) {
        if (isUsableWindow(rows[i]) && matchesDefinition(rows[i], definition)) {
            return rows[i]
        }
    }
    return null
}

function selectRepresentative(windows, preferredKey) {
    var definition = definitionForPreferred(preferredKey)
    if (definition !== null) {
        var preferred = preferredFiniteWindow(windows, definition)
        if (preferred !== null) {
            return preferred
        }
    }
    return firstFiniteWindow(windows)
}
```

Contract:

- `selectRepresentative(windows)` — unchanged behavior; `preferredKey` is `undefined`, `definitionForPreferred` returns `null`, control falls straight through to `firstFiniteWindow`. All existing 1-arg call sites and tests stay green with no edits.
- `"automatic"` is deliberately **not** a map key, so it takes the identical `null`-definition path as `undefined`, `null`, `""`, `42`, and `"yearly"`. Automatic and unrecognized are the same code path by construction, not by duplicated logic.
- An explicit key with a finite value for that provider returns that exact normalized window object (no clone, no fabricated value).
- An explicit key with no finite value for that provider falls back to the full automatic order **for that provider only** — selection is evaluated per `ProviderRow`, so no cross-provider state exists.
- No finite window at all returns `null` for every preferred value; the row stays identity-only.
- `selectCompact` is not called, not read, and not modified.

### `contents/code/PreferredWindow.js` (new)

```javascript
.pragma library

var DEFAULT_KEY = "automatic"
var VALID_KEYS = ["automatic", "session", "weekly", "monthly"]

function parse(value) {
    if (typeof value !== "string") {
        return null
    }
    for (var i = 0; i < VALID_KEYS.length; i++) {
        if (VALID_KEYS[i] === value) {
            return value
        }
    }
    return null
}

function keyOrDefault(value) {
    var parsed = parse(value)
    return parsed === null ? DEFAULT_KEY : parsed
}
```

`parse`/`keyOrDefault` mirror `RequestTimeout.parse`/`secondsOrDefault` exactly. Matching is strict and case-sensitive, consistent with `RequestTimeout` rejecting `"120"`: `"Weekly"`, `"WEEKLY"`, `" weekly"`, `undefined`, `null`, `123`, and `["weekly"]` all resolve to `"automatic"`.

### `contents/ui/ProviderRow.qml`

```qml
property string preferredWindowKey: "automatic"

readonly property var representativeWindow: root.summary
    ? UsageModel.selectRepresentative(root.windows, root.preferredWindowKey) : null
```

The binding re-evaluates automatically when `preferredWindowKey` changes. `displayedWindows`, accessibility, icon, elision, and the non-expansion contract are untouched; a fallback bar renders through the same `UsageWindowRow` with no added visual signal.

### `contents/ui/main.qml`

```qml
import "../code/PreferredWindow.js" as PreferredWindow

property string preferredWindowKey:
    PreferredWindow.keyOrDefault(Plasmoid.configuration.preferredRepresentativeWindow)
```

Declared next to `requestTimeoutMs`, matching the existing config-property block. Inside the `All` `Repeater` delegate only:

```qml
delegate: ProviderRow {
    required property var modelData

    providerData: modelData
    summary: true
    preferredWindowKey: root.preferredWindowKey
    iconResolver: providerSelector.iconResolver
    Layout.fillWidth: true
}
```

The detail `ProviderRow` (`summary: false`) is not touched: it renders every window and never calls the selector.

### `contents/config/main.xml`

```xml
<entry name="preferredRepresentativeWindow" type="String">
  <default>automatic</default>
</entry>
```

Placed inside `<group name="General">`, immediately after the `requestTimeout` entry.

### `contents/ui/config/configGeneral.qml`

New page-level members alongside the existing aliases:

```qml
property alias cfg_preferredRepresentativeWindow: preferredWindow.selectedKey
property string cfg_preferredRepresentativeWindowDefault
property alias preferredWindowControl: preferredWindow
property alias preferredWindowGuidance: preferredWindowGuidanceLabel

readonly property var preferredWindowKeys: ["automatic", "session", "weekly", "monthly"]

function preferredWindowIndex(key) {
    var index = page.preferredWindowKeys.indexOf(key)
    return index < 0 ? 0 : index
}

function preferredWindowKeyAt(index) {
    return index >= 0 && index < page.preferredWindowKeys.length
        ? page.preferredWindowKeys[index] : "automatic"
}
```

Control, appended to the `Kirigami.FormLayout` immediately **after** the `requestTimeout` SpinBox:

```qml
QQC2.ComboBox {
    id: preferredWindow
    objectName: "preferredRepresentativeWindow"
    property string selectedKey: "automatic"
    Kirigami.FormData.label: i18n("Representative window:")
    model: [
        page.translated("Automatic"),
        page.translated("Session"),
        page.translated("Weekly"),
        page.translated("Monthly")
    ]
    Accessible.name: i18n("Preferred representative window")
    Accessible.description: i18n("Choose which usage window every provider summary shows in All. Automatic uses Session, then Weekly, then Monthly.")
    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
    onActivated: selectedKey = page.preferredWindowKeyAt(currentIndex)
    onSelectedKeyChanged: currentIndex = page.preferredWindowIndex(selectedKey)
    Component.onCompleted: currentIndex = page.preferredWindowIndex(selectedKey)
}
```

Guidance label, appended after `requestTimeoutGuidanceLabel`:

```qml
PlasmaComponents.Label {
    id: preferredWindowGuidanceLabel
    objectName: "preferredWindowGuidance"
    text: i18n("Every provider summary in All shows this usage window. Automatic picks the first available of Session, Weekly, then Monthly. A provider without the chosen window falls back to that automatic order. The panel badge is unaffected.")
    color: Kirigami.Theme.disabledTextColor
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    Accessible.name: i18n("Representative window guidance")
}
```

Display/persisted mapping — Automatic→`automatic`, Session→`session`, Weekly→`weekly`, Monthly→`monthly`; index equals position in `preferredWindowKeys`. The `Component.onCompleted` index sync, plus a two-way `onActivated`/`onSelectedKeyChanged` pair, mirrors the `requestTimeoutPreset` ↔ `requestTimeout` sync exactly, with `selectedKey` playing the role the SpinBox `value` plays there. Any out-of-domain persisted value resolves to index 0 (Automatic) in the UI, matching the runtime resolver.

Resulting tab order (existing order fully preserved, one appended stop): CLI path → refresh interval → timeout preset → custom timeout → **representative window**.

## Testing Strategy

| Layer | File | What to Test |
|---|---|---|
| Unit (resolver) | `tests/PreferredWindowHarness.qml` (new) | `parse` accepts each of the four keys; `keyOrDefault` maps `undefined`, `null`, `""`, `"Weekly"`, `"WEEKLY"`, `" weekly"`, `"yearly"`, `123`, `NaN`, `["weekly"]` to `"automatic"`; `DEFAULT_KEY === "automatic"`. |
| Unit (selector) | `tests/UsageModelTest.qml` | `test_selectRepresentativeHonoursExplicitPreferredWindow` (weekly key → Weekly window); `test_selectRepresentativeFallsBackWhenPreferredWindowIsNotFinite` (monthly key, non-finite Monthly → Session); `test_selectRepresentativePerProviderFallbackIsIndependent` (one provider falls back, another keeps Monthly, same call key); `test_selectRepresentativeAutomaticMatchesLegacySingleArgument` — asserts `selectRepresentative(w) === selectRepresentative(w, "automatic") === selectRepresentative(w, undefined) === selectRepresentative(w, "yearly")` by object identity across finite/non-finite/empty fixtures (this is the provable default-unchanged guarantee); `test_selectRepresentativeReturnsNullForNoFiniteWindowUnderAnyPreference`; `test_selectCompactIsUnaffectedByPreferredWindow` (assert compact output for the same fixtures is byte-identical). The three existing `selectRepresentative` cases stay unmodified as backward-compat proof. |
| Component | `tests/ProviderRowHarness.qml` | New summary rows: `preferredWeeklyRow` (Session+Weekly finite, key `weekly` → one bar, `representativeWindow.label === "Weekly"`); `preferredFallbackRow` (key `monthly`, Monthly non-finite → `label === "Session"`, still exactly one bar); `preferredIdentityOnlyRow` (key `weekly`, no finite window → zero `UsageWindowRow`s, zero ProgressBars); default-property assertion `summaryRow.preferredWindowKey === "automatic"` and unchanged `summaryRow` rendering; reactivity assertion — mutate `preferredWeeklyRow.preferredWindowKey = "session"` and re-assert the rendered label; styling-parity assertion — fallback row and explicit row expose the same visible-detail count via `countVisibleUsageDetails`. |
| Settings | `tests/SettingsInteractionTest.qml` | Pass `"cfg_preferredRepresentativeWindow": "automatic"` in `createObject`; `test_preferredWindowControlIsDiscoverableAndDefaulted` (findable by `objectName`, `currentIndex === 0`, `cfg_* === "automatic"`, guidance visible with a non-empty `Accessible.name`); `test_preferredWindowSelectionPersistsKeys` (keyboard/mouse select each option → `cfg_*` becomes `session`/`weekly`/`monthly`); `test_preferredWindowIsIndependentFromTimeout` (changing it leaves `cfg_requestTimeout`/`cfg_refreshInterval` untouched); extend `test_tabTraversalUsesNativeFocus` with one appended `keyClick(Qt.Key_Tab)` → `preferredWindowControl.activeFocus`. |
| Runner | `scripts/run-qml-tests.sh` | **One** added line: `PreferredWindowHarness \` in the `qml6 -f` harness list (placed next to `RequestTimeoutHarness`). The QtTest list needs **no** change — `UsageModelTest.qml` and `SettingsInteractionTest.qml` are already registered there, so the anticipated second registration line does not exist. |
| E2E (manual) | `docs/live-plasma-smoke.md` | Setting reachable by keyboard and labeled; Automatic reproduces prior `All` rendering; Weekly/Monthly change every eligible row; a provider lacking the window still shows a bar with its own label; panel badge unchanged; Breeze Light/Dark readability. |

## Threat Matrix

N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary changes. The `codexbar` CLI invocation, argv, and lifecycle are untouched.

## Implementation Phases (RED → GREEN → REFACTOR)

1. **Resolver** — RED `tests/PreferredWindowHarness.qml` (fails: module missing) → GREEN `contents/code/PreferredWindow.js` → register the harness in `scripts/run-qml-tests.sh`.
2. **Selector** — RED new `UsageModelTest.qml` cases including the automatic/1-arg identity case and the `selectCompact`-unchanged case → GREEN the `selectRepresentative` extension in `UsageModel.js`; confirm the three pre-existing selector tests pass untouched.
3. **Component** — RED new `ProviderRowHarness.qml` rows and reactivity assertions → GREEN `preferredWindowKey` property + selector call in `ProviderRow.qml`.
4. **Settings surface** — RED new `SettingsInteractionTest.qml` cases → GREEN `contents/config/main.xml` entry + `configGeneral.qml` ComboBox, helpers, and guidance label.
5. **Plumbing** — GREEN `main.qml` import, `preferredWindowKey` property, and `All` delegate wiring; full `./scripts/run-qml-tests.sh` green.
6. **REFACTOR** — deduplicate any key-list drift between `PreferredWindow.VALID_KEYS`, `UsageModel.preferredWindowKeys`, and `configGeneral.preferredWindowKeys`; update `docs/live-plasma-smoke.md`; re-run the full suite.

## Review Budget

| Area | Est. lines |
|---|---|
| `UsageModel.js` | 30–40 |
| `PreferredWindow.js` | 20–25 |
| `ProviderRow.qml` | 3–5 |
| `main.qml` | 4–6 |
| `main.xml` | 3 |
| `configGeneral.qml` | 45–55 |
| `UsageModelTest.qml` | 70–85 |
| `ProviderRowHarness.qml` | 45–55 |
| `PreferredWindowHarness.qml` | 30–35 |
| `SettingsInteractionTest.qml` | 30–40 |
| `run-qml-tests.sh` | 1 |
| `docs/live-plasma-smoke.md` | 8–12 |
| **Total** | **290–340** |

Within the 400-line review budget: **Yes** (340 worst case, 60 lines of headroom). Single PR; no chaining required.

## Migration / Rollout

No migration. The kcfg entry defaults to `automatic`, and existing installs with no persisted value resolve through `keyOrDefault` to `"automatic"`, reproducing current rendering exactly. Rollback: revert the commit; the persisted string becomes inert. Partial rollback: make `PreferredWindow.keyOrDefault` return `DEFAULT_KEY` unconditionally, restoring today's behavior with the UI intact.

## Open Questions

None.
