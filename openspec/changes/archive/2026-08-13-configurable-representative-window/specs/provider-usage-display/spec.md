# Delta for Provider Usage Display

## MODIFIED Requirements

### Requirement: Provider presentation

On open, the popup MUST select the first response-ordered provider having a window. A native selector MUST expose `All` and usable providers with name, authoritative icon or themed fallback, and exact `source`. `All` MUST show providers in response order with exactly one summary row per provider. Each summary row MUST preserve provider identity and MUST show exactly one representative usage bar when a finite `usedPercent` exists in that provider's effective window. A persisted global `preferredRepresentativeWindow` setting (Automatic default, or Session, Weekly, Monthly) governs the effective window uniformly for every provider in `All`; no per-provider override exists. Automatic, absent, or an unrecognized value MUST select the first finite value in Session, then Weekly, then Monthly order, unchanged from prior behavior. An explicit window with a finite value for that provider MUST be used. An explicit window with no finite value for that provider MUST fall back to that automatic order for that provider only. When no window has a finite value, the row MUST show identity only and MUST NOT invent a percentage or bar, regardless of the setting. A fallback bar MUST render with no visual distinction beyond its existing per-window label. This setting MUST NOT affect compact-panel selection (Requirement: Deterministic compact summary), which stays fixed. This persisted settings-panel preference differs from the transient popup provider/tab selection banned under Requirement: Provider-focused exclusions and MUST NOT be read as that banned persistent selection. `All` rows MUST NOT expand or expose additional window detail. Existing provider tabs MUST continue to show every supplied Session, Weekly, and Monthly window with exact raw resets; missing values MUST be omitted. Selection MUST be transient. Refresh or reorder MUST preserve `All` or the selected provider by identity; otherwise it MUST select the first usable provider, or `All`. Reopening MUST reapply the default.

(Previously: unconditional Session → Weekly → Monthly order with no configurable preference.)

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

- GIVEN Session, Weekly, and Monthly percentages are missing, nonnumeric, or non-finite, for any `preferredRepresentativeWindow` value
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

#### Scenario: Explicit preferred window with a finite value

- GIVEN `preferredRepresentativeWindow` is Weekly and a provider has a finite Weekly percentage
- WHEN `All` is displayed
- THEN exactly one bar uses that provider's Weekly percentage

#### Scenario: Per-provider fallback under an explicit preference

- GIVEN `preferredRepresentativeWindow` is Monthly; one provider lacks a finite Monthly value but has a finite Session value; another provider has a finite Monthly value
- WHEN `All` is displayed
- THEN the first provider falls back to Session while the second still uses Monthly

#### Scenario: Automatic preserves current default behavior

- GIVEN `preferredRepresentativeWindow` is Automatic, absent, or an unrecognized persisted value
- WHEN `All` is displayed
- THEN every provider's bar selection follows the exact Session-then-Weekly-then-Monthly order, unchanged

#### Scenario: Preference is global, not per-provider

- GIVEN `preferredRepresentativeWindow` is set to an explicit window
- WHEN `All` is displayed
- THEN the same preferred window governs selection for every provider uniformly, with no per-provider override

#### Scenario: Fallback bar has no special visual treatment

- GIVEN a provider's bar is rendered via automatic fallback rather than the explicit preference
- WHEN `All` is displayed
- THEN the bar uses identical styling to any other representative bar, distinguished only by its existing per-window label
