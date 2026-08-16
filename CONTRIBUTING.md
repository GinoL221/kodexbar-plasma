# Contributing

Practical rules for this repository. Product scope and backlog live in [ROADMAP.md](ROADMAP.md).

## Product boundary

- The external **CodexBar CLI** owns providers, credentials, auth, and data acquisition.
- This plasmoid shells out with exact contracts (`usage --provider all --format json --json-only`, and selected-provider `cost …` when applicable).
- Do not add Auth, Add Account, Quit, reset-credit redeem, or QML price calculation.

## When to use SDD

Use the OpenSpec / Engram SDD cycle when the change touches:

- CLI contract or subprocess lifecycle
- PII / identity display rules
- Substantial behavior (roughly >150 authored lines of product logic)

Use a **direct PR** for docs, skills, chores, runner tweaks, and small fixes.

## Delivery

- Prefer **stacked-to-main** when a change exceeds the ~400 authored-line review budget.
- Ask before oversized single PRs (`ask-on-risk`).
- Do not push or open PRs without explicit maintainer authorization in agent sessions.
- One branch owner at a time; avoid two agents applying the same branch.

## Required local gates

From the repository root, before review:

```sh
./scripts/run-qml-tests.sh
./scripts/lint-qml.sh
./scripts/validate-package.sh
git diff --check
```

When icons or `ProviderIcons.js` change:

```sh
python3 scripts/check-provider-icons.py
```

When popup layout or polish changes:

- [docs/ui-parity-checklist.md](docs/ui-parity-checklist.md)
- Relevant sections of [docs/live-plasma-smoke.md](docs/live-plasma-smoke.md) (real desktop, Breeze Light/Dark)

When touching visual goldens:

- [docs/visual-regression.md](docs/visual-regression.md) — prefer regenerating goldens **inside** the CI Docker image

## UI craft

Load `skills/plasma-kirigami-ui/SKILL.md` before editing QML. Use Plasma/Kirigami/Breeze primitives only; CodexBar screenshots are information-architecture references, not a skin to clone.

## Tests

- Behavioral authority: `./scripts/run-qml-tests.sh` (auto-discovers plain `tests/*Harness.qml`).
- Visual (supplemental): `./scripts/run-visual-tests.sh` or the Docker flow in `docs/visual-regression.md`.
- Live Plasma remains manual; offscreen suites do not certify `PlasmoidItem` / panel integration.

## PR checklist

The GitHub PR template mirrors the gates above. Fill it honestly; do not claim live Plasma coverage from offscreen-only runs.
