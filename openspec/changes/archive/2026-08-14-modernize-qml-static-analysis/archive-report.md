# Archive Report: modernize-qml-static-analysis

## Final State

- Status: archived; native verification generation 4 passed.
- Evidence revision: `sha256:dba01a21affd2bcf385d26678e231aeddd799d10eba13d8256b4c9208cb27423`.
- Tasks: 13/13 complete. Requirements: 6/6 passed. Scenarios: 12/12 passed.
- `./scripts/lint-qml.sh`: passed; 56 exact KDE `i18n`/`i18np` warnings accepted by the semantic baseline.
- Behavioral runner: passed 44 QtTest cases and 19 QML harnesses.
- Focused checker: 10/10 passed. Bound structural tests: 3/3 passed. `git diff --check`: passed.

## Delivery Shape and Scope

- Three stacked slices were delivered, each under 400 lines: semantic gate/tests, Bound QML modernization, and guidance/final verification.
- No CMake, provider/CLI/package/icon changes were made, and no archived responsive changes were included.
- Breeze Light and independent legacy/current follow-ups remain non-blocking and unobserved; they are not claimed as verification evidence.

## Existing Warnings

- One source-coupled assertion remains.
- Two inline RED checks remain.
- These warnings are non-blocking; no CRITICAL findings or blockers remain.

## Archive Integrity

- The main specification was synced before archival.
- Archived tasks contain no unchecked implementation tasks.
- The archived change directory is `openspec/changes/archive/2026-08-14-modernize-qml-static-analysis/`.

## SDD Cycle Complete

The hybrid SDD change is fully implemented, verified, and archived. The main QML static-analysis specification is the source of truth.
