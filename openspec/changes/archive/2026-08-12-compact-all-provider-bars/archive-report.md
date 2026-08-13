# Archive Report: compact-all-provider-bars

## Final Status

**PASS WITH WARNINGS**. The compact provider-bar change completed its planned implementation and bounded remediation, with the provider-usage display spec updated and the historical evidence archived.

| Field | Value |
|---|---|
| Change | `compact-all-provider-bars` |
| Archive date | 2026-08-12 |
| Artifact store | Hybrid (OpenSpec + Engram) |
| Archived path | `openspec/changes/archive/2026-08-12-compact-all-provider-bars/` |
| Requirements | 1/1 compliant |
| Scenarios | 7/7 compliant |
| Tasks | 14/14 complete |
| Critical findings | None |

## Artifact Store and Completeness

The archive contains the proposal, exploration, provider-usage-display delta spec, design, tasks, apply-progress mirror, and verify-report. The main `provider-usage-display` spec was updated with the representative-bar behavior, fallback ordering, identity-only behavior, non-expandable summaries, and preserved detail tabs.

OpenSpec had no apply-progress file at verification time. The local `apply-progress.md` is an archival mirror of the complete cumulative Engram artifact, not an invented test record.

## Verification References

- Full runner: `./scripts/run-qml-tests.sh` exited 0.
- Observed result: 35 QtTest cases plus 18 executable QML harness flows, 53 passing cases/flows.
- Focused harnesses: `UsageModelHarness.qml`, `ProviderRowHarness.qml`, and `MainCompactHarness.qml` each exited 0 under the recorded offscreen/software command.
- Static check: `git diff --check` exited 0 with empty output.
- Verify evidence revision: `sha256:f7cb08c22120d721dc943f89511965f01185ee555c4d5598c116c57e6411be45`.
- Test output hash: `sha256:8e01fd2e54cef8d51f49545b756d897a2248d0f025c9e08e4c363553c31f7b6c`.
- Build output hash: `sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.

## Known Limitations and Drift

- The design-to-artifact mismatch for `UsageModelHarness.qml` is non-blocking; selector coverage is present in `UsageModelTest.qml`.
- The design's runner-registration statement has historical documentation drift; runtime verification remained green.
- Live Breeze Light/Dark, real keyboard delivery, and narrow-layout checks were not independently executed in a real Plasma session.
- No QML coverage tool, linter, or type checker was configured.
- This report records historical verification, not current HEAD verification. Later commits, especially `d4a96b1`, are outside its evidence scope.
- No additional test command or hash is claimed beyond the recorded verify-report and cumulative apply-progress evidence.

## Archival Outcome

The change set is complete and coherent as a historical archive, with non-blocking documentation and environment warnings explicitly retained. No native archive command is claimed as having been run.
