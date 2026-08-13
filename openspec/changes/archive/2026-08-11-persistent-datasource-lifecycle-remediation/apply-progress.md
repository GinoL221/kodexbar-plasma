# Apply Progress: Persistent DataSource Lifecycle Remediation

## Baseline historical artifact hashes

Captured before any remediation edits:

| File | SHA-256 |
|---|---|
| `openspec/changes/persistent-datasource-lifecycle/design.md` | `d7ecbc71b88d538d5acb9e25beb770bf60c66d567dbfb5bb7bdfd698ab86610a` |
| `openspec/changes/persistent-datasource-lifecycle/specs/provider-usage-display/spec.md` | `2750a345f0a6ca5670c52f5f97481f7154557a6143b6c63130f9b60bd072caf7` |
| `openspec/changes/persistent-datasource-lifecycle/verify-report.md` | `a662864cec2edcedf3a5b8aa030cddce75f300487b27748cb52a5bb8e7b5a6e3` |

Check-only comparison command:

```bash
sha256sum -c <<'EOF'
d7ecbc71b88d538d5acb9e25beb770bf60c66d567dbfb5bb7bdfd698ab86610a  openspec/changes/persistent-datasource-lifecycle/design.md
2750a345f0a6ca5670c52f5f97481f7154557a6143b6c63130f9b60bd072caf7  openspec/changes/persistent-datasource-lifecycle/specs/provider-usage-display/spec.md
a662864cec2edcedf3a5b8aa030cddce75f300487b27748cb52a5bb8e7b5a6e3  openspec/changes/persistent-datasource-lifecycle/verify-report.md
EOF
```

Final historical artifact hashes after remediation: identical to baseline (verified 2026-08-11).

## TDD Cycle Evidence

| Task | Test File / Check | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|---|---|---|---|---|---|---|---|
| 1.1 | `sha256sum` baseline | N/A (structural) | N/A | N/A | N/A | Skipped single output | N/A |
| 1.2 | `openspec/.../design.md` exit-code contract | N/A (docs) | N/A | N/A | N/A | Skipped single output | N/A |
| 1.3 | `docs/live-plasma-smoke.md` template | N/A (docs) | N/A | N/A | N/A | Skipped single output | N/A |
| 1.4 | `tests/AssertionLegacyMaskingProbe.qml` | Harness unit | N/A (new) | Written (masks failure, exits 0) | Passed `exit=0` | 2 cases (pass + fail) | Clean |
| 1.5 | `tests/*Harness.qml` (15 files) | Harness unit / static | Full runner green before edits | Static check `0/15` had `Qt.exit(1)` before change | All 15 helpers now latch, `Qt.exit(1)`, and throw | Runtime probes + full suite | Clean |
| 1.6 | `tests/AssertionFailFastProbe.qml` | Harness unit | N/A (new) | Written (desired fail-fast invariant) | Passed `exit=1` | 2 cases (pass + fail) | Clean |
| 1.7 | Static grep verification | Static | N/A | N/A | 15 helpers OK, TerminationHarness untouched | N/A | Clean |
| 1.8 | Focused probes + `CompactUsageButtonHarness` | Harness unit | N/A | N/A | Probe `exit=1`, legacy probe `exit=0`, harness `exit=0` | 3 scenarios | Clean |
| 1.9 | `./scripts/run-qml-tests.sh` | Integration | Full runner green before edits | N/A | exit 0, 27 QtTest outcomes + 16 harnesses + termination | Full matrix | Clean |
| 1.10 | `git diff --check` + diff stat | Static | N/A | N/A | No whitespace errors; only docs and harnesses changed | N/A | Clean |
| 1.11 | This apply-progress artifact | N/A (evidence) | N/A | N/A | N/A | Skipped single output | N/A |

## Work Unit Evidence

### Work unit 1 — Documentation reconciliation

- **Focused test command and exact result**: `grep -E 'Evidence class|Observer / source|Command path|Plasma / runtime context|Ready outcome|Visible provider rows|Compact summary|Date / reference|Automation limitations' docs/live-plasma-smoke.md` returned 9 matching lines; `grep -E 'nonzero exit|empty stdout|Error' openspec/changes/persistent-datasource-lifecycle-remediation/design.md` returned matching contract text.
- **Runtime harness command/scenario and exact result**: N/A — documentation work unit has no runtime boundary.
- **Rollback boundary**: Revert `openspec/changes/persistent-datasource-lifecycle-remediation/design.md` (exit-code contract section) and `docs/live-plasma-smoke.md` (manual evidence template section).

