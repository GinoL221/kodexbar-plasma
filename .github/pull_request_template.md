## Summary

<!-- What changed and why (1–3 sentences). -->

## Type

- [ ] Feature
- [ ] Fix
- [ ] Docs / skill / chore
- [ ] SDD change (link `openspec/changes/...` or archive path)

## Local gates (required before review)

Run from the repository root:

- [ ] `./scripts/run-qml-tests.sh`
- [ ] `./scripts/lint-qml.sh`
- [ ] `./scripts/validate-package.sh`
- [ ] `python3 scripts/check-provider-icons.py` (when icons or `ProviderIcons.js` change)
- [ ] `git diff --check`

## Live Plasma (when UI or theming changes)

- [ ] `docs/live-plasma-smoke.md` — relevant sections for this PR
- [ ] `docs/ui-parity-checklist.md` — when popup/layout/polish changes
- [ ] Breeze Light and Breeze Dark spot-check

## Boundaries

- [ ] Exact `usage --provider all --format json --json-only` unchanged (unless this PR's SDD explicitly changes it)
- [ ] No auth / Add Account / Quit / reset-credit redeem
- [ ] No QML price calculation; cost remains CLI-reported only
- [ ] No web-generic UI (HTML/CSS patterns, fixed brand glass, emoji icons)

## Review size

- Estimated authored changed lines: <!-- N -->
- [ ] Under 400, or chained / exception noted below

## Notes for reviewers

<!-- Risks, screenshots, fixture updates, golden updates, etc. -->
