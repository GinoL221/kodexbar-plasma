# Design: CLI data to Plasma UI

KodexBar Plasma is a read-oriented CLI consumer, not a provider integration. This describes the current implementation; [ROADMAP.md](../ROADMAP.md) separates deferred work from shipped behavior. For user scope and privacy, see [product.md](product.md); for setup, see the [README](../README.md).

## Data flow

1. [main.qml](../contents/ui/main.qml) starts refreshes and wires the compact control, popup, settings, cost and notifications. [UsageController.qml](../contents/ui/UsageController.qml) validates the configured absolute path or checks bounded discovery locations, then runs `usage --format json --json-only`. No `--provider all` argument is passed; the external CLI's omitted-option semantics are not verified here.
2. The controller parses JSON and [UsageModel.js](../contents/code/UsageModel.js) normalizes provider windows and errors. Requests are serialized with generation guards and a watchdog; path, timeout and parse failures retain the previous committed snapshot. A nonzero exit with usable JSON is still processed and can change the provider list. [RateLimitPolicy.js](../contents/code/RateLimitPolicy.js) supports backoff and retaining rate-limited provider data.
3. [SnapshotStorage.js](../contents/code/SnapshotStorage.js) persists nonempty normalized provider snapshots to local SQLite and hydrates them at startup. Snapshots can contain raw provider data and should be treated as sensitive; display filtering is not storage redaction.
4. [ProviderFilterPolicy.js](../contents/code/ProviderFilterPolicy.js) filters the presentation. [CompactUsageButton.qml](../contents/ui/CompactUsageButton.qml) renders an icon with accessible status; [ProviderSelector.qml](../contents/ui/ProviderSelector.qml) defaults to Overview and reconciles selection on reopen or data changes. Provider rows render the overview or selected details.
5. [CostController.qml](../contents/ui/CostController.qml) independently requests `cost --provider {provider} --format json --json-only` for selected `codex` or `claude`. Invalid, failed or timed-out cost data does not block usage. [NotificationController.qml](../contents/ui/NotificationController.qml) evaluates committed usage and rate-limit state independently of popup opening.

## Interaction and trust boundaries

- Plasma/Kirigami controls, theme units, accessible names and keyboard interaction are the UI foundation. The [UI parity checklist](ui-parity-checklist.md) and [live smoke guide](live-plasma-smoke.md) describe review and manual verification; historical checklist claims are not necessarily current behavior.
- The CLI owns provider access and credentials. The widget validates and displays selected fields, filters sensitive-looking free-form details, and offers no account, redemption or reset mutations. Selected-provider identity may be displayed when valid. An optional [NaN wrapper](nan-adapter.md) is external to this boundary.
- The README's explicit `--provider all`, default-first-provider and visible panel-summary descriptions conflict with the source above. The popup code also suppresses individual provider failures rather than rendering the README's bounded provider-error summary. Resolve these documentation discrepancies separately; do not infer CLI defaults from them.
