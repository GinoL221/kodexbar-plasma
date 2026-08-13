# Proposal: Configurable Representative Window

## Intent

In `All`, every provider summary row shows one representative usage bar chosen by a hardcoded Session → Weekly → Monthly order. Users who budget against a weekly or monthly quota must open each provider tab one at a time to read the window they care about. The order is a reasonable default, not a universal one. Success: a user picks a preferred window once in Settings and `All` answers their question directly, with behavior unchanged for anyone who never touches the setting.

## Scope

### In Scope

- New persisted global setting `preferredRepresentativeWindow` (Automatic | Session | Weekly | Monthly), default `automatic`, in the existing General settings page.
- Preference-aware representative selection for `All` summary rows, with per-provider graceful fallback.
- Resolver for missing/unknown persisted values back to `automatic`.
- Test coverage per existing harness conventions plus runner registration.

### Out of Scope

- Per-provider preferred windows (no settings surface; conflicts with transient-selection rules).
- Any change to `selectCompact` / the panel badge algorithm or its "Deterministic compact summary" requirement.
- Provider tabs (they already show every supplied window), CLI arguments, new windows, or expandable `All` rows.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `provider-usage-display`: MODIFY "Requirement: Provider presentation" — the unconditional Session → Weekly → Monthly MUST becomes the `automatic` default; add conditional behavior for an explicit preferred window. Existing scenarios must be re-verified, not replaced.

## Approach

Extend the pure `UsageModel.selectRepresentative(windows)` with an optional second argument (preferred window key). Behavior:

- `automatic` or absent → current first-finite Session → Weekly → Monthly order, byte-for-byte.
- Explicit key with a finite value for that provider → that window.
- Explicit key without a finite value for that provider → automatic fallback for that provider only. Identity-only rendering stays reserved for providers with no finite window at all.

Plumb via a new `ProviderRow` property fed from `Plasmoid.configuration`, resolved through a small `.pragma library` module mirroring `RequestTimeout.js`. Settings uses a `cfg_`-aliased `QQC2.ComboBox` following the proven `requestTimeoutPreset` pattern.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/code/UsageModel.js` | Modified | Optional preferred-key parameter on `selectRepresentative`; `selectCompact` untouched |
| `contents/code/PreferredWindow.js` | New | Pure resolver mapping invalid values to `automatic` |
| `contents/ui/ProviderRow.qml` | Modified | New `preferredWindowKey` property threaded into selection |
| `contents/ui/main.qml` | Modified | Read + resolve config, pass to summary rows |
| `contents/config/main.xml` | Modified | New String kcfg entry, group General |
| `contents/ui/config/configGeneral.qml` | Modified | Labeled, accessible ComboBox + guidance |
| `openspec/specs/provider-usage-display/spec.md` | Modified | MODIFY delta on "Provider presentation" |
| `tests/`, `scripts/run-qml-tests.sh` | Modified/New | New cases, resolver harness, explicit registration |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Reviewer reads this as banned "persistent selection" | Med | "Provider-focused exclusions" bans transient popup provider/tab selection state. This is a global settings-panel preference, same class as `refreshInterval`/`requestTimeout`; state this explicitly in the spec delta |
| Spec delta written as ADDED, contradicting normative text | Med | MODIFY "Provider presentation"; re-verify all six existing scenarios |
| `selectCompact` accidentally conflated (same file) | Med | Explicit non-goal; assert compact behavior unchanged in tests |
| 1-arg call sites break | Low | Second parameter optional; keep existing 1-arg tests green |
| New harness not registered in runner | Med | Registration is an explicit task in both runner lists |

## Rollback Plan

Revert the change commit. The kcfg entry disappears; any persisted value becomes inert. No migration, no stored user data beyond one string, no CLI or lifecycle impact. Partial rollback: force the resolver to return `automatic`, restoring today's behavior with UI intact.

## Dependencies

None. No CLI, packaging, or external contract changes; the `codexbar` boundary is untouched.

## Product Decisions (confirmed)

- Default option label: "Automatic". No inline explanation of the fallback order in the label itself; explained via guidance/help text below the control, following the existing `configGeneral.qml` pattern.
- No visual distinction for a fallback bar. The existing per-window label on the bar (e.g. "Session") is sufficient signal; no extra icon/color/text for the fallback case.
- The panel badge (`selectCompact`) stays permanently fixed to its "highest finite percentage" algorithm. It does not honor this preference now or later; any change to it would be a separate, unrelated proposal.
- Per-provider preferred window is a permanent non-goal, not a deferred TODO. State it as a design boundary in the spec, consistent with the popup's transient provider/tab selection.

## Success Criteria

- [ ] Default `automatic` reproduces current `All` rendering exactly, with existing scenarios green.
- [ ] Selecting Weekly or Monthly renders that window for every provider that has a finite value for it.
- [ ] A provider lacking the preferred window falls back automatically rather than losing its bar.
- [ ] Providers with no finite window still render identity only, with no invented percentage.
- [ ] Setting is keyboard-reachable, labeled, and readable in Breeze light/dark.
- [ ] Panel badge output is unchanged.
- [ ] `./scripts/run-qml-tests.sh` passes with new tests registered.
