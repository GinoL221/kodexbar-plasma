---
name: plasma-kirigami-ui
description: "Trigger: Plasma 6 QML, Kirigami, Breeze, plasmoid UI. Build native KDE interfaces and reject web-generic patterns."
license: Apache-2.0
metadata:
  author: "kodexbar-plasma"
  version: "1.2"
---

## Activation Contract

Load this skill before creating or changing QML, Kirigami, Plasma applet, or configuration UI in this repository.

## Hard Rules

- Use Plasma 6 and Kirigami primitives, `Kirigami.Units`, `Kirigami.Theme`, and Breeze/system styling.
- Prefer `org.kde.plasma.components`, `QtQuick.Controls`, `Kirigami.FormLayout`, and native Plasma applet representations where appropriate.
- Preserve keyboard navigation, accessible labels, theme adaptation, compact panel sizing, and Plasma interaction conventions.
- Do not introduce HTML, CSS, JavaScript web layouts, browser metaphors, web breakpoints, emoji icons, or generic web-dashboard patterns.
- Keep the external `codexbar` CLI boundary; UI code must not reimplement providers, authentication, fetching, or token pricing.
- CodexBar (Linux/macOS) screenshots are **information architecture** references only. Translate structure into Plasma; never clone macOS glass, fixed brand accent colors, or web dashboard cards.

## Decision Gates

| Need | Choose |
| --- | --- |
| Panel content | `compactRepresentation` and native Plasma layout primitives |
| Popup content | Kirigami/Plasma components with system units and theme colors |
| Settings | Plasma configuration model plus `Kirigami.FormLayout` |
| Icon | Existing themed/vector icon; never an emoji or web icon package |
| Spacing / density | `Kirigami.Units` only; no hard-coded px design tokens from web tools |
| Color | `Kirigami.Theme.*` only; no fixed light-only or dark-only paints |
| External design tools | Optional wireframes only; implementation authority stays this skill + checklist |

## Execution Steps

1. Inspect nearby QML and reuse its established Plasma/Kirigami patterns.
2. Prefer small presentational sections and JS extractors over growing `main.qml` / row god-objects.
3. Implement the smallest native component that fits the applet surface.
4. Check light/dark theme behavior, keyboard access, sizing, and narrow panel layouts.
5. Verify no web-generic dependency, fabricated metrics, or stale runtime identity was introduced.
6. Verify UI craft: walk `docs/ui-parity-checklist.md`, run `docs/live-plasma-smoke.md` on desktop, and spot-check Breeze Light/Dark.

## Output Contract

Return changed QML/configuration paths, the native Plasma/Kirigami conventions applied, and which checklist sections were verified (or explicitly deferred with reason).

## References

- `references/popup-and-layout-invariants.md` — Popup hierarchy, UsageWindowRow anatomy, standardized resets, and test invariants.
- `../../docs/ui-parity-checklist.md` — Craft / parity gate for popup and compact UI.
- `../../docs/live-plasma-smoke.md` — Live Plasma keyboard and theme smoke.
- `../../metadata.json` — Applet identity and Plasma package metadata.
- `../../contents/ui/` — Existing native QML patterns.
- `../../ROADMAP.md` — Backlog including visual regression work.
