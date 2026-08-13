# Tasks: Persistent DataSource Lifecycle Closeout

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | 90–140 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single evidence-only PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Produce hash-bound closeout evidence | Single PR | `./scripts/run-qml-tests.sh && git diff --check` | 16 offscreen QML harnesses via runner; live Plasma is read-only user evidence | Closeout `verify-report.md` and archived closeout folder only |

## Phase 1: Negative Evidence Gates

- [x] 1.1 In `verify-report.md`, RED-check an incorrect resolved repository root and record `archive_eligible: false`; do not invoke `git -C` against another repository.
- [x] 1.2 RED-check wrong `HEAD`/tree and each staged, unstaged, and untracked porcelain state; each must deny archive without a commit command.
- [x] 1.3 RED-check missing or mismatched test counts, diff result, receipt fields, manual provenance, or original-FAIL hash; record each as ineligible.

## Phase 2: Fresh Evidence Reconciliation

- [x] 2.1 Create `verify-report.md` from a clean checkout at `HEAD=dca2671`, proving `d027c1e` ancestry, tree `7b612c708717037a8d02654902a5fcb1b3c3fd32`, and exact four-path range diff.
- [x] 2.2 Run `./scripts/run-qml-tests.sh`; record exit 0, output hash, 8/12/7 QtTest passes, 16 harnesses, and non-failing offscreen `i18n` warnings.
- [x] 2.3 Run `git diff --check`; record exit 0 and output hash, explicitly distinguishing whitespace validation from cleanliness.

## Phase 3: Scope and Preservation

- [x] 3.1 Record native receipt `review-bf49b254cb6fa962`, its exact snapshot and approved four-path `d027c1e..dca2671` scope; state it does not approve the original candidate.
- [x] 3.2 Cite `apply-progress.md` as user-provided real-provider `plasmawindowed` evidence (populated rows, compact `100%`); preserve unknown observer/time/execution ownership and no host-acceptance claim.
- [x] 3.3 Hash `persistent-datasource-lifecycle/verify-report.md` before and after; assert unchanged admitted `FAIL`, 0/4 requirements, 10/14 scenarios, active and blocked.

## Phase 4: Closeout Archive

- [x] 4.1 Set `archive_eligible: true` only when all fresh gates pass; otherwise preserve evidence and set it false without changing source, receipts, or original artifacts.
- [x] 4.2 Confirm archive readiness only: `verify-report.md` records `archive_eligible: true`; the actual move to `openspec/changes/archive/YYYY-MM-DD-persistent-datasource-lifecycle-closeout/` is performed by the archive phase, with rollback limited to that closeout artifact move.
