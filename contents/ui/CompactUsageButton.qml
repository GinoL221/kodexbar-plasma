import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

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

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "utilities-system-monitor"
            isMask: true
            color: Kirigami.Theme.textColor
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
        }

        PlasmaComponents.Label {
            text: root.usageText
            visible: text.length > 0
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
        }
    }
}
