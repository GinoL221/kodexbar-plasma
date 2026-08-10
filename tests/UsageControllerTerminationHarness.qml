import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root

    property string command: Qt.resolvedUrl("fixtures/codexbar-lifecycle-fixture.sh").toString().replace(/^file:\/\//, "")

    Component.onCompleted: {
        controller.requestRefresh()
        disconnectTimer.start()
    }

    UsageUi.UsageController {
        id: controller
        commandPath: root.command
        timeoutMs: 5000
    }

    Timer {
        id: disconnectTimer
        interval: 500
        onTriggered: {
            controller.destroy()
            exitTimer.start()
        }
    }

    Timer {
        id: exitTimer
        interval: 1000
        onTriggered: Qt.quit()
    }
}
