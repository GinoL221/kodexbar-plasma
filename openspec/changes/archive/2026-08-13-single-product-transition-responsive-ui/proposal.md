# Proposal: Single-Product Transition and Responsive UI

## Intent

Make the current Plasma 6 product understandable to users during the transition from the legacy applet, while ensuring provider usage bars remain readable in narrow popup windows. This is a document-only transition plus a bounded responsive UI improvement; it preserves the external `codexbar` boundary and existing runtime behavior.

## Scope

### In Scope
- Document installation, update, add-new-widget, coexistence, and optional per-instance configuration-copy guidance for `org.kde.plasma.kodexbar.plasma`.
- Add strict-TDD RED/green QML coverage for constrained provider/window widths.
- Make the smallest native QtQuick/Kirigami layout adjustment so percentages remain visible and bars use available width without clipping.

### Out of Scope
- Removing packages, changing package IDs, or rewriting existing Plasma panel instances.
- CLI contracts, fixtures, provider/auth/fetch behavior, controller lifecycle work, or the blocked `persistent-datasource-lifecycle` change.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `provider-usage-display`: narrow popup usage rows must preserve readable percentage text and a usable progress-bar width while retaining existing provider, lifecycle, and CLI contracts.

## Approach

Retain both package identities and explain that users add a new `KodexBar Plasma` instance rather than expecting a legacy instance to change identity. Extend the existing provider/window harnesses with constrained-width assertions first, run `./scripts/run-qml-tests.sh`, then apply the smallest native layout change in `ProviderRow.qml`/`UsageWindowRow.qml`. Preserve metadata identity, per-instance `General` settings, compact selection, and the exact all-provider command.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `README.md`, `docs/live-plasma-smoke.md` | Modified | Document parallel transition and live verification. |
| `contents/ui/ProviderRow.qml`, `contents/ui/UsageWindowRow.qml` | Modified | Constrain narrow-row layout without clipping. |
| `tests/ProviderRowHarness.qml`, related QML harnesses | Modified | Add responsive contract coverage before production changes. |
| `openspec/specs/provider-usage-display/spec.md` | Delta | Record the responsive requirement. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Offscreen geometry differs from real Plasma allocation. | Med | Keep `plasmawindowed` smoke verification as a manual gate. |
| Scope exceeds the 400-line review budget. | Low/Med | Stop and request a delivery decision under `ask-on-risk`. |

## Rollback Plan

Revert the documentation, test, QML, and spec changes as one work unit. Package identities, installed packages, panel instances, and external CLI behavior remain untouched.

## Dependencies

- Plasma 6/Kirigami runtime and the existing `./scripts/run-qml-tests.sh` harness.

## Success Criteria

- [ ] Users can distinguish legacy and current packages and add the current instance without package or panel mutation.
- [ ] Narrow-width tests prove visible percentages, non-clipped bounds, and available progress-bar width.
- [ ] `./scripts/run-qml-tests.sh` passes with the exact CLI and lifecycle boundaries preserved.
