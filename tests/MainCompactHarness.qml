import QtQuick
import QtQuick.Controls as QQC2
import "../contents/code/UsageModel.js" as UsageModel
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false
    property var controller: null
    property var firstSummary: null
    property var secondSummary: null

    function assert(condition, message) {
        if (!condition) {
            console.error("MainCompactHarness failure:", message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    function countProgressBars(item) {
        var n = 0
        if (item instanceof QQC2.ProgressBar) n++
        for (var i = 0; i < item.children.length; i++) n += countProgressBars(item.children[i])
        return n
    }

    Component.onCompleted: {
        controller = controllerComponent.createObject(root, {
            commandPath: "/tmp/codexbar",
            testMode: true
        })
        controller.requestRefresh()
        controller.completeForTest(controller.generation, JSON.stringify([
            { provider: "first", usage: { primary: { usedPercent: 75 }, secondary: { usedPercent: 80 } } },
            { provider: "second", usage: { primary: { usedPercent: 60 }, secondary: { usedPercent: 90 } } }
        ]), 0)

        var compact = UsageModel.selectCompact(controller.committedProviders)
        assert(compact.provider.provider === "second", "compact surface must use the global highest percentage")
        assert(compact.window.label === "Weekly", "compact surface must expose the selected window")

        var firstRep = UsageModel.selectRepresentative(controller.committedProviders[0].windows)
        assert(firstRep.label === "Session" && firstRep.usedPercent === 75,
               "first provider representative must be its own Session window")
        var secondRep = UsageModel.selectRepresentative(controller.committedProviders[1].windows)
        assert(secondRep.label === "Session" && secondRep.usedPercent === 60,
               "second provider representative must be its own Session window, not the global Weekly peak")

        firstSummary = summaryRowComponent.createObject(root, {
            providerData: controller.committedProviders[0],
            summary: true
        })
        secondSummary = summaryRowComponent.createObject(root, {
            providerData: controller.committedProviders[1],
            summary: true
        })
        assert(countProgressBars(firstSummary) === 1, "first summary row renders exactly one bar")
        assert(countProgressBars(secondSummary) === 1, "second summary row renders exactly one bar")

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

    Component {
        id: summaryRowComponent
        UsageUi.ProviderRow { }
    }
}
