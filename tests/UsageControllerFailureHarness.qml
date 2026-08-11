import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("UsageControllerFailureHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    function complete(controller, stdout, exitCode) {
        controller.requestRefresh()
        controller.completeForTest(controller.generation, stdout, exitCode)
    }

    Component.onCompleted: {
        var controller = controllerComponent.createObject(root, {
            commandPath: "/tmp/codexbar",
            testMode: true,
            timeoutMs: 180000
        })

        complete(controller, JSON.stringify([
            { provider: "usable", usage: { primary: { usedPercent: 42 } } }
        ]), 0)
        assert(controller.phase === "ready", "a valid response must commit usable data")
        assert(controller.committedProviders.length === 1, "the committed snapshot must contain valid providers")

        complete(controller, JSON.stringify([
            { provider: "usable", usage: { primary: { usedPercent: 42 } } }
        ]), "0")
        assert(controller.phase === "ready", "a zero exit code returned as text must be accepted")

        controller.requestRefresh()
        controller.timeoutForTest(controller.generation)
        assert(controller.phase === "error", "a timeout must produce a recoverable error")
        assert(controller.errorMessage === "CodexBar did not return all-provider usage within 180 seconds. Check enabled providers in CodexBar, temporarily disable a provider that hangs, then retry.", "timeout guidance must be exact and provider-neutral")
        assert(controller.activeRequestCount === 0, "a timeout must release the request for Refresh")
        assert(controller.committedProviders.length === 1, "a timeout must not replace the committed snapshot")

        complete(controller, "{malformed", 0)
        assert(controller.phase === "error", "malformed JSON must produce a recoverable error")
        assert(controller.committedProviders.length === 1, "malformed JSON must not replace the committed snapshot")
        assert(controller.activeRequestCount === 0, "malformed JSON must release the request for Refresh")

        complete(controller, JSON.stringify([
            { provider: "usable", usage: { primary: { usedPercent: 42 } } },
            { provider: "unavailable", error: { kind: "provider", message: "optional CLI missing" } }
        ]), 7)
        assert(controller.phase === "ready", "usable stdout must commit despite an optional provider failure")
        assert(controller.committedProviders.length === 1, "usable stdout must replace the committed snapshot")
        assert(controller.committedErrors.length === 1, "provider failure details must remain available")
        assert(controller.activeRequestCount === 0, "a nonzero CLI exit with output must release the request")

        complete(controller, "[]", 0)
        assert(controller.phase === "noData", "a valid empty response must produce No data")
        assert(controller.committedProviders.length === 0, "a valid empty response must atomically replace prior data")
        assert(controller.errorMessage === "", "a valid empty response must clear the transient error")
        finish()
    }

    Component {
        id: controllerComponent
        UsageUi.UsageController { }
    }
}
