---
name: plasma-kirigami-ui
description: "Trigger: Plasma 6 QML, Kirigami, Breeze, plasmoid UI. Build native KDE interfaces and reject web-generic patterns."
license: Apache-2.0
metadata:
  author: "kodexbar-plasma"
  version: "1.0"
---

## Activation Contract

Load this skill before creating or changing QML, Kirigami, Plasma applet, or configuration UI in this repository.

## Hard Rules

- Use Plasma 6 and Kirigami primitives, `Kirigami.Units`, `Kirigami.Theme`, and Breeze/system styling.
- Prefer `org.kde.plasma.components`, `QtQuick.Controls`, `Kirigami.FormLayout`, and native Plasma applet representations where appropriate.
- Preserve keyboard navigation, accessible labels, theme adaptation, compact panel sizing, and Plasma interaction conventions.
- Do not introduce HTML, CSS, JavaScript web layouts, browser metaphors, web breakpoints, emoji icons, or generic web-dashboard patterns.
- Keep the external `codexbar` CLI boundary; UI code must not reimplement providers, authentication, or fetching.

## Decision Gates

| Need | Choose |
| --- | --- |
| Panel content | `compactRepresentation` and native Plasma layout primitives |
| Popup content | Kirigami/Plasma components with system units and theme colors |
| Settings | Plasma configuration model plus `Kirigami.FormLayout` |
| Icon | Existing themed/vector icon; never an emoji or web icon package |

## Execution Steps

1. Inspect nearby QML and reuse its established Plasma/Kirigami patterns.
2. Implement the smallest native component that fits the applet surface.
3. Check light/dark theme behavior, keyboard access, sizing, and narrow panel layouts.
4. Verify no web-generic dependency or stale runtime identity was introduced.

## Output Contract

Return changed QML/configuration paths and the native Plasma/Kirigami conventions applied.

## References

- `../../metadata.json` — applet identity and Plasma package metadata.
- `../../contents/ui/` — existing native QML patterns.
