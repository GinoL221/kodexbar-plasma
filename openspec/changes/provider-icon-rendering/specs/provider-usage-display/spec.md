# Delta for Provider Usage Display

## MODIFIED Requirements

### Requirement: Provider presentation

On open, the popup MUST select the first response-ordered provider having a window. A native selector MUST expose `All` and usable providers with name, exact `source`, and either an authoritative icon or a themed fallback; every bundled provider icon MUST be visually distinct from every other bundled provider's icon and MUST adapt to the active Breeze theme, remaining a visible, non-blank mark in both Breeze Light and Breeze Dark rather than a fixed light-only or dark-only rendering. A bundled icon MUST NOT rely on a hardcoded absolute literal color (including pure white or pure near-black) that renders it indistinguishable from its background in either theme; bundled icons use `fill="currentColor"` (and `stroke="currentColor"` where the source strokes), matching the repository's existing theme-adaptive SVG convention, unless a documented literal-color fallback is used after a proven `Kirigami.Icon` theme-adaptation defect, in which case that fallback MUST remain legible against both Breeze Light and Breeze Dark panel backgrounds. `All` MUST show providers in response order with exactly one summary row per provider. Each summary row MUST preserve provider identity and MUST show exactly one representative usage bar when a finite `usedPercent` exists in that provider's effective window. A persisted global `preferredRepresentativeWindow` setting (Automatic default, or Session, Weekly, Monthly) governs the effective window uniformly for every provider in `All`; no per-provider override exists. Automatic, absent, or an unrecognized value MUST select the first finite value in Session, then Weekly, then Monthly order, unchanged from prior behavior. An explicit window with a finite value for that provider MUST be used. An explicit window with no finite value for that provider MUST fall back to that automatic order for that provider only. When no window has a finite value, the row MUST show identity only and MUST NOT invent a percentage or bar, regardless of the setting. A fallback bar MUST render with no visual distinction beyond its existing per-window label. This setting MUST NOT affect compact-panel selection (Requirement: Deterministic compact summary), which stays fixed. This persisted settings-panel preference differs from the transient popup provider/tab selection banned under Requirement: Provider-focused exclusions and MUST NOT be read as that banned persistent selection. `All` rows MUST NOT expand or expose additional window detail. Existing provider tabs MUST continue to show every supplied Session, Weekly, and Monthly window with exact raw resets; missing values MUST be omitted. Selection MUST be transient. Refresh or reorder MUST preserve `All` or the selected provider by identity; otherwise it MUST select the first usable provider, or `All`. Reopening MUST reapply the default.

(Previously: a bundled icon or themed fallback was accepted with no requirement that it be visually distinct per provider or adapt to the active Breeze theme, permitting hardcoded literal-color icons that could render as a blank block or an invisible mark in one theme.)

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

#### Scenario: Every known provider renders a distinct, visible icon

- GIVEN every provider key in `contents/code/ProviderIcons.js` `knownProviders`
- WHEN its icon is rendered at `Kirigami.Units.iconSizes.smallMedium`
- THEN it renders a visible, non-blank mark that is visually distinguishable from every other provider's icon, in both Breeze Light and Breeze Dark

#### Scenario: No hardcoded literal color defeats theme adaptation

- GIVEN a bundled provider icon's SVG source
- WHEN the active Breeze theme changes between Light and Dark
- THEN the icon MUST NOT render a fixed white or fixed near-black mark that becomes indistinguishable from the panel background in either theme

#### Scenario: Codex and Azure OpenAI show their own brand mark

- GIVEN `codex.svg`, `azureopenai.svg`, and `openai.svg`
- WHEN their provider icons are rendered
- THEN each renders geometry visually distinct from the other two; none is byte-identical or visually identical to another provider's mark

#### Scenario: Documented literal-color fallback remains legible

- GIVEN the `currentColor` convention is proven inadequate for one icon by the manual smoke check
- WHEN a literal-color fallback is used for that icon instead
- THEN the fallback is documented as an exception and remains legible against both Breeze Light and Breeze Dark panel backgrounds

#### Scenario: Manual Breeze Light and Dark smoke check gates acceptance

- GIVEN no CI QML runtime exists to prove visual icon color or contrast
- WHEN the icon rendering fix is verified
- THEN a manual `plasmawindowed` smoke check, run once in Breeze Light and once in Breeze Dark per `docs/live-plasma-smoke.md`, confirms every provider in `knownProviders` renders a legible, distinct icon in both runs before the change is accepted

#### Scenario: Icon-only fix preserves unrelated runtime boundaries

- GIVEN the provider icon rendering fix is applied
- WHEN the change is reviewed
- THEN legacy and current package IDs, the exact `usage --provider all --format json --json-only` invocation (Requirement: Authoritative all-provider request), provider selection behavior, accessibility (Requirement: Native and accessible UI), the responsive layout (Requirement: Responsive contract preserves runtime boundaries), user configuration, and `contents/config/` remain unchanged
