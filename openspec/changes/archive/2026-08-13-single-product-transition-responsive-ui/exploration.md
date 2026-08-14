## Exploration: Single Product Transition and Responsive UI

### Current State
The repository product is a Plasma 6 applet with package ID `org.kde.plasma.kodexbar.plasma`; `metadata.json` and `scripts/validate-package.sh` enforce that identity. The host currently has both this package and the legacy installed applet `org.kde.plasma.kodexbar`, so they are independent Plasma package identities and may coexist. Updating/installing the repository product must use its ID and must not remove either package or alter existing panel instances; a legacy panel instance cannot be converted in place merely by updating the differently identified package.

The current product's configuration is stored per applet instance under `General` (`codexbarCommand`, refresh interval, timeout, and representative window). The UI keeps the external `codexbar` CLI boundary and issues the configured executable with `usage --provider all --format json --json-only`.

The responsive report belongs to the current repository UI only. In `UsageWindowRow.qml`, the window label consumes fill width while the percentage has only a maximum width, so narrow layouts have no explicit reservation or minimum width for the percentage. Its progress bar fills the available width but has no narrow-width behavior. `CompactUsageButton.qml` caps the panel label at eight grid units, which can elide status text but does not affect popup bars. Existing tests prove visibility, finite-value handling, and some narrow geometry, but do not assert that a percentage and progress bar remain readable at constrained popup widths.

The active `persistent-datasource-lifecycle` change remains historically blocked (`0/4` requirements, `10/14` scenarios, five critical blockers) despite its runner exiting zero. It concerns controller lifecycle correctness and harness assertion quality, not package identity or responsive layout; this exploration does not resolve or modify it.

### Affected Areas
- `metadata.json` — authoritative repository package identity: `org.kde.plasma.kodexbar.plasma`.
- `scripts/validate-package.sh` — validates the current package ID and package structure.
- `README.md`, `docs/live-plasma-smoke.md` — installation, update, and live smoke instructions must distinguish coexisting legacy and current package IDs.
- `contents/config/main.xml`, `contents/ui/config/configGeneral.qml` — per-instance current-product settings and CLI boundary to preserve during migration guidance.
- `contents/ui/main.qml` — popup sizing and the composition path to provider rows.
- `contents/ui/CompactUsageButton.qml` — compact panel badge width cap and narrow-panel behavior.
- `contents/ui/ProviderRow.qml`, `contents/ui/UsageWindowRow.qml` — provider/window label, percentage, and progress-bar layout constraints.
- `tests/ProviderRowHarness.qml`, `tests/MainCompactHarness.qml`, `tests/CompactUsageButtonHarness.qml` — existing offscreen coverage to extend before UI behavior changes.
- `scripts/run-qml-tests.sh` — strict-TDD runner admitting the relevant harnesses.
- `openspec/changes/persistent-datasource-lifecycle/verify-report.md` — required blocked-context record; intentionally untouched.

### Approaches
1. **Documented parallel transition plus targeted responsive contract** — retain both package IDs, provide explicit install/update/add-new-widget and optional manual configuration-copy guidance, then add narrow-width assertions before changing the current UI layout.
   - Pros: Preserves legacy packages/panel instances; isolates current-product behavior; fits a small, reviewable first unit.
   - Cons: Users must add the new product instance; Plasma does not offer automatic cross-ID panel migration.
   - Effort: Medium

2. **Attempt automatic legacy-instance migration** — inspect and rewrite Plasma containment/configuration state to replace legacy instances with the new package.
   - Pros: Potentially reduces manual user steps.
   - Cons: Violates the no-panel-instance-change constraint; couples to user-specific Plasma internals and risks data loss or duplicate applets.
   - Effort: High

### Recommendation
Choose documented parallel transition plus targeted responsive contract. First create RED tests that instantiate the current `UsageWindowRow`/`ProviderRow` at constrained widths and assert visible percentage text, non-clipped layout bounds, and an available progress-bar width; then make the smallest native QtQuick/Kirigami layout adjustment needed. Keep `metadata.json` identity unchanged and preserve every `General` setting and the external CLI invocation. Migration guidance should explicitly state that legacy and current IDs coexist, packages are not removed, and a user adds a new `KodexBar Plasma` instance rather than expecting a legacy panel instance to change identity.

### Risks
- Package IDs define separate Plasma applet types; automatic replacement would require unsafe user containment/config mutation and conflicts with the requested preservation of panel instances.
- Offscreen QML harnesses can prove geometry constraints but cannot prove real panel allocation, keyboard traversal, or Breeze rendering; `plasmawindowed org.kde.plasma.kodexbar.plasma` remains a manual smoke gate.
- The active lifecycle change's failing harness semantics are unrelated but mean its historical zero-exit test result cannot be used as acceptance evidence for this change.
- Responsive changes spanning popup, rows, and compact representation can exceed the 400-line budget; under `ask-on-risk`, stop for a delivery decision if the first unit forecasts that risk.

### Ready for Proposal
Yes — propose a bounded first work unit for transition documentation and RED/green responsive tests plus the minimal current-product QML layout change. Do not include package removal, legacy panel migration, controller lifecycle remediation, provider/auth/fetch work, or any change to the `codexbar` CLI boundary.
