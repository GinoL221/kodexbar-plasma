# Delta for Provider Cost Estimate

## MODIFIED Requirements

### Requirement: Provider-specific cost contract

For a supported selected provider, the system MUST invoke exactly `cost --provider {provider} --format json --json-only` through the validated configured executable. A successful matching payload MUST render CLI-supplied `sessionCostUSD`, `sessionTokens`, `last30DaysCostUSD`, and `last30DaysTokens` only in selected detail. Session and 30-day figures MUST render as a two-part row — the period name ("Today" / "Last 30 days") left, the formatted cost/token value right-aligned. Cost values MUST use a fixed comma-decimal, period-thousands-grouped format (e.g. `$36,27`); token counts >= 1000 MUST abbreviate with a K/M/B suffix and one decimal place (e.g. `108,2M`), values under 1000 render as a plain integer; neither format is locale-dependent. When `source === "local"`, a visible `"Local token-cost estimate"` caption MUST render below the values. It MUST NOT calculate prices.

#### Scenario: Matching local estimate
- GIVEN the selected provider returns a valid matching local payload
- WHEN cost completes
- THEN Session and 30-day rows appear as period-label-left / value-right, with the `"Local token-cost estimate"` caption visible

#### Scenario: All summary remains cost-free
- GIVEN one or more cost snapshots exist
- WHEN `All` is selected
- THEN no summary row displays cost or tokens

#### Scenario: Large values never use scientific notation
- GIVEN a cost or token value large enough that naive formatting could produce scientific notation
- WHEN the value renders
- THEN it appears as a plain grouped/abbreviated number, never in `e+`/`e-` form
