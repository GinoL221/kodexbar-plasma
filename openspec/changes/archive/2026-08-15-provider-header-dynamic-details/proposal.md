# Proposal: Dynamic Provider Header Details

## Intent

Provider snapshots already preserve CLI-supplied `raw` data, but the popup exposes only normalized windows. Users therefore cannot see useful provider context such as version, login method, or provider-specific detail rows. This change surfaces that context without moving provider logic, authentication, or fetching into the UI.

## Scope

### In Scope
- Enrich provider headers with `version` and `loginMethod` only when present.
- Add a collapsed-by-default, keyboard-expandable dynamic details section for valid `usage.details[]` entries, rendering supplied titles and label/value rows verbatim.
- Add defensive UI harness coverage, accessibility/theme behavior, and concise documentation/spec clarification.

### Out of Scope
- Pace, credits, cost, token values, projections, calculations, or provider-specific extras.
- Displaying email or organization; these remain preserved in `raw` only.
- Changes to the CodexBar CLI, `UsageModel.js`, `UsageController.qml`, compact view, authentication, or request lifecycle.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `provider-usage-display`: require conditional provider header metadata and defensive, expandable rendering of CLI-supplied dynamic details while preserving commercial-data and runtime-boundary exclusions.

## Approach

Use Approach 2 from exploration. Extend the provider-row presentation with guarded reads from `raw`; hide absent or malformed fields. Use native Plasma/Kirigami controls and theme units, with accessible names/descriptions and keyboard activation. Keep normalization and controller boundaries unchanged. Add focused executable QML harnesses before implementation, preserving the existing four-key contract tests. Keep authored change size approximately 250–350 lines.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/ui/ProviderRow.qml` | Modified | Header metadata and expandable details. |
| `contents/ui/main.qml` | Modified | Bounded popup scrolling/layout if required. |
| `tests/` | New/Modified | Defensive, rendering, keyboard, and accessibility harnesses. |
| `openspec/specs/provider-usage-display/spec.md` | Modified | Delta requirements and scenarios. |
| `README.md` | Modified | Clarify displayed versus preserved fields. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Popup expansion harms compact layout | Med | Bounded scrolling, collapsed default, manual Breeze light/dark smoke. |
| Malformed `raw` crashes QML | Med | Guard every nested access and test absent/non-array data. |
| Sensitive identity leaks | Low | Never render email or organization; retain privacy boundary. |

## Rollback Plan

Revert the proposal's UI, harness, documentation, and spec delta commits. The unchanged normalized snapshot and controller paths remain usable, so rollback removes only presentation enrichment.

## Dependencies

- Phase 1 `raw` passthrough and the existing Plasma/Kirigami harness tooling.

## Success Criteria

- [ ] Version/login method render only when present; details remain collapsed until activation.
- [ ] Missing/malformed fields render safely; email, organization, pace, credits, cost, and tokens never display.
- [ ] Focused QML tests and `./scripts/lint-qml.sh` pass; popup remains readable and keyboard/theme accessible.
- [ ] Authored implementation stays within approximately 250–350 lines and preserves `UsageModel.js`/`UsageController.qml`.
