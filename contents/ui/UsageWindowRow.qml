pragma ComponentBehavior: Bound

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
    // Selected-provider-only pace summary text (e.g. "42% in deficit |
    // Expected 18% used"), attached by the caller when this window's label
    // matches a valid CLI-supplied pace.primary/secondary/tertiary entry.
    property string paceSummary: ""

    readonly property bool hasFinitePercent: typeof root.windowData.usedPercent === "number" && isFinite(root.windowData.usedPercent)
    readonly property string resetText: root.windowData.resetsAt !== null && root.windowData.resetsAt !== undefined ? String(root.windowData.resetsAt) : ""
    readonly property string resetDescriptionText: root.windowData.resetDescription !== null && root.windowData.resetDescription !== undefined ? String(root.windowData.resetDescription) : ""

    property var progressBar: progressLoader.item
    property alias windowLabel: windowLabel
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
        if (root.paceSummary.length > 0) {
            details.push(root.paceSummary)
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
            Layout.minimumWidth: 0
            Layout.preferredWidth: Math.min(implicitWidth, Kirigami.Units.gridUnit * 4)
            Layout.maximumWidth: Kirigami.Units.gridUnit * 4
            Layout.fillWidth: true
            Layout.horizontalStretchFactor: 0
        }

        Loader {
            id: progressLoader
            sourceComponent: root.hasFinitePercent && !root.compact ? progressComponent : inactiveProgressComponent
            active: true
            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 2
            Layout.horizontalStretchFactor: 1
        }

        PlasmaComponents.Label {
            id: percentageLabel
            visible: root.hasFinitePercent
            text: visible ? Translation.translate("%1% used", [root.windowData.usedPercent],
                typeof i18n === "function" ? i18n : null) : ""
            color: Kirigami.Theme.textColor
            Layout.minimumWidth: implicitWidth
            Layout.maximumWidth: implicitWidth
        }
    }

    Component {
        id: progressComponent

        QQC2.ProgressBar {
            implicitWidth: Kirigami.Units.gridUnit * 3
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

    PlasmaComponents.Label {
        id: paceSummaryLabel
        objectName: "paceSummaryLabel"
        visible: root.paceSummary.length > 0 && !root.summary
        text: visible ? root.paceSummary : ""
        color: Kirigami.Theme.disabledTextColor
        elide: root.compact ? Text.ElideRight : Text.ElideNone
        wrapMode: root.compact ? Text.NoWrap : Text.Wrap
        Layout.fillWidth: true
    }
}
