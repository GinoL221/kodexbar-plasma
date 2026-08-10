import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false

    property var controller: null

    function assert(condition, message) {
        if (!condition) {
            console.log("UsageControllerHarness failure:", message)
            assertionFailed = true
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        controller = controllerComponent.createObject(root, {
            commandPath: "/tmp/cli dir/cli'$(unsafe)",
            timeoutMs: 60000,
            testMode: true
        })
        assert(controller.commandLine() === "'/tmp/cli dir/cli'\\''$(unsafe)' usage --provider all --format json --json-only",
               "command must quote only the configured path and append fixed arguments")
        assert(!controller.validatePath("codexbar").valid, "relative paths must be rejected")

        controller.setPathExecutableForTest(false)
        controller.commandPath = "/definitely/missing/codexbar"
        controller.requestRefresh()
        assert(controller.phase === "error", "missing absolute paths must fail preflight")
        assert(controller.activeRequestCount === 0, "missing paths must not start the CLI request")
        assert(controller.errorMessage.indexOf("not executable") !== -1,
               "missing paths must explain how to correct the CLI path")

        controller.commandPath = "/dev/null"
        controller.requestRefresh()
        assert(controller.phase === "error", "non-executable absolute paths must fail preflight")
        assert(controller.activeRequestCount === 0, "non-executable paths must not start the CLI request")

        controller.setPathExecutableForTest(true)
        controller.commandPath = "/tmp/cli dir/cli'$(unsafe)"

        controller.requestRefresh()
        controller.requestRefresh()
        assert(controller.activeRequestCount === 1, "only one request may be active")
        assert(controller.refreshQueued, "overlap must queue one follow-up")
        var currentGeneration = controller.generation
        controller.completeForTest(currentGeneration - 1, "[]", 0)
        assert(controller.activeRequestCount === 1, "stale completion must not release the active request")
        controller.timeoutForTest(currentGeneration)
        assert(controller.phase === "loading", "timeout must start the queued refresh")
        assert(controller.generation === currentGeneration + 1, "queued refresh must start once")
        controller.timeoutForTest(controller.generation)
        assert(controller.phase === "error", "timeout must become a recoverable error")
        assert(controller.committedProviders.length === 0, "timeout must not commit output")
        finish()
    }

    Component {
        id: controllerComponent

        UsageUi.UsageController { }
    }
}
