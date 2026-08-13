# Archive Report: configurable-representative-window

## Final Status

- Change: `configurable-representative-window`
- Artifact mode: Hybrid (OpenSpec + Engram)
- Archived to: `openspec/changes/archive/2026-08-13-configurable-representative-window/`
- Archive date: 2026-08-13
- Verification verdict: **PASS** (native `gentle-ai sdd-verify-validate`: valid=true, verdict=pass)
- Result: PASS; no blockers, no critical findings, 1 non-blocking SUGGESTION

## Final Evidence

- Requirements: 1/1 fully compliant (Provider presentation requirement modified)
- Scenarios: 12/12 compliant (7 preserved scenarios + 5 new scenarios added)
- Tasks: 43/43 complete (all implementation and refactor phases closed)
- `./scripts/run-qml-tests.sh`: exit 0; 17+16+11=44 QML test cases passed, 18 standalone harnesses passed
- `git diff --check`: exit 0, no whitespace errors
- No BLOCKER or CRITICAL findings
- 1 non-blocking SUGGESTION (recorded in verify-report)

## Delivery Packaging History

Per the launch prompt's explicit final-state facts:

- Apply batch actual size: 468 authored lines (exceeded 400-line budget)
- User decision: explicitly accepted `size:exception` for a single PR (declined the alternative 2-PR chained split)
- Native `gentle-ai sdd-attempt` ledger: required a `reset` (blocked initially on `maintainer_decision` at settle time because `changed_lines` exceeded the acquire-time cap)
- Ledger reset: performed with explicit `--reason`/`--actor` documenting user consent
- Ledger settle: `verify` work-unit settled cleanly with `state: complete`
- Delivery state: No commit or push has been made; all changes remain as uncommitted working-tree modifications

This is delivery-packaging history, not an implementation defect. No re-flag or risk carried forward.

## Implementation Scope Realized

The change successfully implemented configurable preferred representative window selection for the `All` provider summary display:

- **Resolver**: `PreferredWindow.js` created, supporting `automatic`, `session`, `weekly`, `monthly` keys with graceful fallback for unrecognized values
- **Selector**: `UsageModel.selectRepresentative(windows, preferredKey)` extended with optional second parameter, preserving byte-for-byte behavior when key is absent/automatic
- **Component**: `ProviderRow.qml` wired with new `preferredWindowKey` property; reactivity and styling parity verified
- **Settings surface**: `configGeneral.qml` and `main.xml` extended with labeled `QQC2.ComboBox` control and persistent configuration entry
- **Plumbing**: `main.qml` reads and resolves configuration, passes to all summary rows in the `All` repeater; detail rows remain untouched
- **Test coverage**: 43 tasks including resolver harness, selector test cases, component reactivity, settings persistence, tab traversal, and end-to-end smoke

## Specs Synced

Updated `openspec/specs/provider-usage-display/spec.md`:
- Modified "Requirement: Provider presentation" from 7 scenarios to 12 scenarios
- New scenarios: "Explicit preferred window with a finite value", "Per-provider fallback under an explicit preference", "Automatic preserves current default behavior", "Preference is global, not per-provider", "Fallback bar has no special visual treatment"
- Preserved all 7 existing scenarios: Heterogeneous providers, Session is representative, Representative fallback order, Monthly is the only finite window, Provider has no finite percentage, Full detail remains in provider tab, All summaries are not expandable
- All other requirements unchanged (Bounded timeout, Validated request timeout, Authoritative all-provider request, Deterministic compact summary, Global states, Mixed provider failures, Refresh and concurrency, Native and accessible UI, MVP exclusions, Configuration-first path, Deterministic bounded discovery, Saved-path migration, Setup and troubleshooting, Provider-focused exclusions, Preserved runtime boundaries)

## Mechanical Readbacks

Spec merge and archive move both produced empty `diff -r` output, confirming byte-identity:

```text
--- spec merge verification (verbatim) ---
(no output — merge successful)

--- archive move verification (verbatim) ---
(no output — archive move successful)
```

## SDD Cycle Completion

- Proposal: `openspec/changes/archive/2026-08-13-configurable-representative-window/proposal.md`
- Exploration: `openspec/changes/archive/2026-08-13-configurable-representative-window/exploration.md`
- Specification: `openspec/changes/archive/2026-08-13-configurable-representative-window/specs/provider-usage-display/spec.md` (delta, now merged)
- Design: `openspec/changes/archive/2026-08-13-configurable-representative-window/design.md`
- Tasks: `openspec/changes/archive/2026-08-13-configurable-representative-window/tasks.md` (43/43 complete)
- Apply progress: `openspec/changes/archive/2026-08-13-configurable-representative-window/apply-progress.md`
- Verify report: `openspec/changes/archive/2026-08-13-configurable-representative-window/verify-report.md` (verdict: pass)

The change has been fully planned, implemented, verified, and archived. The live specification now reflects the configurable preference capability alongside preserved backward-compatible default behavior.
