# Design: Persistent DataSource Lifecycle Closeout

## Technical Approach

Produce an evidence-only closeout for the product baseline ending at `dca2671`. Verification binds each evidence class to its own authority: Git identity, current offscreen tests, native incremental review, user-provided live observation, and the immutable historical FAIL. No production, test, documentation, configuration, review-authority, or original lifecycle artifact is changed.

## Architecture Decisions

| Option | Tradeoff | Decision and rationale |
|---|---|---|
| Isolated baseline evidence run | Requires a clean checkout/worktree | Run evidence from repository root at exact `HEAD=dca2671` and tree `7b612c708717037a8d02654902a5fcb1b3c3fd32`; reject staged, unstaged, or untracked state. The authoring worktree currently contains untracked closeout artifacts, and `git diff --check` does not detect them. |
| Incremental receipt only | Cannot approve the historical candidate | Read native status plus `review-receipt.json`/`review-state.json`; accept `review-bf49b254cb6fa962` only when authoritative and approved for snapshot `sha256:bf49b254cb6fa9623c450514ed71b949550b90ee772b5cbc75c1bcfe2f8af518` and the four paths in `d027c1e..dca2671`. |
| Manual evidence as provenance | Does not provide automated host coverage | Attach the `apply-progress.md` real-provider `plasmawindowed` observation (populated rows and compact `100%`) as user-provided corroboration. Do not invent observer, timestamp, command execution, or verifier ownership. |
| Immutable historical verdict | Leaves the original change blocked | Cite `persistent-datasource-lifecycle/verify-report.md` as FAIL (0/4 requirements, 10/14 scenarios) and guard its exact bytes/hash; later evidence cannot supersede it. |

## Evidence Flow

```text
d027c1e → dca2671/tree → clean baseline gates → test/diff evidence
          receipt ─────→ scoped review evidence ─┐
          manual record → manual provenance ─────┼→ closeout verify report
          original FAIL → immutable citation ────┘
```

Procedure:
1. Resolve the repository root; prove `d027c1e` is an ancestor of `dca2671`, `HEAD` is `dca2671`, and the evidence checkout is clean.
2. Record `git diff --name-status d027c1e..dca2671`; require exactly the four receipt paths.
3. Read native review authority and receipt state; require approved status, exact snapshot, trees, and paths.
4. Run `./scripts/run-qml-tests.sh`; require exit 0, exactly 8/12/7 QtTest passes and 16 successful QML harnesses. Record output hash and retain offscreen `i18n` warnings without treating them as failures.
5. Run `git diff --check`; require exit 0 and record output hash. This is a whitespace gate, not a cleanliness check.
6. Attach the manual observation with source path and limitations; hash the original FAIL before and after closeout work.
7. Archive only after every gate passes.

## File Changes

| File | Action | Description |
|---|---|---|
| `openspec/changes/persistent-datasource-lifecycle-closeout/design.md` | Create | This bounded procedure. |
| `openspec/changes/persistent-datasource-lifecycle-closeout/tasks.md` | Create later | Evidence collection and negative gates only. |
| `openspec/changes/persistent-datasource-lifecycle-closeout/verify-report.md` | Create later | Fresh, hash-bound closeout verdict. |
| `openspec/changes/archive/YYYY-MM-DD-persistent-datasource-lifecycle-closeout/` | Move later | Archive only this closeout folder. |

All production, test, script, documentation, configuration, receipt, and `persistent-datasource-lifecycle/` paths are read-only.

## Interfaces / Contracts

The verification record must include baseline commit/tree and cleanliness; command, exit, counts, and output hashes; receipt ID/status/snapshot/trees/four paths; manual source and provenance limitation; original FAIL path/hash/verdict/counts; and `archive_eligible: true|false`. Missing or mismatched fields force `false`.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Evidence gates | Identity, clean state, receipt scope, counts, hashes | RED cases mutate one expected value at a time and must deny eligibility; then run against fresh evidence. |
| Integration | Current QML suite and whitespace gate | Run the fixed commands from the proven root; capture complete outputs. |
| Manual | Live Plasma provenance | Read only the user-provided record; never label it automated or current host acceptance. |

## Threat Matrix

| Boundary | Applicability | Safe/failure behavior | Planned RED tests |
|---|---|---|---|
| Documentation-like paths | N/A — no executable classification is added | Closeout files are data only | None |
| Git repository selection | Applicable | Exact resolved root succeeds; `git -C`, relative, or absolute selection resolving elsewhere fails closed | Wrong-root cases must deny archive |
| Commit state | Applicable | Exact commit/tree with empty porcelain succeeds; staged, unstaged, untracked, or alternate commit state fails closed; no commit command is allowed | One dirty-state case per class plus wrong HEAD/tree |
| Push state | N/A — no push occurs | No-op | None |
| PR commands | N/A — no PR command occurs | No-op | None |

## Migration / Rollout

No migration required. Rollback deletes/reverts only closeout artifacts. Any stale evidence—changed HEAD/tree, dirty checkout, changed runner/output/counts, non-approved or changed receipt, altered original FAIL bytes, or manual evidence lacking its source/limitations—causes a no-op: preserve records, report ineligible, and do not archive. Manual evidence remains historical corroboration and cannot become fresh automated acceptance.

## Open Questions

None.
