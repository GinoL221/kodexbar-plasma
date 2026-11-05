import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false
    property var controller: null
    property var dispatchedList: []

    function assert(condition, message) {
        if (!condition) {
            console.error("NotificationControllerHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        controller = controllerComponent.createObject(root, {
            testMode: true
        })
        controller.notificationDispatched.connect(function(title, text, iconName, urgency) {
            root.dispatchedList.push({ title: title, text: text, iconName: iconName, urgency: urgency })
        })

        // 1. Initial healthy state -> 0 dispatched
        controller.checkAndNotify([
            { provider: "claude", windows: [{ key: "primary", label: "Session", usedPercent: 40 }] }
        ], [], 0, 0)
        assert(root.dispatchedList.length === 0, "healthy usage must emit no notifications")

        // 2. Escalation to 95% (critical) -> 1 notification
        controller.checkAndNotify([
            { provider: "claude", windows: [{ key: "primary", label: "Session", usedPercent: 95, resetDescription: "in 1 hour" }] }
        ], [], 0, 0)
        assert(root.dispatchedList.length === 1, "escalation to 95% must dispatch 1 notification")
        assert(root.dispatchedList[0].title.indexOf("Claude") !== -1, "notification must name Claude")
        assert(root.dispatchedList[0].title.indexOf("90%") !== -1, "notification must specify 90% threshold")

        // 3. Steady poll at 95% -> still 1 notification (no repeat spam)
        controller.checkAndNotify([
            { provider: "claude", windows: [{ key: "primary", label: "Session", usedPercent: 95 }] }
        ], [], 0, 0)
        assert(root.dispatchedList.length === 1, "steady poll must not emit duplicate notification")

        // 4. Escalation to 100% (exhausted) -> 2nd notification
        controller.checkAndNotify([
            { provider: "claude", windows: [{ key: "primary", label: "Session", usedPercent: 100 }] }
        ], [], 0, 0)
        assert(root.dispatchedList.length === 2, "reaching 100% must dispatch exhausted notification")
        assert(root.dispatchedList[1].title.indexOf("exhausted") !== -1, "notification must announce exhausted")

        // 5. Rate limit strike 1 -> 3rd notification
        controller.checkAndNotify([
            { provider: "claude", windows: [{ key: "primary", label: "Session", usedPercent: 100 }] }
        ], ["claude"], 1, 2)
        assert(root.dispatchedList.length === 3, "rate limit strike 1 must dispatch rate limit alert")
        assert(root.dispatchedList[2].title.indexOf("Rate limit") !== -1, "notification must announce rate limit")

        // 6. Disabled notifications switch
        controller.notificationsEnabled = false
        controller.checkAndNotify([
            { provider: "codex", windows: [{ key: "primary", label: "Session", usedPercent: 100 }] }
        ], [], 0, 0)
        assert(root.dispatchedList.length === 3, "disabled controller must emit no notifications")

        finish()
    }

    Component {
        id: controllerComponent
        UsageUi.NotificationController { }
    }
}
