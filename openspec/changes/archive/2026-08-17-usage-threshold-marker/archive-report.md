# Archive Report: Usage Threshold Marker

**Date**: 2026-08-17
**Change**: usage-threshold-marker
**Archive Location**: `openspec/changes/archive/2026-08-17-usage-threshold-marker/`
**Mode**: Hybrid (OpenSpec + Engram)

## Executive Summary

The `usage-threshold-marker` SDD change has been successfully completed, verified, and archived. All implementation tasks are complete (54/56 checked; 2 unchecked tasks explicitly marked as superseded by later design revisions and left permanently pending-not), all verification passes achieved with user approval, and the change's delta specification has been merged into the main `provider-usage-display` specification. The change folder has been moved to archive with full byte-identity verification.

## Change Scope

This change added a visual risk marker to usage window bars (both Overview summary and selected-provider detail modes) to alert users when usage approaches provider limits. The marker features:

- Pure JS classification logic (`UsageThreshold.js`) with fixed thresholds (ok <70%, warn 70–89.99%, critical >=90%)
- Bundled custom SVG icons (warning triangle for warn, critical circle for critical) with recolorable masks
- Row-sibling placement (not bar-overlay): after bar in Overview, after percent text in detail mode
- Reserved layout slot at fixed width to preserve bar track length equality across all rows
- Shared implementation between summary and detail modes to prevent divergence
- Accessible description enhancement with risk phrasing (Critical usage / Elevated usage)
- Three design revisions after live-user-feedback iterations (Revision 1: icon instead of dot; Revision 2: row-sibling placement; Revision 3: custom bundled SVGs + detail placement flip)

No CLI, controller, model, or data contract changes were made.

## Final State Authority

### Task Completion Status

**Source**: Persisted `openspec/changes/usage-threshold-marker/tasks.md`
**Result**: ✓ COMPLETE — 54/56 implementation tasks checked

All implementation phases completed and verified:
- Phase 1 (Harness Split): Move column-width/elide asserts ✓
- Phase 2 (Threshold Marker): JS classification + QML component + a11y + 2 harnesses + lint re-pin ✓
- Phase 3 (Visual + Docs): Fixture update + golden regeneration + checklist ✓
- Phase 4 (Icon Marker Revision, D19-D22): Symbol icon swap from circular dot ✓
- Phase 5 (Golden Re-regen, Round 1): Regenerated with icon marker (offscreen-harness limitation recorded) ✓
- Phase 6 (Row-Sibling Placement Revision, D23-D26): Moved marker from bar-overlay to row-sibling ✓
- Phase 7 (Golden Re-regen, Round 2): Verified reserved-slot invariant (bar width unchanged) ✓
- Phase 8 (Custom Icons + Detail Placement Flip, D27-D30): Bundled SVG icons + detail-mode after-percent ✓
- Phase 9 (Golden Re-regen, Round 3): Final regeneration with custom SVGs (offscreen-harness color-recolor limitation recorded) ✓

