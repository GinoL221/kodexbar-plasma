import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false

    property string fixturePath: Qt.resolvedUrl("fixtures/codexbar-cost-lifecycle-fixture.sh").toString().replace(/^file:\/\//, "")
    property bool committedObserved: false

    function assert(condition, message) {
        if (!condition) {
            console.error("CostControllerDataSourceLifecycleHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        controller.request("codex", 1)
        root.assert(controller.activeRequestCount === 1, "an allowlisted request must become active")
        timeout.start()
    }

    UsageUi.CostController {
        id: controller
        commandPath: root.fixturePath
        timeoutMs: 5000
        onSnapshotsChanged: {
            if (root.committedObserved) {
                return
            }
            var snapshot = controller.snapshotFor("codex", 1)
            if (snapshot === null) {
                return
            }
            root.committedObserved = true
            root.assert(snapshot.provider === "codex", "the committed snapshot must belong to the requested provider")
            root.assert(snapshot.source === "local", "the committed snapshot must preserve the CLI-supplied source")
            root.assert(snapshot.sessionCostUSD === 0, "the committed snapshot must preserve sessionCostUSD")
            root.assert(snapshot.last30DaysCostUSD === 1.5, "the committed snapshot must preserve last30DaysCostUSD")
            root.assert(snapshot.last30DaysTokens === 42, "the committed snapshot must preserve last30DaysTokens")
            Qt.callLater(function() {
                root.assert(controller.activeRequestCount === 0, "a successful commit must release the active request")

                // Requesting the exact same fresh pair again must coalesce: no
                // second process, and the same snapshot instance remains committed.
                controller.request("codex", 1)
                root.assert(controller.activeRequestCount === 0, "a fresh matching pair must not start a duplicate process")
                root.assert(controller.snapshotFor("codex", 1) !== null, "the fresh snapshot must remain available")
                root.finish()
            })
        }
    }

    Timer {
        id: timeout
        interval: 6000
        onTriggered: {
            root.assert(false, "the cost DataSource lifecycle did not commit a snapshot")
            Qt.exit(1)
        }
    }
}