### Work unit 2 — Assertion helper RED/GREEN probes and 15-harness hardening

- **Focused test command and exact result**:
  - `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/AssertionFailFastProbe.qml` → `exit=1`
  - `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 --software -f tests/AssertionLegacyMaskingProbe.qml` → `exit=0`
  - Static helper check confirmed all 15 targeted harnesses contain `Qt.exit(1)` inside `assert`; `UsageControllerTerminationHarness.qml` was not edited.
- **Runtime harness command/scenario and exact result**: `./scripts/run-qml-tests.sh` → exit 0, with 27 QtTest outcomes passing and all 16 standalone harnesses plus the termination harness completing.
- **Rollback boundary**: Revert the 15 modified `tests/*Harness.qml` files and delete `tests/AssertionLegacyMaskingProbe.qml` and `tests/AssertionFailFastProbe.qml`.

### Work unit 3 — Full verification and historical-integrity evidence

- **Focused test command and exact result**: `sha256sum -c` with the baseline checksum block above → all three historical files OK.
- **Runtime harness command/scenario and exact result**: `./scripts/run-qml-tests.sh` → exit 0; known non-failing offscreen `i18n`/`i18np` ReferenceError QWARNs observed in `configGeneral.qml` (pre-existing).
- **Rollback boundary**: Same as work units 1 and 2 combined.

## Changed files

| File | Action | What changed |
|---|---|---|
| `openspec/changes/persistent-datasource-lifecycle-remediation/design.md` | Modified | Added Exit-code contract section |
| `docs/live-plasma-smoke.md` | Modified | Added manual evidence record template and limitations note |
| `tests/AssertionLegacyMaskingProbe.qml` | Created | RED probe showing legacy helper can mask a failure and exit 0 |
| `tests/AssertionFailFastProbe.qml` | Created | GREEN probe showing strengthened helper exits 1 and aborts the callback |
| `tests/CompactUsageButtonHarness.qml` | Modified | Fail-fast `assert` (latch + `Qt.exit(1)` + throw) |
| `tests/ErrorSummaryHarness.qml` | Modified | Fail-fast `assert` |
| `tests/MainCompactHarness.qml` | Modified | Fail-fast `assert` |
| `tests/ProviderRowHarness.qml` | Modified | Fail-fast `assert` |
| `tests/RefreshIntervalHarness.qml` | Modified | Fail-fast `assert` |
| `tests/RequestTimeoutHarness.qml` | Modified | Fail-fast `assert` |
| `tests/RequestTimeoutSettingsHarness.qml` | Modified | Fail-fast `assert` |
| `tests/TimeoutFeedbackPopupHarness.qml` | Modified | Fail-fast `assert` |
| `tests/UsageControllerHarness.qml` | Modified | Fail-fast `assert` (also switched log to `console.error`) |
| `tests/UsageControllerDataSourceLifecycleHarness.qml` | Modified | Fail-fast `assert` |
| `tests/UsageControllerFailureHarness.qml` | Modified | Fail-fast `assert` |
| `tests/UsageControllerLifecycleHarness.qml` | Modified | Fail-fast `assert` |
| `tests/UsageControllerPathCheckHarness.qml` | Modified | Fail-fast `assert` |
| `tests/UsageControllerPreflightHarness.qml` | Modified | Fail-fast `assert` |
| `tests/UsageModelHarness.qml` | Modified | Fail-fast `assert` with consistent prefix |

## Files intentionally unchanged

- All production QML under `contents/ui/`
- `tests/UsageControllerTerminationHarness.qml`
- `scripts/run-qml-tests.sh`
- Historical `persistent-datasource-lifecycle` artifacts (`design.md`, `specs/provider-usage-display/spec.md`, `verify-report.md`)

## Verification summary

- `./scripts/run-qml-tests.sh`: exit 0
- `git diff --check`: no output
- Historical artifact hashes: unchanged from baseline
- `UsageControllerTerminationHarness.qml`: no diff

## Risks and issues

None. The change stayed within the approved scope and below the 800-line review budget.
