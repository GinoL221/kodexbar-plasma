# Roadmap

Short post-parity backlog. Product behavior for usage, selected-provider enrichment, and local cost is shipped; this list is hygiene, craft, and test infrastructure.

## Done (recent)

- All-provider usage lifecycle and compact/popup UI
- Provider icons theme-adaptive gate
- Selected-provider enrichment (pace, credits, reset inventory, identity header)
- Isolated `codexbar cost` lifecycle and Cost section
- SDD archive for `final-popup-parity`

## Next

| Priority | Item | Notes |
|---|---|---|
| P0 | Repo hygiene | Zombie SDD cleanup, PR template, doc links |
| P0b | UI craft skill + checklist | `skills/plasma-kirigami-ui`, `docs/ui-parity-checklist.md` |
| P1 | Offscreen visual regression | Change `qml-visual-regression`: geometry asserts, few goldens, no sudo |
| P1b | Test runner maintainability | Auto-discover harnesses; split oversized harnesses when touched |
| P2 | Process notes | SDD vs chore rules (see skill/checklist and PR template) |
| P3 | Deferred product | Legacy package ID sunset date; release checklist; optional self-hosted QML CI |

## Explicit non-goals

- Web design tooling as UI authority (OpenPencil / Impeccable-style stacks)
- Auth, Add Account, Quit, or redeeming reset credits inside the plasmoid
- Computing token prices in QML
- Full `plasmawindowed` screenshot CI on GitHub-hosted runners

## How to work items

- **SDD** for CLI contract, lifecycle, PII display rules, or substantial behavior
- **Direct PR** for docs, skills, chore, and small runner changes
- **stacked-to-main** when a change exceeds the ~400 authored-line review budget
