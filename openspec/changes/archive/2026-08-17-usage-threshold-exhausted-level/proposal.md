# Proposal: Usage Threshold Exhausted Level

## Intent

`critical` (>=90%) currently covers everything from "about to run out" to "already fully out" with the same icon and color. A window at exactly 100% (or beyond, since values aren't clamped) means the user has zero quota left right now — a qualitatively different state from "critical", not just a more severe shade of it. Add a fourth, visually distinct level so a fully exhausted window reads differently from one that's merely close to the edge.

## Scope

### In Scope

1. `contents/code/UsageThreshold.js`: add `EXHAUSTED_AT = 100` and `LEVEL_EXHAUSTED = "exhausted"`. `level()` gains a fourth branch: `usedPercent >= EXHAUSTED_AT` → `exhausted` (checked before the existing `critical` branch). `isRisk()` returns `true` for `exhausted` too (it's still a risk level, just a more severe one).
2. `contents/icons/threshold-exhausted.svg` (new, already created and user-approved against rendered previews): a filled octagon (distinct silhouette from `warn`'s triangle and `critical`'s circle) with a diagonal "no entry" slash cut via SVG `<mask>` — same technique as the existing two bundled icons.
3. `contents/ui/UsageWindowRow.qml`: `thresholdMarkerComponent`'s `source`/`color` ternaries gain a third branch for `exhausted` — icon is `threshold-exhausted.svg`, color is `Kirigami.Theme.negativeTextColor` (same red as `critical` — the user confirmed same-color-different-shape is the intended signal, not a new color).
4. `Accessible.description`: `exhausted` appends `"Quota exhausted"` (distinct from `critical`'s `"Critical usage"`), same append-after-percent-entry rule as the existing two levels.
5. Test coverage: extend `tests/UsageThresholdHarness.qml`'s boundary table (99.9→critical, 100→exhausted, 100.0→exhausted, 120→exhausted) and `tests/UsageWindowThresholdHarness.qml` with a `usedPercent:100` fixture pair (summary + detail) asserting icon source, color, and that the reserved-slot/fill-independence/cross-mode invariants still hold at the new level.

### Out of Scope

- Changing `warn`/`critical`'s existing boundaries, icons, or colors — untouched.
- A distinct color for `exhausted` — same `negativeTextColor` as `critical`, differentiated by icon shape only, per explicit user decision.
- Clamping `usedPercent` above 100 — still classified, never clamped (existing `UsageThreshold.js` behavior, unchanged).
- Any change to `ProviderSelector.qml` tab underlines — still brand-only, unaffected by any threshold level.
- Settings/configurability for the new boundary — `EXHAUSTED_AT = 100` is fixed policy, same standing as `WARN_AT`/`CRITICAL_AT`.

## Capabilities

### Modified Capabilities
- `provider-usage-display`: extends the existing "Usage window threshold risk marker" requirement (merged from the archived `usage-threshold-marker` change) with a fourth classification level. Not a new requirement — a genuine delta on the existing one.

## Approach

Purely additive to the existing, already-shipped threshold-marker architecture: one more `UsageThreshold.js` constant/branch, one more bundled SVG, one more ternary arm in the already-shared `thresholdMarkerComponent` (still one implementation for both summary and detail modes, still fixed-width reserved slot, still no fill recoloring). No new architectural decisions beyond the icon/color choice — this reuses every mechanism (`isMask` bundled SVGs, `opacity`-driven reserved-slot visibility, mode-asymmetric placement) already built and live-smoke-verified in the archived change.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/code/UsageThreshold.js` | Modified | Fourth level, `EXHAUSTED_AT` constant |
| `contents/icons/threshold-exhausted.svg` | New | Octagon + diagonal-slash mask icon (already created, user-approved) |
| `contents/ui/UsageWindowRow.qml` | Modified | Third ternary branch in `thresholdMarkerComponent`, a11y phrase |
| `tests/UsageThresholdHarness.qml` | Modified | Boundary table extended for `EXHAUSTED_AT` |
| `tests/UsageWindowThresholdHarness.qml` | Modified | New `usedPercent:100` fixtures |
| `openspec/specs/provider-usage-display/spec.md` | Modified | Requirement delta merges on archive |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `EXHAUSTED_AT` branch ordering bug (checked after `CRITICAL_AT` instead of before) silently collapses to `critical` | Low | RED-first boundary test at exactly 100 catches this immediately |
| Icon visually too similar to `critical` at 16px | Low | Already addressed — octagon silhouette is deliberately distinct from `critical`'s circle, confirmed via rendered preview iteration with the user before implementation |
| Offscreen visual-regression harness still can't show `isMask` local-SVG color (known standing limitation from the archived change) | Certain, pre-existing | Same as before — golden regen documents the limitation honestly, live smoke is the real gate |

## Rollback Plan

Revert the four touched files; `contents/icons/threshold-exhausted.svg` becomes unreferenced dead weight (harmless) or can be deleted. `warn`/`critical` behavior is completely unaffected since their branches are untouched.

## Success Criteria

- [ ] A window at exactly 100% (or above) shows the octagon+slash icon, not the critical circle.
- [ ] A window at 99.9% still shows the critical circle (boundary is exclusive-below on the `exhausted` side, matching the existing `warn`/`critical` convention).
- [ ] Color stays `negativeTextColor` (same red as critical) — differentiation is shape-only, by design.
- [ ] Reserved-slot/fill-independence/cross-mode invariants still hold at the new level.
- [ ] `run-qml-tests.sh` and `lint-qml.sh` pass; live Breeze smoke confirms the icon reads clearly distinct from critical.
