## Exploration: configurable-representative-window

### Current State

`contents/code/UsageModel.js` defines `windowDefinitions` (`primary`/Session, `secondary`/Weekly, `tertiary`/Monthly), a finite-value guard, and `selectRepresentative(windows) = firstFiniteWindow(windows)` — a pure, fixed-order (Session → Weekly → Monthly) picker with no configurability today. A separate `selectCompact(providers)` picks the single highest finite percentage across all providers/windows for the panel badge (`main.qml` `compactSelection`) — a different, spec-mandated deterministic algorithm (tie order Session/Weekly/Monthly/first-provider) that must not be touched by this change.

`contents/ui/ProviderRow.qml` (summary mode) computes `representativeWindow: UsageModel.selectRepresentative(root.windows)` and renders it via `UsageWindowRow.qml`. This is the only call site of `selectRepresentative`.

`contents/ui/main.qml` instantiates `ProviderRow { summary: true }` per provider in the `All` `Repeater`; it also reads `Plasmoid.configuration.*` for `codexbarCommand`, `refreshInterval` (via `RefreshInterval.js`), `requestTimeout` (via `RequestTimeout.js`).

Settings pattern: `contents/config/main.xml` (kcfg, group "General") declares `codexbarCommand` (String), `refreshInterval` (Int, 1–3600, default 60), `requestTimeout` (Int, 30–600, default 60). `contents/config/config.qml` wires one `ConfigCategory` to `config/configGeneral.qml`. `contents/ui/config/configGeneral.qml` is a `KCM.SimpleKCM` using `Kirigami.FormLayout`, exposing `cfg_*` aliased properties per kcfg entry, plus a preset `QQC2.ComboBox` + custom `QQC2.SpinBox` pattern for `requestTimeout` — a directly reusable template for a new "preferred window" combo (preset dropdown + guidance label, `Accessible.name`/`description` set, `Component.onCompleted` index sync).

Validation/fallback for config values lives in small `.pragma library` JS resolver modules mirroring `RequestTimeout.js` (`parse`, `secondsOrDefault`, `millisecondsOrDefault`) and `RefreshInterval.js` — invalid/out-of-range persisted values silently resolve to a safe default.

Tests: `tests/UsageModelTest.qml` (QtTest, pure-function tests, includes `selectRepresentative`-specific cases), `tests/ProviderRowHarness.qml` (Item-based harness instantiating `ProviderRow` directly), `tests/SettingsInteractionTest.qml` (QtTest, instantiates `configGeneral.qml` live, drives keyboard/mouse, checks `cfg_*` + focus traversal), plus small dedicated harnesses per resolver module. All are registered explicitly in `scripts/run-qml-tests.sh` (a QtTest list and a `qml6 -f` harness list) — new files must be added there too.

### Affected Areas

- `contents/code/UsageModel.js` — `selectRepresentative` needs an optional second parameter (preferred window key) with fallback to the current automatic order; must stay backward compatible with existing 1-arg call sites/tests.
- `contents/ui/ProviderRow.qml` — new property (e.g. `preferredWindowKey`) threaded into `UsageModel.selectRepresentative(root.windows, root.preferredWindowKey)`.
- `contents/ui/main.qml` — read `Plasmoid.configuration.preferredRepresentativeWindow`, resolve it through a new small JS resolver (mirroring `RequestTimeout.js`), pass it to each summary `ProviderRow`.
- `contents/config/main.xml` — new kcfg `<entry>` in group "General" (String, `<default>automatic</default>`), following the exact pattern of the three existing entries.
- `contents/ui/config/configGeneral.qml` — new `cfg_preferredRepresentativeWindow` aliased combo box + guidance label, following the `requestTimeoutPreset` ComboBox convention.
- `contents/config/config.qml` — no change expected; the single existing General category already hosts all settings.
- `openspec/specs/provider-usage-display/spec.md` — "Requirement: Provider presentation" currently hardcodes an unconditional "selecting the first finite value in Session, then Weekly, then Monthly order"; this requires a spec **MODIFY** delta (not ADDED), rewording to "Automatic" as default plus new conditional scenarios for an explicit preferred window. Must not touch "Requirement: Deterministic compact summary" (must stay fixed).
- New resolver JS module (pattern: `contents/code/RequestTimeout.js`) — e.g. `PreferredWindow.js`, a pure `resolve(value)` mapping unknown/invalid persisted strings back to `"automatic"`.
- Tests: `tests/UsageModelTest.qml` (new `selectRepresentative(windows, key)` preference cases), `tests/ProviderRowHarness.qml` (end-to-end prop-to-render check), `tests/SettingsInteractionTest.qml` (new control discoverability/default/tab-traversal), a new small harness for the resolver module, and `scripts/run-qml-tests.sh` registration in both lists.

