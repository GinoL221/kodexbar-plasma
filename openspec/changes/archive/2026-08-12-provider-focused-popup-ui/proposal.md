# Proposal: Provider-Focused Popup UI

## Intent

Make the popup easier to scan by prioritizing one usable provider while retaining a cross-provider view, without inventing data or changing the runtime contract.

## Goals and User Outcome

- Open on the first usable provider, not `All`.
- Select `All` or any returned provider through a native selector.
- Show provider name, themed icon, and raw source when available.
- Show individual Session/Weekly/Monthly windows with progress bars.
- Keep `All` available as a compact per-provider summary.
- Omit missing percentage/reset fields; never fabricate zeroes, placeholders, or calculated durations.

## Scope

### In Scope
- Presentation-only selector and transient selection state.
- Provider-focused detail view for every available window.
- Compact `All` summary per provider.
- Native Plasma/Kirigami controls, theme adaptation, keyboard access, and narrow-popup support.
- QML harnesses and live-Plasma smoke checks.

### Out of Scope / Non-Goals
- Cost, credits, tokens, auth, CLI provider switching, or CLI changes.
- Calculated reset durations, new sources, persistent selection, per-provider refresh, or panel changes.
- Lifecycle, errors, snapshots, refresh/coalescing, timeouts, or data-contract changes.

## Product Rules

- Refresh continues to invoke exactly `usage --provider all --format json --json-only`.
- Provider order follows the response; the first provider with usable windows is the initial selection.
- `All` remains selectable and summarizes each provider compactly.
- Detail mode renders Session, Weekly, and Monthly only when supplied.
- Raw `source`, `resetsAt`, and `resetDescription` remain exact and informational.
- Existing icon lookup and fallback remain authoritative.

## Capabilities

### New Capabilities
- None; this is a presentation extension of provider usage display.

### Modified Capabilities
- `provider-usage-display`: define provider selection, first-usable default, compact `All` summaries, detailed windows, and omission rules.

## Approach and Affected Areas

Add a native selector and detail component; make `main.qml` switch between detail and compact `All`. Keep model, controller, errors, compact representation, and CLI boundary unchanged. Update harnesses and `docs/live-plasma-smoke.md`.

## Implications and Risks

| Risk | Mitigation |
|---|---|
| Selector overflow or long names | Native scrolling/truncation and keyboard-reachable entries. |
| Missing values misrepresented | Render only finite/supplied fields; test null and heterogeneous data. |
| Regression under 400-line budget | Surgical QML changes and focused harnesses; forecast before apply. |
| Selection and refresh diverge | Keep selection presentation-only. |

## Rollback Plan

Revert selector/detail QML, harness, smoke-guide, and delta-spec changes; unchanged runtime code and snapshots remain the baseline.

## Acceptance Direction

- Popup opens on the first usable provider and can reach `All` and every provider by keyboard.
- Detail and `All` views preserve order, raw values, failures, and omission behavior.
- Existing lifecycle/error/snapshot and exact-command tests remain green; new harnesses cover selection and incomplete data.
