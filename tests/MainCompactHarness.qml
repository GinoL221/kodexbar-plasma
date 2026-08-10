import QtQuick
import "../contents/code/UsageModel.js" as UsageModel
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("MainCompactHarness failure:", message)
            assertionFailed = true
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        var controller = controllerComponent.createObject(root, {
            commandPath: "/tmp/codexbar",
            testMode: true
        })
        controller.requestRefresh()
        controller.completeForTest(controller.generation, JSON.stringify([
            { provider: "first", usage: { primary: { usedPercent: 75 } } },
            { provider: "second", usage: { primary: { usedPercent: 75 }, secondary: { usedPercent: 90 } } }
        ]), 0)

        var compact = UsageModel.selectCompact(controller.committedProviders)
        assert(compact.provider.provider === "second", "compact surface must use the global highest percentage")
        assert(compact.window.label === "Weekly", "compact surface must expose the selected window")

        controller.requestRefresh()
        controller.timeoutForTest(controller.generation)
        assert(controller.phase === "error", "a failed refresh must expose the error state")
        assert(controller.committedProviders.length === 2, "a refresh failure must not clear the committed snapshot")
        finish()
    }

    Component {
        id: controllerComponent
        UsageUi.UsageController { }
    }
}
