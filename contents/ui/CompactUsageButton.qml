import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.ToolButton {
    id: root

    property string usageText: ""

    text: ""
    icon.name: ""
    display: QQC2.AbstractButton.TextBesideIcon
    focusPolicy: Qt.StrongFocus
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

        Kirigami.Icon {
            id: compactIcon
            source: Qt.resolvedUrl("../icons/kodexbar-monochrome.svg")
            isMask: true
            color: Kirigami.Theme.textColor
            implicitWidth: Kirigami.Units.iconSizes.smallMedium
            implicitHeight: Kirigami.Units.iconSizes.smallMedium
            anchors.centerIn: parent
        }
    }
}
