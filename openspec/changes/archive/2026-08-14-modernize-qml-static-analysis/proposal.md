# Proposal: Modernize QML Static Analysis

## Intent

Make QML language-server and lint diagnostics actionable. The current `contents/ui` analysis mixes structural `unqualified` warnings with legitimate Plasma context-property warnings. Adopt Qt 6/KDE-compatible bound-component practices without changing runtime behavior or KDE translation extraction.

## Scope

### In Scope
- Add `.qmlls.ini` for the non-CMake package (`no-cmake-calls=true`, `/usr/lib/qt6/qml` import path).
- Add an explicit `.qmllint.ini` policy: existing structural diagnostics remain errors; `UnqualifiedAccess` remains visible as warnings, never globally disabled.
- Modernize `contents/ui`: `ComponentBehavior: Bound`, qualified outer access, and required delegate properties (including `index`).
- Keep `i18n`/`i18np` call shapes intact and document the intentional Plasma translation-warning baseline.
- Align `scripts/lint-qml.sh`, README guidance, and existing QML harness verification.

### Out of Scope
- `contents/config` (follow-up change), provider behavior, authentication/fetching, or the external `codexbar` CLI boundary and exact argv.
- Package identities, provider icon backlog, and archived `single-product-transition-responsive-ui` work.
- CMake/build integration, Qt-version-specific practices limited to Qt 6.11.1, and translation API substitution.

## User and Developer Value

Users retain provider results, localization, package behavior, and CLI integration. Developers get resolved imports, type-safe delegate context, a reviewable warning baseline, and actionable future lint failures.

## Capabilities

### New Capabilities
- None: this is tooling and structural modernization; no new runtime capability is introduced.

### Modified Capabilities
- None: existing runtime requirements remain unchanged.

## Approach

Use the narrow policy: bind affected QML documents, qualify outer accesses, and declare injected delegate properties explicitly. Preserve KDE translation calls. Keep `./scripts/run-qml-tests.sh` authoritative; run lint and tests after each structural slice.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `.qmlls.ini`, `.qmllint.ini` | New | Editor imports and explicit diagnostic policy |
| `contents/ui`, `scripts/lint-qml.sh` | Modified | Bound components, qualified access, required properties, lint target |
| `tests/`, `README.md` | Modified | Regression verification and documented baseline |

## Risks and Rollback

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Bound context breaks a delegate | Medium | Declare required properties and run the full QML suite |
| Translation extraction changes | Low | Preserve `i18n`/`i18np` shapes; verify baseline remains documented |
| Suppression hides regressions | Low | Keep `UnqualifiedAccess` visible and narrowly documented |

Rollback is a single revert of configuration, QML, script, test, and documentation changes; runtime data and package boundaries remain untouched.

## Success Criteria

- [ ] `contents/ui` has zero fixable structural warnings.
- [ ] Legitimate Plasma context-property warnings remain visible and documented as the baseline.
- [ ] `.qmlls.ini` resolves Qt/KDE imports without CMake assumptions.
- [ ] `./scripts/lint-qml.sh`, `./scripts/run-qml-tests.sh`, and `git diff --check` pass.
- [ ] The change remains within the 400-line review budget and preserves exact CLI argv and translation call shapes.
