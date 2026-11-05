pragma ComponentBehavior: Bound

import QtQuick

import "../code/NotificationPolicy.js" as NotificationPolicy
import "../code/ProviderIcons.js" as ProviderIcons

Item {
    id: root

    property bool notificationsEnabled: true
    property var activeNotification: null
    property var notificationHistory: []
    property var trackingState: ({})
    property bool testMode: false

    readonly property int urgencyNormal: 50
    readonly property int urgencyCritical: 90

    signal notificationDispatched(string title, string text, string iconName, string urgency)

    function providerDisplayName(id) {
        return ProviderIcons.displayName(id)
    }

    function createNotification() {
        return Qt.createQmlObject(
            "import QtQuick; import org.kde.notification as KNotification; KNotification.Notification { componentName: \"plasma_workspace\"; eventId: \"notification\"; autoDelete: true }",
            root,
            "dynamicNotification"
        )
    }

    function prepareNotification(notification, item) {
        if (!notification || !item || typeof item !== "object") {
            return false
        }
        var title = item.title || ""
        if (title.indexOf("KodexBar") !== 0) {
            title = "KodexBar: " + title
        }
        var iconName = item.iconName || "dialog-information"
        var urgency = item.urgency || "normal"
        notification.title = title
        notification.text = item.text || ""
        notification.urgency = urgency === "critical"
            ? root.urgencyCritical
            : root.urgencyNormal
        if (iconName.length > 0) {
            notification.iconName = iconName
        }
        return true
    }

    function dispatch(item) {
        if (!item || typeof item !== "object") {
            return false
        }
        var title = item.title || ""
        if (title.indexOf("KodexBar") !== 0) {
            title = "KodexBar: " + title
        }
        var text = item.text || ""
        var iconName = item.iconName || "dialog-information"
        var urgency = item.urgency || "normal"

        if (notificationHistory.length >= 50) {
            notificationHistory.shift()
        }
        notificationHistory.push(item)
        notificationDispatched(title, text, iconName, urgency)

        if (testMode) {
            return true
        }

        try {
            root.activeNotification = root.createNotification()
            if (root.prepareNotification(root.activeNotification, item)) {
                root.activeNotification.sendEvent()
                return true
            }
        } catch (_ignored) {
            return false
        }
        return false
    }

    function checkAndNotify(providers, rateLimitedIds, consecutiveRateLimits, retryMinutes) {
        if (!root.notificationsEnabled) {
            return
        }
        var evaluation = NotificationPolicy.evaluateTransitions(
            root.trackingState,
            providers,
            rateLimitedIds,
            consecutiveRateLimits,
            retryMinutes,
            root.providerDisplayName
        )
        root.trackingState = evaluation.nextState

        var list = evaluation.notifications || []
        for (var i = 0; i < list.length; i++) {
            root.dispatch(list[i])
        }
    }
}
