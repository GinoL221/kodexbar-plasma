pragma ComponentBehavior: Bound

import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false
    property var switcher: null
    property var disabledSwitcher: null

    function assert(condition, message) {
        if (!condition) {
            console.error("AccountSwitchControllerHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component {
        id: switchComponent
        UsageUi.AccountSwitchController { }
    }

    Component.onCompleted: {
        disabledSwitcher = switchComponent.createObject(root, {
            commandPath: "",
            testMode: true
        })
        assert(!disabledSwitcher.available, "unset commandPath in testMode must keep available false")
        disabledSwitcher.switchNext()
        assert(!disabledSwitcher.switching, "unavailable switcher must ignore switchNext()")
        disabledSwitcher.destroy()

        var succeededCount = 0
        var failedMessages = []
        switcher = switchComponent.createObject(root, {
            commandPath: "/tmp/bin/cpa-antigravity",
            testMode: true,
            timeoutMs: 5000
        })
        switcher.switchSucceeded.connect(function() { succeededCount += 1 })
        switcher.switchFailed.connect(function(msg) { failedMessages.push(msg) })

        assert(switcher.available, "valid absolute commandPath in testMode must mark switcher available")
        switcher.switchNext()
        assert(switcher.switching, "switchNext() must mark switching active")
        assert(switcher.activeSource === "'/tmp/bin/cpa-antigravity'",
               "activeSource must shell-quote only the validated cpa-antigravity path")

        // Duplicate call while active must be ignored
        switcher.switchNext()
        switcher.completeSwitchForTest(0)
        assert(!switcher.switching, "zero exit must clear switching state")
        assert(succeededCount === 1 && failedMessages.length === 0,
               "zero exit must emit switchSucceeded")

        switcher.switchNext()
        switcher.completeSwitchForTest(1)
        assert(!switcher.switching, "non-zero exit must clear switching state")
        assert(failedMessages.length === 1 && succeededCount === 1,
               "non-zero exit must emit switchFailed")

        switcher.switchNext()
        switcher.timeoutForTest()
        assert(!switcher.switching, "timeout must clear switching state")
        assert(failedMessages.length === 2,
               "timeout must emit switchFailed")

        switcher.destroy()
        finish()
    }
}