### Approaches

1. **Global "preferred representative window" setting (Automatic default) via existing pure-function/property-alias pattern** — one kcfg String entry, one JS resolver module, one ComboBox in the existing General settings page, an optional second parameter on `selectRepresentative`, one new `ProviderRow` property.
   - Pros: Follows every existing convention exactly (kcfg entry, JS resolver, `cfg_` alias, ComboBox preset pattern already proven for `requestTimeout`); `selectRepresentative` stays pure and testable; fully backward compatible (default "automatic" reproduces current behavior byte-for-byte); single settings panel already exists, no new UI surface needed; `selectCompact`/panel badge untouched.
   - Cons: Spec's "Provider presentation" requirement currently states the fallback order unconditionally — needs a careful MODIFY delta (not additive) with re-verified scenarios; must explicitly disambiguate "persistent selection" (banned under provider-focused exclusions) from this new persisted global preference.
   - Effort: Low–Medium.

2. **Per-provider preferred window** — rejected as out of scope: no per-provider settings UI surface exists, and the "Provider-focused exclusions" language explicitly bans "CLI/provider switching" and "persistent selection" in the popup provider-selection sense; conflicts with "Selection MUST be transient... Reopening MUST reapply the default."
   - Effort: High, conflicts with existing spec language — not recommended.

3. **Runtime-only (non-persisted) popup toggle** — avoids kcfg changes but contradicts the "settings-panel option" framing of the request and has no existing analogous pattern (popup tab selection is explicitly transient by spec, which cuts against a persisted preference).
   - Effort: Medium, weaker fit — not recommended as primary.

### Recommendation

Approach 1: a global, kcfg-persisted "preferred representative window" setting (Automatic/Session/Weekly/Monthly) in the existing General settings page, implemented as an optional second parameter on the existing pure `UsageModel.selectRepresentative` function, with "automatic" preserving exact current behavior. This is architecturally straightforward given existing conventions and requires no new UI surface — only a spec MODIFY delta for "Requirement: Provider presentation" plus new test coverage following existing harness patterns.

### Risks

- The spec's "Provider presentation" requirement wording is currently an unconditional MUST for Session → Weekly → Monthly order; the design/spec phase must produce a precise MODIFY delta (not an ADDED requirement) with re-verified existing scenarios plus new ones, or risk contradicting the archived, already-normative spec text.
- "Provider-focused exclusions" bans "persistent selection" — this must be explicitly disambiguated in the proposal (it refers to transient provider/tab selection state, not to a persisted global settings-panel preference, which is the same class as existing `codexbarCommand`/`refreshInterval`/`requestTimeout`). Flag this explicitly to preempt reviewer objection.
- Must keep `selectCompact` (panel badge, "Deterministic compact summary" requirement) completely untouched — easy to accidentally conflate the two selection algorithms in the same small file.
- `selectRepresentative` signature change must remain backward compatible with existing 1-arg call sites/tests.
- `scripts/run-qml-tests.sh` requires explicit registration of any new test file/harness — easy to forget and silently skip coverage.

### Ready for Proposal

**Yes.** Scope is clear, one approach is recommended, affected files are enumerated, and the one spec-wording risk (MODIFY vs ADDED requirement) is identified for the design/spec phase to resolve explicitly.
