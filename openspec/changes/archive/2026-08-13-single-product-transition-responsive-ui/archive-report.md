# Archive Report: Single-Product Transition and Responsive UI

## Outcome

The completed hybrid SDD change was archived on 2026-08-13. The `provider-usage-display` delta was merged into the main specification before the change folder was moved.

## Final Verification

- Native runtime attempt: generation 11; terminal receipt passed.
- Evidence revision: `sha256:f5247a7b1bf09a965752b425ce668c356326216f83a1c6ee3da2b593b624af11`.
- Strict TDD runner: `./scripts/run-qml-tests.sh` passed; 44 QtTest cases and 19 QML harnesses passed.
- `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, `git diff --check`, and structural/scope checks passed.
- No CMake/CTest/build directory was used or included in the final evidence.
- Tasks: 9/9 complete, including task 4.2 for confirmed current-product dark-session narrow/wide live evidence.

## Explicit Boundaries and Warnings

Breeze Light and independent legacy/current installed-instance checks were not observed and remain non-blocking follow-ups; they are not claimed as evidence or blockers. Existing qmllint diagnostics, one implementation-coupled harness assertion, and stale apply-progress line-count metadata (111 versus 219 actual authored lines) remain warnings. The scoped implementation includes tested width propagation in `ProviderRow.qml` and `main.qml`.

No product source, installed package, panel configuration, or unrelated backlog was modified during verification.

## Specs Synced

- `openspec/specs/provider-usage-display/spec.md` — appended the three added requirements and seven scenarios from the delta.

## Archive Contents

- `exploration.md`
- `proposal.md`
- `specs/provider-usage-display/spec.md`
- `design.md`
- `tasks.md`
- `apply-progress.md`
- `verify-report.md`

## Traceability

Engram artifact observations read:

- `#4886` — exploration
- `#4893` — proposal
- `#4900` — spec
- `#4906` — design
- `#4909` — tasks
- `#4935` — apply-progress
- `#4946` — verify-report

Native review receipt gate: no structured `reviewGate` was present; the supplied terminal receipt and final verification facts were used.

## Mechanical Readback

Spec sync diff output was empty:

```text
SPEC_SYNC_DIFF_START
SPEC_SYNC_DIFF_END
```

Pre-move snapshot versus archived change folder diff output was empty:

```text
ARCHIVE_DIFF_START
ARCHIVE_DIFF_END
```
