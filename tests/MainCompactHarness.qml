import QtQuick
import QtQuick.Controls as QQC2
import "../contents/code/UsageModel.js" as UsageModel
import "../contents/code/ProviderCycle.js" as ProviderCycle
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
        if (!item) {
            return 0
        }
        var n = 0
        if (item instanceof QQC2.ProgressBar) {
            n++
        } else if ((item.objectName === "summaryUsageProgressBar" || item.objectName === "detailUsageProgressBar"
                    || item.objectName === "usageProgressBar") && item.visible) {
            n++
        }
        for (var i = 0; i < item.children.length; i++) {
            n += countProgressBars(item.children[i])
        }
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
        assert(countProgressBars(firstSummary) === 2, "first summary row renders two bars when Session and Weekly are both finite (Overview D10)")
        assert(countProgressBars(secondSummary) === 2, "second summary row renders two bars when Session and Weekly are both finite (Overview D10)")

        // Compact cycle verification
        var displayNameFn = function(id) {
            return id === "first" ? "First" : "Second"
        }
        var cycleTargets = ProviderCycle.buildCycleTargets(controller.committedProviders, displayNameFn)
        assert(cycleTargets.length === 3, "must have All + 2 providers")
        var cycled0 = ProviderCycle.resolveCycledUsage(cycleTargets, 0, "session", UsageModel.selectCompact, UsageModel.selectRepresentative, displayNameFn)
        assert(cycled0.isAll === true && cycled0.usedPercent === 90, "cycle index 0 must be All with global peak 90%")
        assert(cycled0.allSummaryText.indexOf("First: 75% (Session)") !== -1, "summary tooltip must list First")
        assert(cycled0.allSummaryText.indexOf("Second: 60% (Session)") !== -1, "summary tooltip must list Second")
        var cycled1 = ProviderCycle.resolveCycledUsage(cycleTargets, 1, "session", UsageModel.selectCompact, UsageModel.selectRepresentative, displayNameFn)
        assert(cycled1.isAll === false && cycled1.targetId === "first" && cycled1.usedPercent === 75, "cycle index 1 must be first provider with 75%")
        var cycled2 = ProviderCycle.resolveCycledUsage(cycleTargets, 2, "session", UsageModel.selectCompact, UsageModel.selectRepresentative, displayNameFn)
        assert(cycled2.isAll === false && cycled2.targetId === "second" && cycled2.usedPercent === 60, "cycle index 2 must be second provider with session 60%")

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
