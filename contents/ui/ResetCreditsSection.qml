pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "../code/ProviderDetails.js" as ProviderDetailsLogic
import "../code/Translation.js" as Translation

// Reset-credit availability, shown only when a positive, structurally valid
// inventory exists. The expiry list is an expandable, keyboard-reachable
// disclosure with no redeem/mutation action, mirroring ProviderDetails.qml's
// existing accessible expand/collapse pattern.
ColumnLayout {
    id: root

    property var providerData: ({})
    property bool expanded: false

    readonly property var resetCredits: ProviderDetailsLogic.validResetCredits(root.providerData)
    readonly property alias disclosureButton: disclosure

    function translate(text) {
        return typeof i18n === "function" ? i18n(text) : text
    }

    visible: root.resetCredits !== null
    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.Label {
        id: resetAvailableLabel
        objectName: "resetAvailableLabel"
        visible: root.resetCredits !== null
        text: root.resetCredits !== null
            ? Translation.translate("Reset credits available: %1", [root.resetCredits.availableCount],
                typeof i18n === "function" ? i18n : null)
            : ""
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }

    QQC2.ToolButton {
        id: disclosure

        visible: root.resetCredits !== null && root.resetCredits.credits.length > 0
        checkable: true
        checked: root.expanded
        text: checked
            ? root.translate("Hide reset credit expirations")
            : root.translate("Show reset credit expirations")
        icon.name: checked ? "arrow-down" : "arrow-right"
        display: QQC2.AbstractButton.TextBesideIcon
        focusPolicy: Qt.StrongFocus
        Accessible.name: text
        Accessible.description: checked
            ? root.translate("Collapse reset credit expirations")
            : root.translate("Expand reset credit expirations")
        onToggled: root.expanded = checked
        Keys.onReturnPressed: function(event) {
            root.expanded = !root.expanded
            event.accepted = true
        }
        Keys.onSpacePressed: function(event) {
            root.expanded = !root.expanded
            event.accepted = true
        }
    }

    Repeater {
        model: root.expanded && root.resetCredits !== null ? root.resetCredits.credits : []

        delegate: PlasmaComponents.Label {
            id: expiryDelegate
            required property var modelData

            Layout.fillWidth: true
            Layout.minimumWidth: 0
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.disabledTextColor
            text: Translation.translate("%1 credits expire %2", [expiryDelegate.modelData.amount, expiryDelegate.modelData.expiresAt],
                typeof i18n === "function" ? i18n : null)
        }
    }
}
