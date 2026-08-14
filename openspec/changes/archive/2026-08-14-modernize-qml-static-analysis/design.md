# Design: Modernize QML Static Analysis

## Technical Approach

`./scripts/lint-qml.sh` is the authoritative static-analysis gate; `./scripts/run-qml-tests.sh` is the authoritative behavioral/QML runner. Verification requires both plus `git diff --check`. Lint recursively covers `contents/ui`, fail-closed validates Qt 6 `qmllint` JSON, and accepts only exact `i18n`/`i18np` unqualified spans as the visible Plasma baseline. Runtime and established boundaries remain unchanged.

## Architecture Decisions

| Option | Tradeoff | Decision and rationale |
|---|---|---|
| Root qmlls configuration | Defaults cannot fit every distro | Use only documented `no-cmake-calls` and `importPaths`; keep host defaults overridable for Qt 6 KDE installations. |
| Count or global suppression | Either misclassifies or hides defects | Keep strict categories as errors and `UnqualifiedAccess` visible; nested-schema and span validation decides acceptance. |
| Non-recursive globs | Miss future directory depths | Standard-library Python recursively enumerates, normalizes, and lexically sorts `contents/ui/**/*.qml`. |
| Translation rewrite | Changes extraction/runtime semantics | Reject; preserve KDE names, arguments, strings, and callback shapes. |

## Data Flow

    editor -> .qmlls.ini -> host default or editor/environment import override
    lint-qml.sh -> portable lookup -> sorted contents/ui/**/*.qml -> qmllint JSON
                                                              -> checker -> pass/fail
    run-qml-tests.sh -> QtTest + qml6 harnesses -> unchanged UI/CLI behavior

## File Changes

| File | Action | Description |
|---|---|---|
| `.qmlls.ini`, `.qmllint.ini` | Create | Non-CMake editor settings and explicit lint levels. |
| `scripts/lint-qml.sh` | Modify | Resolve portable overrides and invoke the recursive gate. |
| `scripts/check-qml-unqualified-baseline.py` | Create | Enumerate, invoke `qmllint` with direct argv, and validate JSON/source spans. |
| `tests/test_qml_unqualified_baseline.py` | Create | RED/GREEN contract and scope fixtures. |
| `contents/ui/main.qml`, `contents/ui/ProviderSelector.qml`, `contents/ui/ProviderRow.qml`, `contents/ui/UsageWindowRow.qml`, `contents/ui/ErrorSummary.qml` | Modify | Bind components, qualify access, and declare delegate inputs as diagnosed. |
| `README.md` | Modify | Document setup, scope, baseline, and verification. |

Scope includes the seven `contents/ui/*.qml` files, `contents/ui/config/configGeneral.qml`, and future nested UI QML. `contents/config/config.qml` stays excluded. Edit only diagnosed files; the final UI tree has zero fixable structural warnings.

## Interfaces / Contracts

```ini
# .qmlls.ini
[General]
no-cmake-calls=true
importPaths=/usr/lib/qt6/qml
```

`.qmllint.ini` keeps the seven existing strict categories as errors, `UnqualifiedAccess=warning`, and `MaxWarnings=-1`; semantic validation, not warning count, is the gate.

Resolve `qmllint` through executable `QMLLINT_BIN`, `PATH`, `qtpaths6`, then known `/usr/lib{,64}/qt6/bin` locations. Imports accept `QML_IMPORT_ROOT` (`-I`) and `QML_IMPORT_PATH` (`-E`), then `qtpaths6` and known distro roots. Invalid explicit overrides fail clearly.

Qt 6.11.1 emits root `{revision, files}`; files require `{filename, warnings, success}`; warnings require `{id, line, column, charOffset, length}`. Require `revision` and numeric locations to be integers excluding booleans, `files`/`warnings` arrays, string identifiers/filenames, boolean `success`, non-negative offsets/lengths, and positive line/column. Extra fields are allowed; missing, malformed, or changed structure fails.

Resolve absolute filenames directly and relative ones from repository root, then canonicalize. Records must map one-to-one to every enumerated readable UTF-8 target inside `contents/ui`; duplicates, omissions, extras, escapes, or unreadable files fail. Slice source by Qt UTF-16 `charOffset`/`length`, rejecting invalid ranges/surrogate splits, and cross-check the 1-based line/column start. Accept only `id == "unqualified"` with span exactly `i18n` or `i18np`; all other diagnostics fail. Nonzero process exit fails. Warning-bearing files may have `success:false`; allow it only when execution succeeds and all warnings are accepted.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit RED/GREEN | JSON/baseline contract | Accept exact nested-token fixtures; reject flat/malformed schema, bad paths, UTF-16/location mismatch, `root`, and `index`. |
| Integration RED/GREEN | Gate and scope | Prove overrides, recursive root/`ui/config`/deeper inclusion, `contents/config/config.qml` exclusion, nonzero-tool failure, and visible diagnostics. |
| Regression | Both authorities | Run lint, QML tests, translation inventory, and `git diff --check`; retain exact CLI argv assertions. |

## Threat Matrix

| Boundary | Minimum adversarial cases | Applicability | Design response | Planned RED tests |
|---|---|---|---|---|
| Documentation-like paths | `requirements.txt`, `CMakeLists.txt`, executable Markdown/MDX, `README.sh` | N/A: enumeration selects `.qml` data for `qmllint`; it does not classify executables | None | None |
| Git repository selection | `git -C`, relative paths, absolute paths | N/A: no Git invocation | None | None |
| Commit state | staged, `commit -a`, empty index | N/A: no commit automation | None | None |
| Push state | tracking branch, first push, explicit refspec | N/A: no push automation | None | None |
| PR commands | explicit `--head`, environment prefix, composed commands | N/A: no PR automation | None | None |

## Migration / Rollout

No migration required. Land checker and scope RED tests first, then QML slices and both authoritative gates. Forecast remains below 400 changed lines; tasks must recalculate and stop under `ask-on-risk` if the complete change-owned diff may exceed it.

## Open Questions

None.
