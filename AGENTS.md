# Project Instructions

## Skills

- Load `skills/plasma-kirigami-ui/SKILL.md` before creating or changing Plasma 6 QML/Kirigami UI.
- Consult `.atl/skill-registry.md` for available repository skills.

## Architecture & Stack

- **Target platform:** KDE Plasma 6 applet (`org.kde.plasma.kodexbar.plasma`).
- **UI layer:** QML / Kirigami views and controllers under `contents/ui/` and `contents/ui/config/`, using `pragma ComponentBehavior: Bound` and native `Kirigami.Units` / `Kirigami.Theme` tokens.
- **Domain helpers:** Stateless ECMAScript Modules under `contents/code/*.mjs` using standard `export var` / `export function` syntax, imported from QML as `import "../code/<Name>.mjs" as <Name>`. Do not use Qt-proprietary `.pragma library` or `.import` directives.
- **CLI boundary:** Usage and cost data come strictly from the external `codexbar` CLI and the Python 3 standard-library NaN Cloud adapter at `scripts/codexbar-nan`; never reimplement provider auth, fetching, or token pricing in QML.
- **Canonical docs:** `docs/product.md` (product scope and settings), `docs/design.md` (architecture, data flow, and Plasma UI system), and `docs/ui-parity-checklist.md` (visual/accessibility gate).

## Verification Commands

- `./scripts/validate-package.sh` — Validate `metadata.json` and isolated `kpackagetool6` install.
- `python3 scripts/check-provider-icons.py` — Verify SVG icon coverage, XML validity, distinctness, and banned-color rules.
- `./scripts/lint-qml.sh` — Enforce `qmllint` and `scripts/check-qml-unqualified-baseline.py`.
- `./scripts/run-qml-tests.sh` — Run QtTest suites, offscreen QML harnesses, and Python unittest discovery.
- `python3 -m unittest discover -s tests -p "test_*.py"` — Run standalone Python test suites directly.
- `./install.sh` — Install `codexbar-nan` and update/install the Plasma applet locally.

## Critical Invariants

- Keep line `151` (`width: root.width`) of `contents/ui/UsageWindowRow.qml` aligned with `LAYOUT_POSITIONING_EXCEPTIONS` in `scripts/check-qml-unqualified-baseline.py` (or update the exception intentionally if that binding moves).
- Preserve the locked comma-decimal and dot-thousands number formatting contract in `contents/ui/CostSection.qml` (`formatUsd`, `formatTokensAbbreviated`), asserted by `tests/ProviderRowHarness.qml` and visual goldens.
- Strip `accountEmail` and `accountOrganization` before persisting snapshots in `contents/code/SnapshotStorage.mjs`, and keep raw identity PII off primary UI chrome (`contents/code/ProviderDetails.mjs`, `contents/ui/ProviderHeader.qml`).
- Route user-facing strings through `contents/code/Translation.mjs` with `languagePreference`, and keep Spanish translations in `contents/code/SpanishDictionary.mjs` complete and deduplicated.

## External Knowledge & Vault Triggers

- Before changing provider CLI integration, `codexbar` / `agy` discovery, or the `scripts/codexbar-nan` adapter, read `01-Conocimiento/Tecnologías/Herramientas/KodexBar.md` via Obsidian MCP. If Obsidian MCP is unavailable, rely on `docs/product.md`, `docs/design.md`, and explicit user context without inventing configuration values.
- Before visual refinement or evolving `docs/design.md`, read `01-Conocimiento/Tecnologías/Herramientas/Adoptar el flujo de diseño en un proyecto avanzado.md` via Obsidian MCP, keeping `skills/plasma-kirigami-ui/SKILL.md` as the implementation authority (never web or CSS tokens).
- For non-trivial architectural uncertainty, optionally consult Gentleman Book MCP as a recommendation contrasted against repository conventions and official Qt 6 / KDE Plasma 6 documentation.
