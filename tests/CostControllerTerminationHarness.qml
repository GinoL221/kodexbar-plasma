import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root

    property string command: Qt.resolvedUrl("fixtures/codexbar-cost-lifecycle-fixture.sh").toString().replace(/^file:\/\//, "")

    Component.onCompleted: {
        controller.request("codex", 1)
        replaceTimer.start()
    }

    UsageUi.CostController {
        id: controller
        commandPath: root.command
        timeoutMs: 5000
    }

    Timer {
        id: replaceTimer
        interval: 500
        onTriggered: {
            // A selection/generation change while a cost request is in flight
            // must replace it: the superseded process is terminated, never
            // left running or allowed to publish stale data.
            controller.request("claude", 2)
            exitTimer.start()
        }
    }

    Timer {
        id: exitTimer
        interval: 1000
        onTriggered: Qt.quit()
    }
}
