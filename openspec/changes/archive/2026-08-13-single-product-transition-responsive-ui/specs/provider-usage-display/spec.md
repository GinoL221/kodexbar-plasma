# Delta for Provider Usage Display

## ADDED Requirements

### Requirement: Parallel package transition guidance

The installation and live-smoke documentation MUST identify `org.kde.plasma.kodexbar` as the legacy package and `org.kde.plasma.kodexbar.plasma` as the current package. It MUST explain that both package IDs MAY coexist, installation and updates of the current product MUST target `org.kde.plasma.kodexbar.plasma`, and users MUST add a new `KodexBar Plasma` widget rather than expect an existing legacy instance to change identity. Optional configuration-copy guidance MUST be manual and MUST preserve the destination instance's independent `General` settings: `codexbarCommand`, refresh interval, request timeout, and representative window. Guidance MUST NOT require package removal, panel mutation, or package/panel migration.

#### Scenario: Install the current product alongside legacy

- GIVEN the legacy package is installed
- WHEN a user follows current-product installation and add-widget guidance
- THEN `org.kde.plasma.kodexbar.plasma` is targeted and a new `KodexBar Plasma` instance is added
- AND the legacy package and its panel instances remain unchanged

#### Scenario: Update the current product

- GIVEN both package IDs coexist
- WHEN a user follows current-product update guidance
- THEN only `org.kde.plasma.kodexbar.plasma` is targeted
- AND no cross-ID conversion or removal is prescribed

#### Scenario: Optionally copy configuration

- GIVEN a user wants equivalent settings in a new current-product instance
- WHEN the optional copy guidance is followed
- THEN the four documented `General` settings are copied per instance
- AND no package identity or panel containment is rewritten

### Requirement: Constrained current-product usage rows

Within the current product's popup, provider and window usage rows MUST adapt to constrained available width. Every finite percentage selected for display MUST remain visible and non-clipped, the row's visible content MUST remain within its allocated bounds, and its progress bar MUST consume the width available after required labels and spacing without overflowing. These rules MUST NOT change the legacy UI.

#### Scenario: Finite percentage at constrained width

- GIVEN a current-product provider or window row has a finite percentage and constrained width
- WHEN the row is laid out
- THEN the percentage is visible in full and does not intersect or exceed the row bounds
- AND the progress bar occupies the remaining available width without clipping

#### Scenario: Wider allocation remains usable

- GIVEN the same current-product row receives additional width
- WHEN the row is laid out again
- THEN the percentage remains visible and non-clipped
- AND the progress bar expands to use the additional available width

### Requirement: Responsive contract preserves runtime boundaries

Responsive behavior MUST preserve package identity, all per-instance settings, provider data semantics, and exactly `usage --provider all --format json --json-only`. It MUST NOT change CLI contracts, providers, authentication, fetching, controller lifecycle, compact selection, or failure handling. Executable responsive tests MUST establish the constrained-width behavior before production changes and MUST pass through `./scripts/run-qml-tests.sh`.

#### Scenario: Responsive suite observes row geometry

- GIVEN constrained provider and window row fixtures with finite percentages
- WHEN `./scripts/run-qml-tests.sh` executes
- THEN tests observe visible non-clipped percentages, bounded row content, and progress bars using available width
- AND the exact all-provider command remains verified

#### Scenario: Unrelated behavior remains outside the change

- GIVEN the responsive and documentation acceptance checks pass
- WHEN the change is reviewed
- THEN package IDs, per-instance settings, panels, legacy UI, provider behavior, and lifecycle behavior are unchanged
