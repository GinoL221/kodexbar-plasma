# Roadmap

Short post-parity backlog. Product behavior for usage, selected-provider enrichment, and local cost is shipped; this list is hygiene, craft, and test infrastructure.

## Done (recent)

- All-provider usage lifecycle and compact/popup UI
- Provider icons theme-adaptive gate
- Selected-provider enrichment (pace, credits, reset inventory, identity header)
- Isolated `codexbar cost` lifecycle and Cost section
- SDD archive for `final-popup-parity`
- P0 hygiene (zombie SDD archive, PR template, ROADMAP links)
- P0b UI craft skill + `docs/ui-parity-checklist.md`
- P1 offscreen visual regression + deterministic Breeze Light/Dark inject
- P1b `run-qml-tests.sh` auto-discovers plain `*Harness.qml`

## Next

| Priority | Item | Notes |
|---|---|---|
| P2 | Process notes | SDD vs chore rules already in ROADMAP/PR template; expand only if needed |
| P3 | Deferred product | Legacy package ID sunset date; release checklist; optional self-hosted QML CI |
| Later | Split oversized harnesses | e.g. `ProviderRowHarness.qml` when next touched |

## Explicit non-goals

- Web design tooling as UI authority (OpenPencil / Impeccable-style stacks)
- Auth, Add Account, Quit, or redeeming reset credits inside the plasmoid
- Computing token prices in QML
- Full `plasmawindowed` screenshot CI on GitHub-hosted runners

## How to work items

- **SDD** for CLI contract, lifecycle, PII display rules, or substantial behavior
- **Direct PR** for docs, skills, chore, and small runner changes
- **stacked-to-main** when a change exceeds the ~400 authored-line review budget
