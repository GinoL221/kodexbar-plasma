# Delta for Provider Usage Display

## MODIFIED Requirements

### Requirement: Provider presentation

On open, the popup MUST select the first response-ordered provider having a window. A native selector MUST expose `All` and usable providers with name, authoritative icon or themed fallback, and exact `source`. `All` MUST show providers in response order with exactly one summary row per provider. Each summary row MUST preserve provider identity and MUST show exactly one representative usage bar when a finite `usedPercent` exists, selecting the first finite value in Session, then Weekly, then Monthly order. When none of those windows has a finite value, the row MUST show identity only and MUST NOT invent a percentage or bar. `All` rows MUST NOT expand or expose additional window detail. Existing provider tabs MUST continue to show every supplied Session, Weekly, and Monthly window with exact raw resets; missing values MUST be omitted. Selection MUST be transient. Refresh or reorder MUST preserve `All` or the selected provider by identity; otherwise it MUST select the first usable provider, or `All`. Reopening MUST reapply the default.

(Previously: `All` showed compact summaries without requiring exactly one provider bar or defining Session-to-Weekly-to-Monthly representative selection.)

#### Scenario: Heterogeneous providers

- GIVEN providers with nullable source, windows, reset fields, or unknown icons
- WHEN results are displayed
- THEN values are preserved, absent fields are omitted, and a themed fallback icon is used

#### Scenario: Session is representative

- GIVEN a provider has finite Session, Weekly, and Monthly percentages
- WHEN `All` is displayed
- THEN exactly one bar uses the Session percentage for that provider

#### Scenario: Representative fallback order

- GIVEN Session is missing or non-finite and Weekly and Monthly are finite
- WHEN `All` is displayed
- THEN exactly one bar uses the Weekly percentage for that provider

#### Scenario: Monthly is the only finite window

- GIVEN only Monthly has a finite percentage
- WHEN `All` is displayed
- THEN exactly one bar uses the Monthly percentage for that provider

#### Scenario: Provider has no finite percentage

- GIVEN Session, Weekly, and Monthly percentages are missing, nonnumeric, or non-finite
- WHEN `All` is displayed
- THEN the provider identity remains visible without a bar or invented percentage

#### Scenario: Full detail remains in provider tab

- GIVEN a provider supplies Session, Weekly, and Monthly windows
- WHEN its provider tab is selected
- THEN every supplied window and exact raw reset remains visible

#### Scenario: All summaries are not expandable

- GIVEN a provider summary is visible in `All`
- WHEN the user navigates or activates the row
- THEN no inline window details or expandable content are revealed
