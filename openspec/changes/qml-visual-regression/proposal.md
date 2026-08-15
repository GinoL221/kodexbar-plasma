# Proposal: QML Visual Regression

## Intent

Add deterministic, component-level visual regression for the selected-provider UI. Existing geometry and accessibility checks cannot detect clipping, spacing, icon, or Breeze-style regressions. This adds pixel coverage without claiming live Plasma certification.

## Scope

### In Scope
- Add geometry/accessibility assertions first for selected-provider Cost-present and Cost-absent states.
- Capture four fixed `450x400` offscreen fixtures: Breeze Light/Dark × Cost present/absent.
- Compare decoded RGBA pixels with a calibrated threshold and produce diffs.
- Add explicit `UPDATE_GOLDENS=1` replacement, documentation, and an independent `scripts/run-visual-tests.sh`.
- Expose the visual job locally and as non-blocking CI; preserve the 400-line review budget through slices.

### Out of Scope
- Changes to production UI behavior or the external `codexbar` boundary.
- `main.qml`/`PlasmoidItem`, live Plasma, assistive-technology traversal, or `plasmawindowed` screenshot automation.
- Automatic baseline updates, exact PNG-hash comparison, sudo, or merge gating on visual pixels on day one.

## Capabilities

### New Capabilities
- `qml-visual-regression`: deterministic geometry/a11y and selected-provider RGBA golden checks.

### Modified Capabilities
- None (test coverage only; existing provider-display requirements remain unchanged).

## Approach

Extend QML harnesses with authoritative geometry/a11y assertions, then add `tests/visual/VisualCaptureHarness.qml` using a fixed `Window`, synthetic stable data, software rendering, Breeze selection, and asynchronous `grabToImage`. Store four reviewed PNGs under `tests/visual/goldens/`. Use Pillow-only comparison with calibrated delta and changed-pixel percentage; fail with a summary and diff image. Keep the runner isolated from `scripts/run-qml-tests.sh` until repeatability is proven.

## Proposal question round

Assumptions: fixture text is stable; visual checks remain opt-in/non-blocking initially; live Plasma remains manual smoke coverage. Confirm or correct these before specs if expectations differ.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `tests/visual/` | New | Capture harness, comparator, and four goldens |
| `scripts/run-visual-tests.sh` | New | Isolated capture/compare workflow |
| `tests/ProviderDetailsIntegrationTest.qml`, `tests/ProviderRowHarness.qml` | Modified | Geometry/a11y assertions |
| `docs/visual-regression.md`, `docs/live-plasma-smoke.md`, `docs/ui-parity-checklist.md` | Modified | Policy, workflow, and coverage boundaries |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Qt, Breeze, font, DPI, or renderer variance causes churn | High | Fixed software fixture, documented tolerance, reviewed explicit refresh |
| Threshold hides a real regression | Med | Calibrate on two identical runs; keep geometry/a11y authoritative |

## Rollback Plan

Revert visual test files, goldens, runner, and documentation as one change. Production QML remains untouched; disable the runner if variance is unacceptable.

## Dependencies

- Qt 6/qmltestrunner, Pillow, and existing Breeze/offscreen test environment; no package installation or sudo.

## Success Criteria

- [ ] Four scenarios pass locally with stable calibrated RGBA comparisons.
- [ ] Intentional visual drift fails with a diff and never updates goldens automatically.
- [ ] Documentation clearly separates offscreen component coverage from manual live-Plasma smoke.
