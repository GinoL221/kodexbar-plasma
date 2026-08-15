---
name: plasma-kirigami-ui
description: "Trigger: Plasma 6 QML, Kirigami, Breeze, plasmoid UI. Build native KDE interfaces and reject web-generic patterns."
license: Apache-2.0
metadata:
  author: "kodexbar-plasma"
  version: "1.1"
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

## Popup information order

When extending the full representation, preserve this selected-provider order unless an SDD change explicitly revises it:

1. Provider tabs (`All` + usable providers)
2. Header (name, updated, plan/login, account email, human-readable org only)
3. Usage windows with optional pace lines
4. Credits remaining (when valid)
5. Reset-credit inventory only when `availableCount` > 0 (count + expandable expirations; no redeem)
6. Cost section only for selected supported providers with a valid CLI cost snapshot
7. Collapsed-by-default `usage.details[]`
8. Global error summary
9. Plasma-native chrome (refresh / configure) — no Auth, Add Account, or Quit

`All` stays a compact summary: no email, org, pace, credits, reset inventory, or cost.

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

## Craft verification

Before calling a UI change done:

1. Walk [docs/ui-parity-checklist.md](../../docs/ui-parity-checklist.md) for the surfaces you touched.
2. Run relevant sections of [docs/live-plasma-smoke.md](../../docs/live-plasma-smoke.md) on a real desktop (not offscreen).
3. Spot-check Breeze Light and Breeze Dark.

## Execution Steps

1. Inspect nearby QML and reuse its established Plasma/Kirigami patterns.
2. Prefer small presentational sections and JS extractors over growing `main.qml` / row god-objects.
3. Implement the smallest native component that fits the applet surface.
4. Check light/dark theme behavior, keyboard access, sizing, and narrow panel layouts.
5. Verify no web-generic dependency, fabricated metrics, or stale runtime identity was introduced.
6. Complete the UI parity checklist items that apply.

## Output Contract

Return changed QML/configuration paths, the native Plasma/Kirigami conventions applied, and which checklist sections were verified (or explicitly deferred with reason).

## References

- `../../docs/ui-parity-checklist.md` — craft / parity gate for popup and compact UI.
- `../../docs/live-plasma-smoke.md` — live Plasma keyboard and theme smoke.
- `../../metadata.json` — applet identity and Plasma package metadata.
- `../../contents/ui/` — existing native QML patterns.
- `../../ROADMAP.md` — backlog including visual regression work.
