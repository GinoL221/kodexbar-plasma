# Tasks: Final Popup Parity

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated authored changed lines | 650–850 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | Four independently green work units |
| Delivery strategy | ask-on-risk |
| Chain strategy | feature-branch-chain |
| Size exception needed | No—unless chaining is declined |

Decision needed before apply: No — resolved
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Cost fixture/model contract | PR 1 | `./scripts/run-qml-tests.sh` | Offscreen cost-model fixture | `CostModel.js`, cost fixture, capture docs/tests |
| 2 | Isolated cost lifecycle | PR 2 | `./scripts/run-qml-tests.sh` | Offscreen DataSource lifecycle race harness | `CostController.qml`, usage generation, lifecycle tests |
| 3 | Safe selected-detail UI | PR 3 | `./scripts/run-qml-tests.sh` | ProviderRow/Selector narrow-width harness | extractors, popup components, UI tests |
| 4 | Release evidence | PR 4 | `./scripts/lint-qml.sh` | `plasmawindowed` Breeze/keyboard smoke | docs, package/lint/smoke evidence |

### PR 2 Size Exception (accepted)

PR 2 landed at ~569 authored changed lines, above the ~400-line per-unit target. Maintainer accepted `size:exception` on 2026-08-15: the overage is real-subprocess race/coalescing/60s-termination coverage for `CostController.qml` (the exact runtime boundary this work unit exists to prove), not padding. No further split was requested. `./scripts/run-qml-tests.sh` exit 0, all pre-existing `UsageController*` regressions and the 17/17 `UsageControllerFixture` suite (including the new `committedGeneration` case) remain green.

## Phase 1: Contract Foundation

- [x] 1.1 RED: Extend `tests/test_cli_contract_fixture.py` for `tests/fixtures/codexbar-cost-capture.json`: redaction, key/type fidelity, version/date, source, and exact cost argv evidence.
- [x] 1.2 GREEN: Add the redacted cost fixture, `docs/cli-contract-capture.md` evidence, and `contents/code/CostModel.js` finite/non-negative, matching-provider normalization; refactor copied snapshots.
- [x] 1.3 RED: Add cost-model QtTest coverage to `scripts/run-qml-tests.sh` for empty, partial, non-finite, wrong-provider, unsupported, and nonzero results hiding data.

## Phase 2: Independent Cost Lifecycle

- [x] 2.1 RED: Extend `tests/UsageControllerFixture.qml` plus a focused cost DataSource harness to preserve exact `usage --provider all --format json --json-only` argv and all existing usage lifecycle/coalescing/timeout/stale regressions.
- [x] 2.2 GREEN: Expose only successful `committedGeneration` in `contents/ui/UsageController.qml`; do not change its command or lifecycle branches.
- [x] 2.3 RED/GREEN: Create `contents/ui/CostController.qml` and tests for allowlisted shell-quoted `cost --provider {provider} --format json --json-only`, validated path, provider/generation/serial races, coalescing, replacement, and 60s termination.
- [x] 2.4 REFACTOR: Prove failed, timed-out, or stale cost never mutates usage and publishes no diagnostics.

## Phase 3: Selected-Provider Presentation

- [ ] 3.1 RED: Extend `tests/ProviderDetailsIntegrationTest.qml` for valid/invalid pace, remaining credit, positive reset expiries, email-only header, opaque UUID/hex org rejection, raw preservation, and fixture PII fail-closed cases.
- [ ] 3.2 GREEN: Extend `contents/code/ProviderDetails.js` with copied normalized extractors and identity fallback; keep all unmodeled fields under `raw` and unrendered.
- [ ] 3.3 RED: Extend `tests/ProviderSelectorHarness.qml` and `tests/ProviderRowHarness.qml` for icon/short-name tabs, compact `All`, cost-free `All`, conditional cost failure, disclosure accessibility, and narrow-width reachability.
- [ ] 3.4 GREEN/REFACTOR: Wire selected-provider cost in `contents/ui/main.qml`; update `ProviderSelector.qml`, `ProviderRow.qml`, `UsageWindowRow.qml`; add native `ProviderHeader.qml`, `ResetCreditsSection.qml`, and `CostSection.qml` with Breeze-safe wrapping and no redeem.

## Phase 4: Release Verification

- [ ] 4.1 Update `README.md` and `docs/live-plasma-smoke.md` with optional local-cost, exclusions, reset disclosure, and privacy expectations.
- [ ] 4.2 Run `./scripts/run-qml-tests.sh`, `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, and `git diff --check`; record results.
- [ ] 4.3 Manually smoke `plasmawindowed` in Breeze Light/Dark: keyboard disclosure, selected identity, narrow popup scrolling, cost isolation, and unchanged `All`.
