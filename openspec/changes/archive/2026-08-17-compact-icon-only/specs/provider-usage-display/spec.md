# Delta for Provider Usage Display

## ADDED Requirements

### Requirement: Compact panel presentation

The compact/panel representation MUST show only the KodexBar logo icon, sized at least `Kirigami.Units.iconSizes.smallMedium`, with no visible percentage or status text beside it. The current percentage/status text MUST remain available through the control's accessible name for assistive technology.

#### Scenario: Icon-only panel button
- GIVEN the compact representation renders
- WHEN the panel button is shown
- THEN only the logo icon is visible, at or above `iconSizes.smallMedium`, with no adjacent text label

#### Scenario: Percentage remains accessible
- GIVEN a computed usage percentage exists
- WHEN the panel button's accessible name is queried
- THEN it still reports the percentage, even though no visible text shows it
