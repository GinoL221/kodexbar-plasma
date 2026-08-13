import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "../code/Translation.js" as Translation

ColumnLayout {
    id: root

    property var windowData: ({})
    property bool compact: false
    property bool summary: false

    readonly property bool hasFinitePercent: typeof root.windowData.usedPercent === "number" && isFinite(root.windowData.usedPercent)
    readonly property string resetText: root.windowData.resetsAt !== null && root.windowData.resetsAt !== undefined ? String(root.windowData.resetsAt) : ""
    readonly property string resetDescriptionText: root.windowData.resetDescription !== null && root.windowData.resetDescription !== undefined ? String(root.windowData.resetDescription) : ""

    property var progressBar: progressLoader.item
    property alias percentageLabel: percentageLabel
    property alias resetsAtLabel: resetsAtLabel
    property alias resetDescriptionLabel: resetDescriptionLabel

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing / 2
    function valueText(value) {
        return value === null || value === undefined ? "" : String(value)
    }

    Accessible.name: Translation.translate("%1 window", [root.valueText(root.windowData.label)],
        typeof i18n === "function" ? i18n : null)
    Accessible.description: {
        var details = []
        if (root.hasFinitePercent) {
            details.push(Translation.translate("%1% used", [root.windowData.usedPercent],
                typeof i18n === "function" ? i18n : null))
        }
        if (root.resetText.length > 0) {
            details.push(Translation.translate("Reset: %1", [root.resetText],
                typeof i18n === "function" ? i18n : null))
        }
        if (root.resetDescriptionText.length > 0) {
            details.push(root.resetDescriptionText)
        }
        return details.join(", ")
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                id: windowLabel
                text: root.valueText(root.windowData.label)
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

        PlasmaComponents.Label {
            id: percentageLabel
            visible: root.hasFinitePercent
            text: visible ? Translation.translate("%1% used", [root.windowData.usedPercent],
                typeof i18n === "function" ? i18n : null) : ""
            color: Kirigami.Theme.textColor
            elide: Text.ElideRight
            Layout.maximumWidth: Kirigami.Units.gridUnit * 9
        }
    }

    Loader {
        id: progressLoader
        sourceComponent: root.hasFinitePercent && !root.compact ? progressComponent : inactiveProgressComponent
        active: true
        Layout.fillWidth: true
    }

    Component {
        id: progressComponent

        QQC2.ProgressBar {
            from: 0
            to: 100
            value: root.windowData.usedPercent
            Layout.fillWidth: true
        }
    }

    Component {
        id: inactiveProgressComponent

        Item {
            visible: false
        }
    }

    PlasmaComponents.Label {
        id: resetsAtLabel
        visible: root.resetText.length > 0 && !root.summary
        text: visible ? Translation.translate("Reset: %1", [root.resetText], typeof i18n === "function" ? i18n : null) : ""
        color: Kirigami.Theme.disabledTextColor
        elide: root.compact ? Text.ElideRight : Text.ElideNone
        wrapMode: root.compact ? Text.NoWrap : Text.Wrap
        Layout.fillWidth: true
    }

    PlasmaComponents.Label {
        id: resetDescriptionLabel
        visible: root.resetDescriptionText.length > 0 && !root.summary
        text: visible ? root.resetDescriptionText : ""
        color: Kirigami.Theme.disabledTextColor
        elide: root.compact ? Text.ElideRight : Text.ElideNone
        wrapMode: root.compact ? Text.NoWrap : Text.Wrap
        Layout.fillWidth: true
    }
}
