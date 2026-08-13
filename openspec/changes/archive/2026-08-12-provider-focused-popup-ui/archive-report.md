# Archive Report: provider-focused-popup-ui

## Final Status

- Change: `provider-focused-popup-ui`
- Artifact mode: Hybrid (OpenSpec + Engram)
- Archived to: `openspec/changes/archive/2026-08-12-provider-focused-popup-ui/`
- Archive date: 2026-08-12
- Review: not applicable; native receipt reported `applicability: unrelated` and no applicable `reviewGate`.
- Result: PASS WITH WARNINGS; intentional warnings are non-blocking.

## Final Evidence

- Requirements: 5/5; scenarios: 12/12; tasks: 11/11.
- `./scripts/run-qml-tests.sh`: exit 0.
- `git diff --check`: exit 0, empty output.
- No BLOCKER or CRITICAL findings.
- User-confirmed Plasma smoke: package update succeeded; `plasmawindowed org.kde.plasma.kodexbar.plasma` launched; selector navigation, first-provider/All/detail presentation, readable layout, and sanitized error summary were observed.
- ErrorSummary raw diagnostics were sanitized after smoke; focused and full tests passed afterward.

## Warnings

- Breeze Light/Dark switching and exact manual refresh reorder/disappearance were not independently observed.
- Known non-failing offscreen `i18n`/`i18np` warnings remain.
- The later compact-All/provider-bar refinement is explicitly future follow-up and is not part of this archived change.

## Specs Synced

Updated `openspec/specs/provider-usage-display/spec.md` by merging the provider-focused delta while preserving unrelated requirements. The delta introduced provider-focused selection/presentation, sanitized mixed failures, accessibility/narrow-layout behavior, exclusions, and preserved runtime boundaries.

## Mechanical Readbacks

```text
--- spec copy diff (verbatim; empty means identical) ---

--- archive move diff (verbatim; empty means identical) ---
```

Both `diff -r` readbacks were empty.

## Engram Traceability

Read artifact observations: proposal `#4500`, spec `#4505`, design `#4506`, tasks `#4509`, apply-progress `#4516`, verify-report `#4568`.
