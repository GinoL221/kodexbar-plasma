# Delta for Provider Usage Display

## ADDED Requirements

### Requirement: Selected-provider enrichment

Selected-provider detail MUST map valid CLI-supplied `pace.primary`, `pace.secondary`, and `pace.tertiary` to Session, Weekly, and Monthly; show valid `credits.remaining`; and show reset-credit `availableCount` plus an expandable list of valid `credits[]` expirations only when the count is positive. Its header MUST show supplied account email and MAY show a human-readable organization, but MUST omit UUID/hex-like organizations. Tabs MUST contain an icon and short provider name only; `All` MUST remain compact and omit email, organization, pace, credits, resets, and cost.

#### Scenario: Valid enrichment is displayed
- GIVEN a selected provider supplies valid identity, pace, credit, and positive reset-credit data
- WHEN its detail is shown
- THEN values appear in the specified header, window, credit, and reset sections

#### Scenario: Invalid or zero data is hidden
- GIVEN enrichment is absent, malformed, non-finite, or reset `availableCount` is zero
- WHEN detail is shown
- THEN affected fields or sections are omitted without placeholders or failure

#### Scenario: Expirations are accessible
- GIVEN positive reset credits include valid expirations
- WHEN the keyboard-reachable disclosure is activated
- THEN it announces expanded state and exposes the expirations without a redeem action

#### Scenario: Privacy remains provider-scoped
- GIVEN email and an opaque organization are supplied
- WHEN tabs, `All`, and selected detail render
- THEN only the selected header shows email, organization is omitted, and tabs show icon plus short name

### Requirement: Protected native presentation

Enrichment MUST preserve exactly `usage --provider all --format json --json-only`, usage ownership, snapshots, timeout/failure distinctions, coalescing, and stale-response handling. Native Plasma/Kirigami UI MUST remain keyboard operable, popup-bounded, horizontally unclipped, and readable in Breeze Light and Dark.

#### Scenario: Usage regression and responsive checks
- GIVEN enriched fixtures at narrow and normal popup widths
- WHEN `./scripts/run-qml-tests.sh`, lint, package validation, and live theme/keyboard smoke run
- THEN the exact usage lifecycle passes and all content remains reachable and theme-readable

## MODIFIED Requirements

### Requirement: Provider-focused exclusions

The plasmoid MUST NOT compute or fabricate pace, credits, resets, identity, organization, cost, or tokens. It MAY display only the selected-provider fields authorized above, prior version/login/details, and cost governed by `provider-cost-estimate`; other raw fields MUST remain unrendered. It MUST NOT add auth, Add Account, Quit, redeem/mutation, pricing tables, QML price calculation, CLI/provider switching, persistent selection, provider implementation, or external data changes.
(Previously: pace, credits, cost, email, organization, and tokens were prohibited from display.)

#### Scenario: Missing commercial or reset data
- GIVEN output lacks valid commercial or reset data
- WHEN usage is displayed
- THEN none is fabricated or requested and unavailable sections are absent

#### Scenario: Verbatim passthrough of unmodeled fields
- GIVEN a provider carries unmodeled CLI-supplied fields
- WHEN normalized
- THEN they remain unmodified under `raw` and are neither computed nor fabricated

#### Scenario: Raw preservation authorizes bounded display
- GIVEN richer raw data is normalized
- WHEN any non-selected or selected-provider surface renders
- THEN only fields authorized for that surface appear and no raw diagnostics are exposed

#### Scenario: Fixture provenance and redaction
- GIVEN committed usage fixtures and capture documentation
- WHEN inspected
- THEN real CLI version/date and key/type fidelity are recorded while sensitive leaf values are substituted

## Non-Goals

Authentication, account management, quit/redeem actions, provider or CLI changes, price calculation, and changes to the authoritative usage lifecycle are excluded.