**Unchecked tasks** (2, explicitly marked superseded and left permanently pending-not):
- Task 5.1 (Revision 1's golden re-regen visual confirmation): Superseded by Revisions 2/3 before retry could run; its target no longer exists in production code
- Task 3.5b (Revision 1's manual gate): Superseded by Revision 2's row-sibling placement before gate could run; replaced by 3.5c and 3.5d

**Final manual gate** (3.5d, Phase 9): ✓ CHECKED — User confirmed "ahora si me gusta como quedo" (now I like how it turned out); custom icons + detail-mode placement + Overview centering all verified correct on live Plasma hardware-accelerated rendering.

### Verification Status

**Source**: `sdd-verify` run completed on current branch (visual-parity-polish/pr6-overview-and-icon-fix)
- **sdd-verify result**: PASS WITH WARNINGS
  - 0 CRITICAL issues
  - Only documentation-staleness warnings (docs/ui-parity-checklist.md and tasks.md — fixed in-cycle before archive)
  - All functional/spec/code coverage confirmed complete
  - All 3 test/lint/discovery commands exit 0

**Current Status**: All blockers resolved, CI-clean, fully verified. User explicitly requested closure ("dale, esto lo podemos cerrar aca entonces").

### Native Review Receipt Gate

No review was initiated for this candidate. The receipt-driven development kill switch remains off for this repository during this cycle. Archive proceeds under ordinary repository policy.

### Specification Changes

**Domain**: `provider-usage-display`
**File**: `openspec/specs/provider-usage-display/spec.md`

#### ADDED Requirements (1 new)
1. **Requirement: Usage window threshold risk marker** — Windows classify `usedPercent` into ok/warn/critical levels with bundled SVG icons (warning triangle / critical circle) at fixed width; marker sits after bar in Overview summary, after percent text in detail; tab underline bars excluded; bar fill remains threshold-independent; reserved slot keeps bar track length equal across all rows; accessible description gains risk phrasing

**Merge Action**: Delta spec merged into main spec at `openspec/specs/provider-usage-display/spec.md` (now 650 lines, +54 lines for 1 new requirement with 8 scenarios)

**Verification**: Edit to main spec appended complete requirement with all scenarios verbatim from delta spec

## Artifacts Archived

**Archive Path**: `openspec/changes/archive/2026-08-17-usage-threshold-marker/`

Archive contents (byte-verified with diff -r, empty diff confirms no truncation):
- `proposal.md` — Intent, scope, capabilities, approach, affected areas, risks, rollback plan, dependencies, success criteria
- `specs/provider-usage-display/spec.md` — Delta specification (1 ADDED requirement with 8 scenarios, pre-merge state)
- `design.md` — 30 architecture decisions (D1–D30) across 3 design revisions, plus detailed revision narratives and threat matrix
- `tasks.md` — 9 phases (harness split, marker, visual, revisions 1–3) with 54 checked + 2 superseded-unchecked tasks, review workload forecast, and strategy notes

## Change History

**Commits on this branch** (visual-parity-polish/pr6-overview-and-icon-fix):
- `0692c43` feat(ui): scannable overview bars, provider accents, and relative... (includes marker-relevant changes)
- `98b9bad` docs(sdd): archive visual-parity-polish change
- `a9dcdad` fix(ci): pin the layout-positioning lint exception to its exact line
- `8b06956` fix(ci): add a named lint exception for UsageWindowRow's titleRow width
- `5a23cd0` feat(ui): overview cards, custom tab strip, and detail chrome polish

**Verification Record**:
- `sdd-verify` run: 2026-08-17, PASS WITH WARNINGS (0 CRITICAL, only documentation-staleness fixed in-cycle)
- Manual live smoke: Multiple iterations (3.5, 3.5c, 3.5d), Breeze Light + Dark, user-approved at 3.5d
- Golden regeneration verified: 0/180000 mismatched pixels across all 4 scenarios, convergence confirmed
- Harness discovery: All 4 new/modified test files confirmed in repo's glob-based discovery

## Source of Truth Update

The main specification (`openspec/specs/provider-usage-display/spec.md`) now reflects the implemented behavior:
- Usage window threshold classification (ok/warn/critical levels)
- Bundled SVG icon marker rendering (threshold-warning.svg / threshold-critical.svg)
- Fixed-width reserved marker slot preserving bar track length equality
- Row-sibling placement (not bar-overlay) with mode-specific position (before percent in Overview, after in detail)
- Accessible description enhancement with risk phrasing
- Tab underline exclusion (ProviderSelector.qml unchanged)
- Shared marker implementation preventing summary/detail divergence

## SDD Cycle Complete

This change has fully transitioned through:
1. ✓ Exploration & Proposal
2. ✓ Specification (1 new requirement with 8 scenarios)
3. ✓ Design (30 architecture decisions across 3 design revisions, D1–D30)
4. ✓ Tasks (9 implementation phases, 54 checked + 2 superseded-unchecked, user-approved final gate)
5. ✓ Apply (All code committed; branch: visual-parity-polish/pr6-overview-and-icon-fix)
6. ✓ Verify (PASS WITH WARNINGS, all functional coverage confirmed, CI-clean)
7. ✓ Archive (specs merged, folder archived, byte-verified, report recorded)

The change is closed and ready for the next iteration.

## Known Limitations (Recorded, Not Blocking)

### Offscreen Visual-Regression Harness Limitations

The `QT_QPA_PLATFORM=offscreen` + `QT_QUICK_BACKEND=software` testing environment has two documented limitations for this marker feature (does not reflect real hardware rendering):

1. **Icon theme glyph loading** (Phase 5): Freedesktop icon-theme names (`emblem-warning-symbolic` / `emblem-important-symbolic`) silently fail to load under offscreen rendering (no platform-theme plugin), rendering as blank pixels. **Resolution**: Switched to bundled SVG resources (D29) in Phase 8, fixing the loading gap.

2. **Icon color recoloring** (Phase 9): Bundled SVG masks with `isMask:true` fail to apply the bound `color:` property override under this offscreen/software Qt 6.11.1 path when the source is a local `Qt.resolvedUrl()` SVG (not theme-loaded). **Confirmed**: An isolated reproduction outside the app shows the SVG loads (`status===Ready`) and paints, but `color` binding is ignored; rendered as SVG's intrinsic black (`fill="currentColor"` defaults). Because the test-capture background is pre-existing solid black (unrelated to Light/Dark theming), the black-on-black result is invisible. **Mitigation**: Manual live smoke (3.5d, Phase 9) confirmed the marker renders with correct colors on real hardware-accelerated Plasma (Breeze Light + Dark, "ahora si me gusta como quedo").

Neither limitation affects the shipped behavior; both are isolated to this repo's specific CI testing environment and are already documented in this archive report and `docs/ui-parity-checklist.md`.

## Risks / Notes

**None blocking.** All implementation tasks completed, verification passed (warnings resolved), specs merged cleanly, and archive verified byte-identical. User explicitly approved final state.

---

**Archive Date**: 2026-08-17
**Archived By**: sdd-archive phase agent
**Spec Merge Verification**: Delta spec appended to main spec; 54 lines added (1 requirement + 8 scenarios)
**Archive Integrity Verification**: diff -r output empty (bytes identical)
**Status**: COMPLETE
