# Roadmap

Short post-parity backlog. Product behavior for usage, selected-provider enrichment, and local cost is shipped; remaining work is ops and deferred product decisions.

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
- P2 process notes → [CONTRIBUTING.md](CONTRIBUTING.md)
- P3 release checklist → [docs/release-checklist.md](docs/release-checklist.md)

## Next / deferred

| Item | Notes |
|---|---|
| Legacy package sunset | `org.kde.plasma.kodexbar` may coexist indefinitely. **Do not auto-remove.** When ready: announce date, document manual migrate (install current ID, copy settings, remove old widget), then stop shipping legacy. No target date yet. |
| Self-hosted QML CI | Only if local `./scripts/run-qml-tests.sh` is skipped often enough to hurt |
| Split oversized harnesses | e.g. `ProviderRowHarness.qml` when next touched |
| Harden visual CI | Goldens are Docker-authoritative; optional blocking later if flakes stay near zero |

## Explicit non-goals

- Web design tooling as UI authority (OpenPencil / Impeccable-style stacks)
- Auth, Add Account, Quit, or redeeming reset credits inside the plasmoid
- Computing token prices in QML
- Full `plasmawindowed` screenshot CI on GitHub-hosted runners

## How to work items

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full contributor rules. Summary:

- **SDD** for CLI contract, lifecycle, PII display rules, or substantial behavior
- **Direct PR** for docs, skills, chore, and small runner changes
- **stacked-to-main** when a change exceeds the ~400 authored-line review budget
