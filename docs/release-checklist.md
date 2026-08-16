# Release checklist

Use before tagging or announcing a release of **KodexBar Plasma** (`org.kde.plasma.kodexbar.plasma`).

## Version and metadata

- [ ] `metadata.json` → `KPlugin.Version` bumped as intended
- [ ] README install/package ID section still points at the **current** package only
- [ ] LICENSE and provenance notes unchanged unless intentionally updated

## Automated gates

- [ ] `./scripts/run-qml-tests.sh` exit 0
- [ ] `./scripts/lint-qml.sh` exit 0
- [ ] `./scripts/validate-package.sh` exit 0
- [ ] `python3 scripts/check-provider-icons.py` exit 0
- [ ] `git diff --check` clean on the release commit
- [ ] Optional: `./scripts/run-visual-tests.sh` via CI Docker image (see [visual-regression.md](visual-regression.md))

## Live Plasma (required for UI-facing releases)

- [ ] Install/update current package: `kpackagetool6 -t Plasma/Applet -u .`
- [ ] `plasmawindowed org.kde.plasma.kodexbar.plasma` reaches Ready with real CLI data
- [ ] [live-plasma-smoke.md](live-plasma-smoke.md) — keyboard, Refresh, errors, provider tabs
- [ ] [ui-parity-checklist.md](ui-parity-checklist.md) — if popup/layout changed this cycle
- [ ] Breeze Light and Breeze Dark spot-check

## Boundaries (must still hold)

- [ ] Exact `usage --provider all --format json --json-only` unchanged (unless this release’s SDD changed it)
- [ ] Cost remains CLI-reported local estimate only; no QML pricing
- [ ] No Auth / Add Account / Quit / reset redeem in the widget
- [ ] Email only in selected-provider header; org only when human-readable

## Package ID transition

| ID | Role |
|---|---|
| `org.kde.plasma.kodexbar.plasma` | **Ship this** |
| `org.kde.plasma.kodexbar` | Legacy coexistence only — do not auto-migrate or delete user instances |

- [ ] Release notes tell users to install/update the **current** ID
- [ ] No script removes the legacy package as part of this release
- [ ] Sunset of legacy ID remains a **future, announced** decision (see [ROADMAP.md](../ROADMAP.md)) — not silent removal

## Artifacts

- [ ] Tag / GitHub release (if used) points at the correct commit
- [ ] Screenshot or short note updated if the popup changed materially (`screenshot.png` / README)

## Sign-off

| Field | Value |
|---|---|
| Version | |
| Date | |
| Gates | pass / fail |
| Live smoke | pass / fail |
| Notes | |
