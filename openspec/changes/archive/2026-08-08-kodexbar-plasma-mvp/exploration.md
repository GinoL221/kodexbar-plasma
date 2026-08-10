## Exploration: kodexbar-plasma-mvp

### Current State
The repository is a working copy of the installed Plasma 6 applet, not an empty shell: `main.qml` is a 1,429-line single-file UI/controller. It uses `PlasmoidItem` compact/full representations, `Plasma5Support.DataSource` with the executable engine, and a refresh `Timer`. It currently supports provider/source selection and a sequential Linux-friendly fallback list, normalizes flexible CLI payloads, renders provider cards and rate windows, and separately invokes `codexbar cost`.

The local CLI command `codexbar usage --provider all --format json --pretty` returned an array containing usable providers and per-provider `error` objects. Successful entries expose `provider`, `source`, and `usage.primary|secondary|tertiary` windows with `usedPercent`, optional `resetsAt`/`resetDescription`, and `updatedAt`; fields are nullable. Sources observed include `oauth`, `claude`, `oauth-api`, `api`, `web`, and `auto`--not only `web`/`local`. The executable's help confirms `--provider all` honors upstream enabled-provider toggles. Its displayed version was `CodexBar unknown`, so the requested v0.48.1 cannot be confirmed locally.

### Affected Areas
- `metadata.json` -- retained Plasma package identity; its fork-specific ID is `org.kde.plasma.kodexbar.plasma`, distinct from the installed `org.kde.plasma.kodexbar`.
- `contents/ui/main.qml` -- primary MVP replacement target: collapse custom candidate fallback, cost scan, optional dashboard/status/credits UI, and multi-chip selection into one all-provider fetch, compact summary, and focused popup.
- `contents/config/main.xml` -- reduce settings to absolute CLI path and refresh interval (retain Plasma KConfig defaults and bounds).
- `contents/ui/config/configGeneral.qml` -- simplify to a native `Kirigami.FormLayout` for the two MVP settings; the CLI path must be explicitly documented/validated as absolute.
- `contents/config/config.qml` -- retained configuration category entry point.
- `contents/icons/providers/` -- retain available provider assets, while providing a safe fallback for CLI provider IDs with no asset.
- `README.md` -- update scope and operational guidance, including the OpenCode Go cookie sync prerequisite.
- `skills/plasma-kirigami-ui/SKILL.md` -- governing project constraint: Plasma/Kirigami primitives, themed icons, panel sizing, accessibility, and no provider/auth/fetch reimplementation.
- `.atl/skill-registry.md` -- records the project skill used by follow-on UI work; no functional change expected.

### Approaches
1. **Focused single-plasmoid rewrite** -- retain the `PlasmoidItem`, executable `DataSource`, timer, JSON parsing boundary, and package/config wiring; replace the broad UI/controller behavior with one `usage --provider all --format json --json-only` request and a small normalized presentation model.
   - Pros: Directly expresses the MVP; removes `cost` and custom provider fallback complexity; keeps native proven Plasma plumbing.
   - Cons: Requires deliberate regression coverage for heterogeneous/null payload fields.
   - Effort: Medium.

2. **Incremental feature flags over the copied widget** -- preserve selection, fallback, cost, and optional display controls while changing defaults to all providers.
   - Pros: Lower immediate code churn; retains current capabilities.
   - Cons: Violates MVP focus, obscures behavior, and keeps a 1,429-line coupled controller for a smaller product.
   - Effort: Medium-High.

### Recommendation
Choose the focused rewrite. Keep the native applet lifecycle and command execution mechanism, but make `--provider all` the sole usage query and treat the CLI response as authoritative. The popup should be a scrollable provider list whose rows show provider, returned source, Session/Weekly/Monthly when present, reset text, and an inline recoverable error state; do not infer providers, credentials, or source availability. The compact representation should deterministically show the provider/window with the highest known `usedPercent`, falling back to a short loading/error/no-data state.

First implementation slice: package identity and settings remain intact; implement one request, normalization for the three named windows, compact worst-percent selection, provider/error/loading/empty states, manual refresh, and timer refresh. Explicit non-goals: `codexbar cost`, charts, provider/source switching, account/auth/cookie editing, custom provider probing/fallback, notifications, and any provider implementation.

### Risks
- `--provider all` yields a mixed array of successes and expected provider/runtime errors on Linux; the popup needs a bounded error presentation so unavailable providers do not drown usable data.
- The CLI payload and provider IDs are version-dependent; nullable windows, arbitrary source values, missing icons, malformed/no output, nonzero exits, and timeout/concurrent refresh handling require defensive normalization.
- The requested “web/local” source label does not match the observed usage contract (`oauth`, `claude`, `oauth-api`, `api`, `web`, `auto`); proposal must define whether “local” means an explicit UI classification or whether the raw CLI source is shown.
- OpenCode Go requires the external `codexbar-sync-opencodego-cookie` workflow; the applet may explain that failure but must not run or automate credential sync.
- The current file couples data acquisition, normalization, and rendering. A clean MVP rewrite may approach the 800-line review budget unless split into focused QML components during design/tasks.
- CodeGraph was unavailable because the project has no index; per project instruction it was not initialized, so exploration used direct source reads.

### Ready for Proposal
Yes -- proceed with a proposal that confirms two product choices: (1) whether the popup lists every CLI result including expected failures or prioritizes usable providers with an error summary, and (2) whether source is displayed verbatim or mapped to a documented `web`/`local` classification. The proposal should also record the absolute-path validation behavior and a rollback path to the installed upstream applet, whose runtime ID remains separate.
