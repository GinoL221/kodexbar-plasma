# Delta for Provider Usage Display

## ADDED Requirements

### Requirement: Conditional provider header metadata and dynamic details

The selected-provider header MUST show only CLI-supplied `version` and `loginMethod` as new metadata, omitting absent or invalid values without placeholders. Valid, non-excluded `usage.details[]` titles and label/value rows MUST appear verbatim in an accessible, theme-adaptive section that is collapsed by default and pointer- or keyboard-expandable. Invalid details MUST be ignored. Expanded content MUST remain popup-bounded and vertically scrollable without horizontal overflow.

#### Scenario: Header metadata is conditional

- GIVEN providers supply valid, absent, empty, or malformed version and login method values
- WHEN their provider views are displayed
- THEN valid values appear without additional raw metadata
- AND invalid values and their placeholders are omitted

#### Scenario: Details are collapsed and accessible

- GIVEN valid, non-excluded details in Breeze Light or Dark
- WHEN the provider view opens and the focused control is keyboard-activated
- THEN the control begins collapsed and reveals the supplied text verbatim
- AND its purpose and changed state are accessible and theme-readable

#### Scenario: Invalid details are safe

- GIVEN details are missing, non-array, or contain malformed entries or rows
- WHEN the provider view is displayed
- THEN invalid content is omitted without failure
- AND existing header and usage-window content remains available

#### Scenario: Expanded details remain bounded

- GIVEN expanded valid details exceed the popup's available height or width
- WHEN the user navigates the expanded content
- THEN vertical scrolling keeps all content reachable within the popup
- AND no horizontal overflow obscures content or controls

#### Scenario: Presentation enrichment preserves runtime boundaries

- GIVEN header metadata or dynamic details are displayed
- WHEN usage refreshes or the compact view is evaluated
- THEN normalized provider data, request lifecycle, and compact selection remain unchanged
- AND the exact all-provider CLI request remains unchanged

## MODIFIED Requirements

### Requirement: Provider-focused exclusions

The plasmoid MUST NOT compute, request, fabricate, or display pace, credit, cost, or token data; it MAY preserve those and other unmodeled CLI-supplied fields verbatim in the normalized snapshot without rendering them. It MUST NOT display email or organization. From preserved richer data, the popup MAY display only conditional version, login method, and valid `usage.details[]` content that does not carry an excluded field. The plasmoid MUST NOT add calculated reset durations, auth, CLI/provider switching, persistent selection, or external data changes.

(Previously: preserved richer data could not be rendered; version, login method, and dynamic details had no narrowly authorized display path.)

#### Scenario: Missing commercial or reset data

- GIVEN output lacks commercial fields or calculated reset duration
- WHEN usage is displayed
- THEN none is fabricated or requested

#### Scenario: Verbatim passthrough of unmodeled provider fields

- GIVEN a provider entry carries CLI-supplied top-level fields the normalizer does not model, such as `pace` (e.g. `pace.secondary.stage`, `pace.secondary.summary`, `pace.secondary.deltaPercent`), `credits.remaining`, `identity.accountEmail`, `version`, `loginMethod`, `codexResetCredits`, `providerCost`, or a generic `usage.details[]` array of `{title, rows: [{label, value, secondaryValue}]}` entries
- WHEN the entry is normalized
- THEN those fields are preserved unmodified under a `raw` key on the normalized provider entry, and none of them is computed, requested, or fabricated

#### Scenario: Raw preservation authorizes only approved display fields

- GIVEN a normalized provider entry carries preserved richer data
- WHEN the popup renders that provider
- THEN only version, login method, and valid non-excluded details MAY be newly displayed
- AND email, organization, pace, credit, cost, and token values are never displayed

#### Scenario: Real capture fixture provenance and redaction

- GIVEN the committed contract fixture under `tests/fixtures/`
- WHEN it is inspected
- THEN it originates from a documented run of the real CLI on the user's machine, records its CodexBar version and capture date, contains no fabricated field, and every key and type present in the original capture survives redaction with only sensitive leaf values substituted
