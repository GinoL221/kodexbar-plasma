import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

import "../code/ProviderIcons.js" as ProviderIcons

QQC2.ToolButton {
    id: root

    property string usageText: ""
    property string providerId: ""
    property string accentColor: ""
    property bool tintPanelIcon: true

    readonly property string providerKey: ProviderIcons.key(root.providerId)
    readonly property url effectiveIconSource: root.providerKey.length > 0
        ? Qt.resolvedUrl("../icons/providers/" + root.providerKey + ".svg")
        : Qt.resolvedUrl("../icons/kodexbar-monochrome.svg")
    readonly property color effectiveIconColor: (root.tintPanelIcon && root.accentColor.length > 0)
        ? root.accentColor
        : Kirigami.Theme.textColor

    signal scrolled(int delta)

    function simulateScroll(delta) {
        root.scrolled(delta)
    }

    text: ""
    icon.name: ""
    display: QQC2.AbstractButton.TextBesideIcon
    focusPolicy: Qt.StrongFocus

    MouseArea {
        anchors.fill: parent
        z: 10
        acceptedButtons: Qt.RightButton
        onPressed: function(mouse) {
            mouse.accepted = false
        }
        onWheel: function(wheel) {
            var rawDelta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
            if (rawDelta > 0) {
                root.scrolled(-1)
                wheel.accepted = true
            } else if (rawDelta < 0) {
                root.scrolled(1)
                wheel.accepted = true
            }
        }
    }
    Accessible.name: typeof i18n === "function"
        ? i18n("KodexBar usage: %1. Open details.", usageText)
        : "KodexBar usage: " + usageText + ". Open details."
    Accessible.description: typeof i18n === "function"
        ? i18n("Open or close KodexBar usage details")
        : "Open or close KodexBar usage details"
    Layout.minimumWidth: contentItem.implicitWidth + Kirigami.Units.smallSpacing * 2
    Layout.minimumHeight: Kirigami.Units.iconSizes.smallMedium

    contentItem: Item {
        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium

        ProviderIcon {
            id: compactIcon
            objectName: "compactProviderIcon"
            source: root.effectiveIconSource
            color: root.effectiveIconColor
            implicitWidth: Kirigami.Units.iconSizes.smallMedium
            implicitHeight: Kirigami.Units.iconSizes.smallMedium
            anchors.centerIn: parent
        }
    }
}
