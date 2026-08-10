## Exploration: codexbar-timeout-feedback

### Current State
The plasmoid issues exactly one configured `codexbar usage --provider all --format json --json-only` command through `UsageController.qml`. Its request watchdog is 15 seconds; timeout disconnects the executable source and reaches the recoverable `error` phase. The popup already exposes `errorMessage` and an always-available Refresh button, while committed provider data remains intact after a failed refresh.

Confirmed locally: the all-provider command exits `124` after a bounded 20-second shell timeout with zero stdout and stderr. The CLI help confirms that `--provider all` honors upstream enabled-provider toggles. The existing timeout text, `CodexBar CLI request timed out.`, does not explain the all-provider boundary, the 15-second limit, or the safe workaround. The supplied investigation identifies Claude as the current likely hang, but the runtime callback carries no provider identity when it times out, so the UI cannot truthfully name a provider.

### Affected Areas
- `contents/ui/UsageController.qml` — replace the generic command-timeout message only; retain the existing 15-second watchdog, source disconnect, state transitions, and queued-refresh behavior.
- `tests/UsageControllerFixture.qml` — add RED/GREEN assertions for actionable timeout wording and retrying after timeout.
- `tests/UsageControllerFailureHarness.qml` or `tests/MainCompactHarness.qml` — extend the existing snapshot-retention timeout coverage if the exact user-visible contract needs an executable harness assertion.
- `README.md` — document the bounded all-provider diagnostic command and upstream enabled-provider workaround without adding provider fetching or authentication behavior.
- `docs/live-plasma-smoke.md` — optionally add a manual timeout/retry and narrow-popup readability check; this is documentation-only validation.

### Approaches
1. **Actionable generic timeout with upstream workaround** — Change the controller's command-timeout message to say that the all-provider request did not finish within 15 seconds, advise checking enabled providers in CodexBar, temporarily disabling a provider that hangs, and then retrying. Add matching README troubleshooting steps.
   - Pros: Smallest safe MVP; accurate for any unidentifiable hanging provider; preserves the external CLI boundary and current retry/concurrency logic.
   - Cons: Does not identify the hanging provider automatically; users must diagnose it upstream.
   - Effort: Low.

2. **Provider-specific timeout message** — Hard-code Claude (or infer a provider) in the timeout UI and documentation.
   - Pros: Faster guidance for the currently observed machine.
   - Cons: The all-provider timeout supplies no provider identity; would make a machine-specific hypothesis look like runtime fact and becomes stale when enabled providers change.
   - Effort: Low, but unsafe.

3. **Per-provider isolation or process-level timeout redesign** — Change fetching so one provider cannot block all-provider results.
   - Pros: Addresses the underlying aggregation failure.
   - Cons: Changes the authoritative all-provider request contract, provider-fetch strategy, lifecycle semantics, and test surface; explicitly deferred by product scope.
   - Effort: High.

### Recommendation
Choose Approach 1. Keep the 15-second controller boundary and generic runtime attribution. The proposed observable command-timeout state is: `CodexBar did not return all-provider usage within 15 seconds. Check enabled providers in CodexBar, temporarily disable a provider that hangs, then retry.` The popup continues to render the negative error label and its Refresh button; manual refresh starts one new request after timeout, subject to the existing one-active-request/coalescing rule. No output is not treated as successful data: a completed callback with empty stdout remains the distinct `CodexBar CLI returned no output.` error, while a watchdog expiry gets the timeout message.

README guidance should provide a bounded all-provider diagnostic command, then advise testing enabled providers upstream and temporarily disabling the one that hangs before refreshing the widget. It should not recommend `--web-timeout` as a general fix: the supplied Claude evidence says it still hangs despite that flag, and CLI help says source behavior is provider-specific. Documentation may mention Claude as observed environment-specific evidence only if clearly scoped; the UI MUST remain provider-neutral.

Tests for the later implementation should start RED: assert the 15-second actionable timeout message through `timeoutForTest()`, assert that a manual `requestRefresh()` from `error` returns to `loading` and creates one new generation, assert that a timeout never replaces a prior committed snapshot, and retain exact all-provider command and single-active-request checks. `./scripts/run-qml-tests.sh` currently passes (13 tests) with `/usr/lib/qt6/bin/qmltestrunner`.

### Risks
- Disconnecting the Plasma executable `DataSource` bounds the widget state, but this change does not prove or alter upstream child-process termination semantics.
- A documentation workaround depends on CodexBar's enabled-provider controls and CLI behavior, which are external and version-dependent.
- Naming Claude in runtime UI would be unsupported because timeout data contains no provider identity; it must remain generic until a future isolation change supplies authoritative attribution.
- The working tree already has unrelated staged and unstaged changes; implementation must isolate this small change.

### Ready for Proposal
Yes — propose a bounded feedback-and-documentation change only: actionable generic 15-second timeout wording, explicit manual retry/workaround guidance, and focused QML tests. Defer per-provider fetching, provider-specific attribution, auth changes, and CLI timeout configuration to a separate change.
