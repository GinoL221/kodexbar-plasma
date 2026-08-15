import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false
    property var controller: null
    property var usage: null

    function assert(condition, message) {
        if (!condition) {
            console.error("CostControllerHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    function payloadFor(provider, value) {
        return JSON.stringify([{
            provider: provider, source: "local",
            sessionCostUSD: value, sessionTokens: value,
            last30DaysCostUSD: value, last30DaysTokens: value
        }])
    }

    Component.onCompleted: {
        controller = controllerComponent.createObject(root, {
            commandPath: "/tmp/codexbar",
            testMode: true
        })

        assert(controller.timeoutMs === 60000, "the default cost watchdog must be 60 seconds")
        assert(controller.snapshotFor("codex", 1) === null, "no snapshot exists before any request")
        assert(controller.errorMessage === undefined, "CostController must expose no diagnostic property")

        // Allowlist: an unsupported provider must never start a process.
        controller.request("gpt4", 1)
        assert(controller.activeRequestCount === 0, "an unsupported provider must be rejected before any request")
        assert(controller.snapshotFor("gpt4", 1) === null, "a rejected provider must never publish a snapshot")

        // Exact allowlisted, shell-quoted argv.
        controller.request("codex", 1)
        assert(controller.activeRequestCount === 1, "an allowlisted provider must become active")
        assert(controller.activeSource === "'/tmp/codexbar' cost --provider 'codex' --format json --json-only",
               "the command must be exactly cost --provider {provider} --format json --json-only")
        var firstSerial = controller.activeSerial

        // Coalescing: an identical active pair must not start a second process.
        controller.request("codex", 1)
        assert(controller.activeRequestCount === 1, "an identical in-flight pair must coalesce")
        assert(controller.activeSerial === firstSerial, "coalescing must not restart the active request")

        // Replacement: a different provider/generation while active must replace it.
        controller.request("claude", 2)
        assert(controller.activeProvider === "claude" && controller.activeGeneration === 2,
               "a different pair must replace the in-flight request")
        assert(controller.activeSerial !== firstSerial, "replacement must start a new request serial")
        var secondSerial = controller.activeSerial

        // Stale callback: the superseded serial can never publish, even with a
        // matching provider/generation payload.
        controller.completeForTest(firstSerial, payloadFor("codex", 1), 0)
        assert(controller.snapshotFor("codex", 1) === null, "a stale serial must never commit a snapshot")
        assert(controller.activeRequestCount === 1, "a stale callback must not release the current request")

        // Wrong-provider payload for the current request must be discarded.
        controller.completeForTest(secondSerial, payloadFor("codex", 1), 0)
        assert(controller.snapshotFor("claude", 2) === null, "a mismatched-provider payload must never commit")
        assert(controller.activeRequestCount === 0, "an invalid payload must still release the request")
        assert(controller.errorMessage === undefined, "an invalid payload must not add a diagnostic property")

        // A valid matching payload commits exactly the normalized snapshot.
        controller.request("claude", 3)
        var thirdSerial = controller.activeSerial
        controller.completeForTest(thirdSerial, payloadFor("claude", 2), 0)
        var snapshot = controller.snapshotFor("claude", 3)
        assert(snapshot !== null, "a valid matching payload must commit a snapshot")
        assert(snapshot.sessionCostUSD === 2, "the committed snapshot must preserve CLI-supplied values")
        assert(controller.activeRequestCount === 0, "a successful commit must release the request")

        // A fresh committed pair must not start a duplicate request.
        controller.request("claude", 3)
        assert(controller.activeRequestCount === 0, "a fresh committed pair must not restart a process")

        // Timeout releases without ever publishing.
        controller.request("codex", 4)
        var timedOutSerial = controller.activeSerial
        controller.timeoutForTest(timedOutSerial)
        assert(controller.activeRequestCount === 0, "a timeout must release the request")
        assert(controller.snapshotFor("codex", 4) === null, "a timeout must never publish a snapshot")
        assert(controller.errorMessage === undefined, "a timeout must not add a diagnostic property")

        // Missing/invalid commandPath fails closed without starting a process.
        controller.commandPath = ""
        controller.request("codex", 5)
        assert(controller.activeRequestCount === 0, "an invalid path must never start a process")
        assert(controller.snapshotFor("codex", 5) === null, "an invalid path must never publish a snapshot")
        controller.commandPath = "/tmp/codexbar"

        // REFACTOR proof: raced, timed-out, and malformed cost activity must
        // never mutate a side-by-side UsageController, even after it has a
        // committed snapshot of its own.
        usage = usageComponent.createObject(root, { commandPath: "/tmp/codexbar", testMode: true })
        usage.requestRefresh()
        usage.completeForTest(usage.generation, JSON.stringify([
            { provider: "codex", usage: { primary: { usedPercent: 10 } } }
        ]), 0)
        var usagePhase = usage.phase
        var usageGeneration = usage.committedGeneration
        var usageProviders = JSON.stringify(usage.committedProviders)
        var usageErrors = JSON.stringify(usage.committedErrors)
        var usageErrorMessage = usage.errorMessage

        controller.request("codex", 200)
        var racedSerial = controller.activeSerial
        controller.request("claude", 201)
        controller.completeForTest(racedSerial, payloadFor("codex", 9), 0)
        controller.timeoutForTest(controller.activeSerial)
        controller.request("codex", 202)
        controller.completeForTest(controller.activeSerial, "{malformed", 0)

        assert(usage.phase === usagePhase, "usage phase must be unaffected by unrelated cost activity")
        assert(usage.committedGeneration === usageGeneration,
               "usage committedGeneration must be unaffected by unrelated cost activity")
        assert(JSON.stringify(usage.committedProviders) === usageProviders,
               "usage committedProviders must be unaffected by unrelated cost activity")
        assert(JSON.stringify(usage.committedErrors) === usageErrors,
               "usage committedErrors must be unaffected by unrelated cost activity")
        assert(usage.errorMessage === usageErrorMessage,
               "usage errorMessage must be unaffected by unrelated cost activity")
        assert(controller.snapshotFor("codex", 200) === null, "a raced-out cost request must never publish")
        assert(controller.snapshotFor("codex", 202) === null, "a malformed cost payload must never publish")
        usage.destroy()

        finish()
    }

    Component {
        id: controllerComponent

        UsageUi.CostController { }
    }

    Component {
        id: usageComponent

        UsageUi.UsageController { }
    }
}
