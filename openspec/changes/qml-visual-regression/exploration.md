## Exploration: qml-visual-regression

### Current State
`scripts/run-qml-tests.sh` runs three QtTest suites, then `ProviderDetailsIntegrationTest.qml` twice under fixed BreezeLight/BreezeDark schemes with `QT_QPA_PLATFORM=offscreen` and `QT_QUICK_BACKEND=software`, followed by standalone `qml6 --software` harnesses. The integration test already creates a visible `450x400` `Window` and renders real `ProviderRow` composition; existing harnesses assert narrow/wide geometry, wrapping, scrollbar behavior, keyboard focus, and accessible names. There is no `grabToImage` usage or image-comparison runner. `main.qml` is not an offscreen visual-test target because it requires a real `PlasmoidItem` representation; its live behavior remains covered by the manual Plasma checklist.

Qt Quick provides the feasible capture mechanism: `Item.grabToImage(callback, targetSize)` is asynchronous and its `ItemGrabResult.saveToFile()` writes a local PNG. The host has Qt 6.11.1, qmltestrunner, Pillow 12.3.0, and ImageMagick, with no sudo requirement. There are no repository GitHub workflow files, so visual coverage should initially be a local, opt-in gate rather than a CI requirement.

### Affected Areas
- `tests/visual/VisualCaptureHarness.qml` — new fixed-size `Window` fixture that renders selected-provider scenarios and waits for asynchronous captures.
- `tests/visual/goldens/` — checked-in Light/Dark PNG baselines for selected provider with and without a valid Cost snapshot.
- `tests/visual/compare_visuals.py` — new Pillow-only pixel comparator and explicit update-mode guard.
- `scripts/run-visual-tests.sh` — new isolated offscreen capture/compare runner; the main runner stays behavior-only.
- `tests/ProviderDetailsIntegrationTest.qml` and `tests/ProviderRowHarness.qml` — retain and, where needed, extend deterministic geometry/a11y assertions rather than replacing them with pixels.
- `docs/visual-regression.md` — fixture, dependency, threshold, golden-update, and non-coverage policy.
- `docs/live-plasma-smoke.md` and `docs/ui-parity-checklist.md` — link automated offscreen coverage while retaining live Plasma, keyboard, and native-theme acceptance work.

### Approaches
1. **Geometry and accessibility assertions only** — Expand the existing QtTest and executable QML harnesses around fixed widths, bounds, overflow, focus, labels, and selected-provider conditional content.
   - Pros: Fast, deterministic, dependency-free, and already matches established test patterns.
   - Cons: Cannot detect spacing, clipping, icon, or visual-style regressions that preserve object geometry.
   - Effort: Low.

2. **Isolated offscreen captures plus Pillow golden comparison** — Add a standalone `qml6 --software` capture harness using a fixed `450x400` window, explicit fixture data, `KDE_COLOR_SCHEME`, and `grabToImage`; compare four focused PNGs (Light/Dark × Cost present/absent) after geometry assertions settle.
   - Pros: Covers real component composition and theme-sensitive pixels without Plasma runtime or sudo; keeps asynchronous capture and external image diff out of QtTest; Pillow is present and produces actionable diff artifacts.
   - Cons: Font/Breeze/Qt upgrades can require intentional golden refreshes; it cannot prove real `PlasmoidItem`, panel behavior, or assistive-technology traversal.
   - Effort: Medium.

3. **Full `plasmawindowed` screenshot automation** — Drive the installed applet and desktop screenshots in CI.
   - Pros: Exercises the actual Plasma representation.
   - Cons: Requires a stable Plasma session and input/display automation, is environment-dependent, and contradicts the approved no-CI/day-one boundary.
   - Effort: High.

### Recommendation
Adopt approaches 1 and 2 in that order. Keep geometry/a11y assertions authoritative for layout contracts, then add only four selected-provider goldens through an independent `scripts/run-visual-tests.sh`; do not append captures to `run-qml-tests.sh` until repeatability is demonstrated. The capture harness should use its own `Window`, fixed dimensions, no animations/timers beyond the capture-ready event loop, synthetic non-localized fixture text, and direct `ProviderRow` composition. This reuses the proven Breeze/offscreen pattern while avoiding the untestable `PlasmoidItem` path.

Use Pillow as the sole image dependency: the runner must fail clearly when `import PIL` is unavailable and must never install packages or invoke sudo. Compare decoded RGBA pixels, not PNG hashes: exact hashes are brittle to encoding and renderer changes. Set a documented per-channel delta and changed-pixel percentage only after two identical local runs establish a baseline; fail with an absolute diff PNG and summary. Golden replacement must require an explicit `UPDATE_GOLDENS=1` command, followed by visual review in both themes. ImageMagick may be a developer diagnostic, not a required runner dependency.

Suggested review slices under the 400-line budget: (1) geometry/a11y RED→GREEN additions; (2) capture harness, isolated runner, comparator, and four generated goldens; (3) documentation and opt-in policy. Generated PNGs are excluded from authored-line risk but must be reviewed as complete snapshot artifacts.

### Risks
- Offscreen rendering can vary with Qt, Breeze, fonts, DPI, or image plugins; fixed software rendering, fixture dimensions, documented tolerances, and separate opt-in execution reduce but do not eliminate churn.
- Direct `ProviderRow` captures cannot catch a `main.qml`/Plasmoid scope or live-panel regression; retain the manual `plasmawindowed` and Breeze smoke gates.
- A permissive threshold can hide regressions and an exact threshold can be flaky; calibrate and record the smallest defensible threshold before making the runner blocking.

### Ready for Proposal
Yes — propose a separate `qml-visual-regression` change with the isolated runner and four-golden scope. Tell the user that it adds a reliable offscreen regression layer, not automated live-Plasma certification or CI gating on day one.
