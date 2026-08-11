## Exploration: portable-cli-configuration

### Current State
The CLI setting is persisted as `codexbarCommand`, but its KConfig default, UI placeholder/reset fallback, `main.qml` fallback, and `UsageController` default all hardcode `/home/ginopc/.local/bin/codexbar`. Refresh always runs the configured value through a quoted `test -x` preflight and then exactly `usage --provider all --format json --json-only`; absolute-path validation, watchdog, request coalescing, stale-response protection, and provider handling are already independent of the default.

An empty, relative, missing, or non-executable path is already blocked with an actionable error. The README repeats the author path in installation and test commands, while the smoke guide tells testers to save and temporarily replace the configured path but does not give first-run discovery guidance. Existing non-empty configured values are read directly from KConfig and can remain unchanged.

### Affected Areas
- `contents/config/main.xml` — replace the author-specific persisted default with a portable unset default.
- `contents/ui/main.qml` — remove the author-specific runtime fallback so unset configuration reaches existing validation.
- `contents/ui/UsageController.qml` — remove the component-level author-specific default while preserving path validation, preflight, and exact command construction.
- `contents/ui/config/configGeneral.qml` — use a neutral example and explain that an absolute executable path is required; guide terminal discovery without using shell `PATH` at runtime.
- `tests/SettingsInteractionTest.qml` — update the native settings-field discovery assertion and cover portable empty-default/reset behavior.
- `tests/UsageControllerFixture.qml` and focused controller harnesses — confirm an unset path is rejected before preflight/command execution without changing command, timeout, or lifecycle coverage.
- `README.md` — replace author-specific commands with user-discovered absolute-path setup and troubleshooting guidance.
- `docs/live-plasma-smoke.md` — add first-run/setup and path-discovery steps while retaining fixture-path save/restore evidence.
- `openspec/specs/provider-usage-display/spec.md` — likely delta target for the portable first-run requirement, compatibility, and explicit non-goals.

### Approaches
1. **Unset required configuration** — Persist an empty CLI-path default, remove all author-path fallbacks, and show the existing actionable runtime validation until the user saves an absolute executable path. Settings and docs present a neutral placeholder plus a terminal discovery command whose output the user explicitly pastes into settings.
   - Pros: Does not assume install location or Plasma shell `PATH`; preserves every existing non-empty configured value; reuses validation/preflight; leaves the exact command and lifecycle intact.
   - Cons: A new installation initially shows an Error state until configured; settings copy must make the required action unmistakable.
   - Effort: Low

2. **Convention-based default** — Replace the author path with a generic location such as `/usr/bin/codexbar`.
   - Pros: A shorter apparent first-run path on a subset of installations.
   - Cons: Still guesses an install layout, fails for Homebrew/tarball/custom installs, and is not genuinely portable.
   - Effort: Low

3. **Runtime executable discovery** — Resolve `codexbar` with `PATH` or probe common locations before issuing the request.
   - Pros: Could reduce manual setup where the runtime environment happens to expose the CLI.
   - Cons: Violates the absolute configured-path model, is unreliable under Plasma's environment, broadens process/probing behavior, and risks changing the protected command/lifecycle boundary.
   - Effort: Medium

### Recommendation
Adopt **Unset required configuration**. The coherent smallest scope is an intentionally blank first-run value, a required native CLI-path field with neutral copy such as `/absolute/path/to/codexbar`, and concise guidance: run `command -v codexbar` in a terminal, verify the returned absolute path with the fixed all-provider command, then paste that path into widget settings. This discovers a path for the user but never relies on inherited `PATH` in Plasma. Existing saved absolute values remain authoritative; no migration is needed. The preflight and command boundary remain untouched.

### Risks
- Removing `main.qml`'s `||` fallback makes an intentionally blank existing value surface the current configuration error rather than silently running the author's path; this is the necessary safe behavior but should be called out as a compatibility change for blank/invalid stored values.
- A terminal may locate an executable that Plasma cannot access because of permissions, sandboxing, or a different environment; the existing absolute-path `test -x` preflight must remain the final runtime check.
- Settings currently restore invalid input to the configured default. With an empty default, focused tests and copy must ensure this correction is understandable rather than looking like lost input.
- Documentation examples must not imply that `command -v` is a runtime dependency or authorize fallback probing.

### Ready for Proposal
Yes — propose an unset required CLI-path default, explicit first-run settings/documentation guidance, focused regression coverage, and explicit exclusions for PATH lookup, location probing, migration, CLI arguments, timeout/lifecycle/provider changes. The likely authored change is comfortably below the 800-line review budget; under ask-on-risk, reassess only if the proposal expands beyond these focused files.
