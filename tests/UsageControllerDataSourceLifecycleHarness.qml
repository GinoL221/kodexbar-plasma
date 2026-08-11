import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false

    property string fixturePath: Qt.resolvedUrl("fixtures/codexbar-lifecycle-fixture.sh").toString().replace(/^file:\/\//, "")
    property bool readyObserved: false
    property bool pathFailureObserved: false

    function assert(condition, message) {
        if (!condition) {
            console.error("UsageControllerDataSourceLifecycleHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        controller.requestRefresh()
        timeout.start()
    }

    UsageUi.UsageController {
        id: controller
        commandPath: root.fixturePath
        timeoutMs: 5000
        onPhaseChanged: {
            if (phase === "ready" && !root.readyObserved) {
                root.assert(committedProviders.length === 1, "the fixture command must commit one provider")
                root.assert(committedProviders[0].provider === "fixture", "the committed provider must come from the fixture")
                root.readyObserved = true
                Qt.callLater(function() {
                    root.assert(controller.activeRequestCount === 0,
                                "successful completion must release the generation")
                    controller.commandPath = "/definitely/missing/codexbar"
                    controller.requestRefresh()
                })
            } else if (root.readyObserved && phase === "error" && !root.pathFailureObserved) {
                root.pathFailureObserved = true
                Qt.callLater(function() {
                    root.assert(controller.committedProviders.length === 1,
                                "path preflight failure must retain the committed snapshot")
                    root.assert(controller.committedProviders[0].provider === "fixture",
                                "path preflight failure must preserve the fixture provider")
                    root.assert(controller.activeRequestCount === 0,
                                "path preflight failure must release the request")
                    root.finish()
                })
            }
        }
    }

    Timer {
        id: timeout
        interval: 6000
        onTriggered: {
            root.assert(false, "preflight-to-command lifecycle did not reach Ready")
            Qt.exit(1)
        }
    }
}
