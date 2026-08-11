# Proposal: Portable CLI Configuration

## Intent

Make CodexBar usable across installations without embedding a maintainer-specific path. New users should receive clear configuration-first guidance; existing users should retain valid choices and receive safe recovery when saved paths stop working.

## Scope

### In Scope
- Use an empty default for new installs and remove author-path fallbacks.
- Revalidate saved paths on use/upgrade; preserve valid paths and never silently replace them.
- Try deterministic, bounded discovery in this order: `$HOME/.local/bin/codexbar`, `/usr/local/bin/codexbar`, `/usr/bin/codexbar`, then `$HOMEBREW_PREFIX/bin/codexbar` when defined.
- Validate each candidate as absolute and executable through the existing `test -x` preflight; select the first valid candidate.
- Fall back closed to manual configuration with actionable guidance covering installation, `command -v codexbar`, external credentials, OpenCode Go prerequisite, troubleshooting, and verification.
- Update focused tests, README, and live-Plasma smoke guidance.

### Out of Scope
- Provider or authentication implementation, credential automation, or OpenCode Go setup automation.
- Changes to command arguments, request lifecycle, watchdog, refresh, or timeout behavior.
- Plasma inherited `PATH`, arbitrary filesystem scanning, broad probing, or silently choosing an unverified executable.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `provider-usage-display`: define portable first-run configuration, bounded discovery, saved-path revalidation, and fail-closed manual fallback while preserving the exact CLI boundary.

## Approach

Keep the configured value as the authoritative absolute-path boundary. On an unset or invalid value, evaluate only the approved candidates in deterministic order, using the existing executable preflight. Persist/use a candidate only after validation; otherwise expose the configuration-first state and manual instructions. Existing valid values remain untouched. Preserve `usage --provider all --format json --json-only` and all lifecycle behavior.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `contents/config`, `contents/ui` | Modified | Portable defaults, discovery, validation feedback, native settings guidance. |
| `tests/` | Modified | New-install, revalidation, candidate-order, and fail-closed coverage. |
| `README.md`, `docs/live-plasma-smoke.md` | Modified | Setup, credentials/prerequisite, troubleshooting, and verification guidance. |
| `openspec/specs/provider-usage-display/spec.md` | Modified | Requirement delta for portable configuration behavior. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| A discovered path works in one environment but not Plasma | Med | Keep `test -x` as the runtime gate and fall back visibly. |
| Candidate order selects an unintended executable | Low | Restrict to four explicit candidates; require validation; never scan. |
| Invalid saved values appear “lost” | Med | Explain revalidation and preserve actionable manual recovery. |

## Rollback Plan

Revert the configuration/UI/discovery/docs/test changes as one change set. Existing valid saved absolute paths remain compatible; removing discovery restores manual configuration without changing the CLI command contract.

## Dependencies

- CodexBar must be installed and externally authenticated; OpenCode Go must be available where required by the documented workflow.

## Success Criteria

- [ ] New installs reach an explicit configuration-first experience and no author path is used.
- [ ] Valid saved paths are preserved; invalid paths revalidate and fail closed.
- [ ] Discovery follows the approved order and never uses inherited `PATH` or filesystem scanning.
- [ ] Guidance enables installation, prerequisite/credential setup, troubleshooting, and verification.
- [ ] Focused and full QML test suites pass; authored review workload remains below 800 lines.

Decision needed before apply: No
Chained PRs recommended: No
800-line budget risk: Low
