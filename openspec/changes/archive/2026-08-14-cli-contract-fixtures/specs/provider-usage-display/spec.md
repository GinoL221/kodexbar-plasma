# Delta for Provider Usage Display

## MODIFIED Requirements

### Requirement: Provider-focused exclusions

The plasmoid MUST NOT compute, request, fabricate, or display cost, credit, or token data; it MAY preserve CLI-supplied cost, credit, token, or other unmodeled fields verbatim in the normalized snapshot without rendering them. The plasmoid MUST NOT add calculated reset durations, auth, CLI/provider switching, persistent selection, or external data changes.

(Previously: the plasmoid MUST NOT add cost, credits, tokens, calculated reset durations, auth, CLI/provider switching, persistent selection, or external data changes — a blanket prohibition that did not distinguish preservation from presentation and did not permit retaining CLI-supplied commercial fields in the normalized snapshot even when nothing is rendered from them.)

#### Scenario: Missing commercial or reset data

- GIVEN output lacks commercial fields or calculated reset duration
- WHEN usage is displayed
- THEN none is fabricated or requested

#### Scenario: Verbatim passthrough of unmodeled provider fields

- GIVEN a provider entry carries CLI-supplied top-level fields the normalizer does not model, such as `pace` (e.g. `pace.secondary.stage`, `pace.secondary.summary`, `pace.secondary.deltaPercent`), `credits.remaining`, `identity.accountEmail`, `version`, `loginMethod`, `codexResetCredits`, `providerCost`, or a generic `usage.details[]` array of `{title, rows: [{label, value, secondaryValue}]}` entries
- WHEN the entry is normalized
- THEN those fields are preserved unmodified under a `raw` key on the normalized provider entry, and none of them is computed, requested, or fabricated

#### Scenario: Raw preservation does not authorize display

- GIVEN a normalized provider entry carries a preserved `raw` sibling
- WHEN the popup renders that provider
- THEN no cost, credit, token, pace, or other commercial or richer field from `raw` is displayed, and preservation in the snapshot is not read as permission to render it

#### Scenario: Real capture fixture provenance and redaction

- GIVEN the committed contract fixture under `tests/fixtures/`
- WHEN it is inspected
- THEN it originates from a documented run of the real CLI on the user's machine, records its CodexBar version and capture date, contains no fabricated field, and every key and type present in the original capture survives redaction with only sensitive leaf values substituted

### Requirement: Provider presentation

On open, the popup MUST select the first response-ordered provider having a window. A native selector MUST expose `All` and usable providers with name, exact `source`, and either an authoritative icon or a themed fallback; every bundled provider icon MUST be visually distinct from every other bundled provider's icon and MUST adapt to the active Breeze theme, remaining a visible, non-blank mark in both Breeze Light and Breeze Dark rather than a fixed light-only or dark-only rendering. A bundled icon MUST NOT rely on a hardcoded absolute literal color (including pure white or pure near-black) that renders it indistinguishable from its background in either theme; bundled icons use `fill="currentColor"` (and `stroke="currentColor"` where the source strokes), matching the repository's existing theme-adaptive SVG convention, unless a documented literal-color fallback is used after a proven `Kirigami.Icon` theme-adaptation defect, in which case that fallback MUST remain legible against both Breeze Light and Breeze Dark panel backgrounds. `All` MUST show providers in response order with exactly one summary row per provider. Each summary row MUST preserve provider identity and MUST show exactly one representative usage bar when a finite `usedPercent` exists in that provider's effective window. A persisted global `preferredRepresentativeWindow` setting (Automatic default, or Session, Weekly, Monthly) governs the effective window uniformly for every provider in `All`; no per-provider override exists. Automatic, absent, or an unrecognized value MUST select the first finite value in Session, then Weekly, then Monthly order, unchanged from prior behavior. An explicit window with a finite value for that provider MUST be used. An explicit window with no finite value for that provider MUST fall back to that automatic order for that provider only. When no window has a finite value, the row MUST show identity only and MUST NOT invent a percentage or bar, regardless of the setting. A fallback bar MUST render with no visual distinction beyond its existing per-window label. This setting MUST NOT affect compact-panel selection (Requirement: Deterministic compact summary), which stays fixed. This persisted settings-panel preference differs from the transient popup provider/tab selection banned under Requirement: Provider-focused exclusions and MUST NOT be read as that banned persistent selection. `All` rows MUST NOT expand or expose additional window detail. Existing provider tabs MUST continue to show every supplied Session, Weekly, and Monthly window with exact raw resets; missing values MUST be omitted. Selection MUST be transient. Refresh or reorder MUST preserve `All` or the selected provider by identity; otherwise it MUST select the first usable provider, or `All`. Reopening MUST reapply the default. The stable four-key contract — `provider`, `source`, and `windows[]` (with each window's `key`, `label`, `usedPercent`, `resetsAt`, and `resetDescription`) — MUST remain shape-stable in value, type, and ordering across normalization; additive siblings on a provider entry, such as a verbatim `raw` passthrough, MAY be present without altering that stability.

(Previously: a bundled icon or themed fallback was accepted with no requirement that it be visually distinct per provider or adapt to the active Breeze theme, permitting hardcoded literal-color icons that could render as a blank block or an invisible mark in one theme; the four-key contract's stability under additive provider-entry fields was unaddressed, with no explicit guarantee constraining whether a new key could alter `provider`, `source`, or `windows[]` value, type, or ordering.)

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

#### Scenario: Four-key contract values are unregressed by raw addition

- GIVEN any payload already covered by an existing `UsageModelTest` scenario
- WHEN it is normalized
- THEN `provider`, `source`, and every `windows[]` entry's `key`, `label`, `usedPercent`, `resetsAt`, and `resetDescription` equal their current values exactly, unaffected by the additive `raw` sibling

#### Scenario: Window-level unknown-key dropping remains unchanged

- GIVEN a `usage` object containing an unrecognized window key
- WHEN it is normalized
- THEN `windows` contains only recognized windows, exactly as before the `raw` addition

#### Scenario: Error entries remain unaffected by raw addition

- GIVEN an entry with a non-null `error`
- WHEN it is normalized
- THEN it is still routed to `errors` with `{provider, source, error}` and does not appear in `providers`, and gains no `raw` sibling
