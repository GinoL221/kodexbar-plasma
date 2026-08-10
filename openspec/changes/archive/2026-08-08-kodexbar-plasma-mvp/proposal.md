# Proposal: KodexBar Plasma MVP

## Intent

Give Plasma users one trustworthy at-a-glance view of all CLI-enabled provider usage without provider probing, authentication logic, or duplicated fetching. The plasmoid will preserve the external `codexbar` boundary while replacing the current broad, coupled UI with a focused MVP.

## Product Outcome

- The compact panel shows the globally highest known usage percentage.
- The popup presents usable providers, returned source values, available Session/Weekly/Monthly windows, and CLI-provided reset information.
- Loading, empty, malformed, timeout, nonzero-exit, and mixed provider-error states are understandable and recoverable.

## Scope

### In Scope
- One `usage --provider all --format json --json-only` request using the configured absolute CLI path.
- Native Plasma/Kirigami compact representation and scrollable popup provider list.
- Configurable refresh interval and manual refresh.
- Defensive normalization of nullable `provider`, `source`, usage windows, reset fields, and errors.
- OpenCode Go cookie-sync prerequisite documented only; no automation.

### Out of Scope
- `codexbar cost`, charts, notifications, fine-grained provider/source switching, credential/account reset actions, provider implementation, or custom fallback probing.
- Mapping raw CLI sources to invented `web`/`local` categories.

## Business Rules and Edge Cases

- Mixed results prioritize usable provider data; expected failures appear in an expandable bounded error summary, not as peer rows.
- Display `source` and reset date/time/text exactly as returned by the CLI.
- Compact selection chooses highest valid `usedPercent`; ties use window priority `Session > Weekly > Monthly`, then first provider in CLI response order.
- With no valid percentage, show Loading, Error, or No data from global state; never invent a value.
- Missing icons use a safe themed fallback. Missing windows are omitted. Reset means display only.

## Capabilities

### New Capabilities
- `provider-usage-display`: All-provider usage retrieval, normalization, compact worst-percent summary, popup rows, states, and refresh behavior.

### Modified Capabilities
- None.

## Approach

Focused rewrite retaining `PlasmoidItem`, `DataSource`, timer, package identity, and configuration wiring. Reduce settings to absolute CLI path and refresh interval; use native Kirigami/Plasma primitives and themed assets.

## Affected Areas

| Area | Impact | Description |
|---|---|---|
| `contents/ui/main.qml` | Modified | Replace fallback/cost/selection logic with the MVP model and views. |
| `contents/config/main.xml`, `contents/ui/config/configGeneral.qml` | Modified | Retain only path and refresh settings with absolute-path guidance. |
| `contents/icons/providers/` | Modified | Preserve assets and add safe fallback behavior. |
| `README.md` | Modified | Document scope and OpenCode Go prerequisite. |
| `metadata.json`, `contents/config/config.qml` | Retained | Preserve fork identity and configuration entry point. |

## Risks and Open Decisions

- CLI schema/version drift, malformed output, concurrent refreshes, and mixed errors require defensive handling and focused verification.
- A single-file rewrite may approach the 800-line review budget; design should split only where it improves reviewability without changing scope.
- Absolute path validation UX and exact bounded error-summary interaction remain design details.

## Rollback Plan

Revert the change files and reinstall/restore the prior fork package. The installed upstream applet remains separately identifiable as `org.kde.plasma.kodexbar`; no migration or data mutation is required.

## Success Criteria

- [ ] All MVP states and provider/window rules are represented without CLI-boundary reimplementation.
- [ ] Refresh, absolute-path configuration, raw source/reset display, and deterministic compact selection work against heterogeneous nullable CLI payloads.
- [ ] Review remains within the 800 changed-line budget or is split before implementation.
