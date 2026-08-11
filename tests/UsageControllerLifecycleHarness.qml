import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false

    property var controller: null

    function assert(condition, message) {
        if (!condition) {
            console.error("UsageControllerLifecycleHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        controller = controllerComponent.createObject(root, {
            commandPath: "/tmp/codexbar",
            testMode: true,
            timeoutMs: 120000
        })
        controller.requestRefresh()
        controller.requestRefresh()
        assert(controller.activeRequestCount === 1, "only one request may be active")
        assert(controller.refreshQueued, "overlap must queue one follow-up")
        var firstGeneration = controller.generation
        controller.timeoutMs = 180000
        controller.completeForTest(firstGeneration - 1, "[]", 0)
        assert(controller.activeRequestCount === 1, "stale completion must not release the active request")
        controller.timeoutForTest(firstGeneration)
        assert(controller.phase === "loading", "timeout must start the queued refresh")
        assert(controller.generation === firstGeneration + 1, "queued refresh must start once")
        controller.timeoutForTest(controller.generation)
        assert(controller.phase === "error", "timeout must become a recoverable error")
        assert(controller.errorMessage.indexOf("180 seconds") !== -1, "a queued request must freeze the timeout active when it starts")
        assert(controller.committedProviders.length === 0, "timeout must not commit output")
        controller.startPreflightForTest()
        var preflightGeneration = controller.generation
        assert(controller.activeRequestCount === 1, "preflight must count as the active generation")
        controller.requestRefresh()
        assert(controller.refreshQueued, "a trigger during preflight must queue one follow-up")
        controller.timeoutForTest(preflightGeneration)
        assert(controller.phase === "loading", "a queued refresh must start only after terminal release")
        assert(controller.generation === preflightGeneration + 1,
                   "coalescing must start exactly one post-release generation")
        finish()
    }

    Component {
        id: controllerComponent

        UsageUi.UsageController { }
    }
}
