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

    signal notificationDispatched(string title, string text, string iconName, string urgency)

    function providerDisplayName(id) {
        return ProviderIcons.displayName(id)
    }

    function dispatch(item) {
        if (!item || typeof item !== "object") {
            return false
        }
        var title = item.title || ""
        var text = item.text || ""
        var iconName = item.iconName || "dialog-information"
        var urgency = item.urgency || "normal"

        notificationHistory.push(item)
        notificationDispatched(title, text, iconName, urgency)

        if (testMode) {
            return true
        }

        try {
            root.activeNotification = Qt.createQmlObject(
                "import QtQuick; import org.kde.notification as KNotification; KNotification.Notification { componentName: \"org.kde.plasma.kodexbar.plasma\"; eventId: \"warning\" }",
                root,
                "dynamicNotification"
            )
            if (root.activeNotification) {
                root.activeNotification.title = title
                root.activeNotification.text = text
                if (iconName.length > 0) {
                    root.activeNotification.iconName = iconName
                }
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
