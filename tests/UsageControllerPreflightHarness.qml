import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false
    property var controller: null

    function assert(condition, message) {
        if (!condition) {
            console.error("UsageControllerPreflightHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        controller = controllerComponent.createObject(root, {
            commandPath: "/definitely/missing/codexbar",
            testMode: true
        })

        controller.discoveryOutputForTest = ""
        controller.setPathExecutableForTest(false)
        controller.requestRefresh()
        assert(controller.phase === "error", "missing paths must fail before a CLI request starts")
        assert(controller.activeRequestCount === 0, "missing paths must not create a CLI request")
        assert(controller.configurationRequired,
               "missing paths must require manual configuration after discovery fails")

        controller.commandPath = "/dev/null"
        controller.requestRefresh()
        assert(controller.phase === "error", "non-executable paths must fail before a CLI request starts")
        assert(controller.activeRequestCount === 0, "non-executable paths must not create a CLI request")
        finish()
    }

    Component {
        id: controllerComponent

        UsageUi.UsageController { }
    }
}
