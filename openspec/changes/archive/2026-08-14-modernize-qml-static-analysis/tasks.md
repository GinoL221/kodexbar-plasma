# Tasks: Modernize QML Static Analysis

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | 650–950 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 gate/tests → PR 2 QML → PR 3 docs/verification |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Semantic gate | PR 1 | `python3 -m unittest tests/test_qml_unqualified_baseline.py` | `./scripts/lint-qml.sh` | configs, checker, Python tests, lint script |
| 2 | Bound QML | PR 2 | `./scripts/run-qml-tests.sh` | Provider/compact/ErrorSummary harnesses | five listed UI files |
| 3 | Guidance and proof | PR 3 | `git diff --check` | `./scripts/run-qml-tests.sh` | README only |

## Phase 1: Policy and RED Contract

- [x] 1.1 RED: add `tests/test_qml_unqualified_baseline.py` fixtures asserting exact nested Qt JSON acceptance for only `unqualified` spans `i18n`/`i18np`; reject `root`, `index`, malformed schema, nonzero tool exit, and any other diagnostic.
- [x] 1.2 RED: test recursive sorted `contents/ui/**/*.qml` enumeration includes `contents/ui/config/configGeneral.qml` and nested fixtures, excludes `contents/config/config.qml`, and rejects duplicate, missing, escaping, unreadable, or non-UTF-8 records.
- [x] 1.3 RED: test UTF-16 offsets/lengths, surrogate splits, and 1-based line/column cross-checks fail closed; test invalid `QMLLINT_BIN`, `QML_IMPORT_ROOT`, and `QML_IMPORT_PATH` overrides.
- [x] 1.4 Add `.qmlls.ini` (non-CMake/import-path settings) and `.qmllint.ini` (seven strict errors, visible `UnqualifiedAccess=warning`, unlimited count), documenting portable environment overrides without Qt 6.11-only assumptions.

## Phase 2: Semantic Static-Analysis Gate

- [x] 2.1 GREEN: create `scripts/check-qml-unqualified-baseline.py`; resolve executable/import overrides, enumerate normalized lexical targets, invoke `qmllint` with direct argv/JSON, and fail closed on process, schema, mapping, source-span, or unaccepted-warning failure.
- [x] 2.2 GREEN: change `scripts/lint-qml.sh` to invoke the checker; retain deterministic portable lookup and make it the static authority, separate from `./scripts/run-qml-tests.sh` behavioral authority.
- [x] 2.3 REFACTOR: run `python3 -m unittest tests/test_qml_unqualified_baseline.py` and `./scripts/lint-qml.sh`; retain fixtures proving visible accepted diagnostics never become a warning-count bypass.

## Phase 3: Bound QML Modernization

- [x] 3.1 RED: extend existing QML harnesses for affected delegates before edits, proving provider selection, compact rendering, rows, and failure disclosure retain behavior and exact CLI argv.
- [x] 3.2 GREEN: update `contents/ui/main.qml`, `ProviderSelector.qml`, and `ProviderRow.qml` with bound components, required `index`/roles, and qualified outer access; preserve literal KDE translation function names and argument shapes.
- [x] 3.3 GREEN: update `contents/ui/UsageWindowRow.qml` and `ErrorSummary.qml` with the same structural rules; run `./scripts/run-qml-tests.sh` and `./scripts/lint-qml.sh`.
- [x] 3.4 Inspect but do not edit `contents/ui/config/configGeneral.qml` unless lint reports a non-translation warning; never edit `contents/config/config.qml`.

## Phase 4: Guidance and Completion

- [x] 4.1 Update `README.md` with Qt 6/KDE editor setup, portable overrides, semantic baseline, scope exclusions, and both required commands; preserve package identities and CLI documentation.
- [x] 4.2 Complete `./scripts/lint-qml.sh`, `./scripts/run-qml-tests.sh`, and `git diff --check`; record accepted spans, zero fixable warnings, and unchanged translations/argv.
