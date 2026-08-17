pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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
    readonly property bool showBar: root.hasFinitePercent && !root.compact
    readonly property real barRatio: {
        if (!root.hasFinitePercent) {
            return 0
        }
        return Math.max(0, Math.min(1, root.windowData.usedPercent / 100))
    }

    // Summary uses the in-line bar; detail uses the full-width bar below the title.
    // Always point at a real Item (never null) for harness geometry handles.
    // Geometry handle: summary mid-row bar, or detail host (Layout-sized).
    property var progressBar: root.summary ? summaryBar : detailBarHost
    property alias windowLabel: windowLabel
    property var percentageLabel: root.summary ? summaryPercentageLabel : bandPercentageLabel
    property alias resetsAtLabel: resetsAtLabel
    property alias resetDescriptionLabel: resetDescriptionLabel

    Layout.fillWidth: true
    // Overview: tight single-line rows. Detail: air between title / bar / band.
    spacing: root.summary
        ? Math.max(2, Math.round(Kirigami.Units.smallSpacing / 2))
        : Kirigami.Units.smallSpacing

    readonly property int barHeight: root.summary
        ? Math.max(4, Math.round(Kirigami.Units.smallSpacing * 0.75))
        : Math.max(8, Math.round(Kirigami.Units.smallSpacing * 1.1))

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

    // Overview (summary): single line — label | bar | percent.
    // Detail: title only on this row; bar and band follow below.
    RowLayout {
        id: titleRow
        // Explicit width tracks the window row so summary bars grow when the
        // parent is resized outside a layout (harness + popup). This is a
        // known qmllint Quick.layout-positioning diagnostic (raw `width:`
        // mixed with Layout.fillWidth on the same item) -- tried replacing
        // it with Layout.preferredWidth: root.width instead, which silences
        // the lint warning, but that breaks tests/ProviderRowHarness.qml's
        // synchronous resize-then-assert pattern (Layout.preferredWidth
        // reflows through the layout engine, not synchronously like a raw
        // width binding). Kept as-is; tests over lint purity here.
        width: root.width
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            id: windowLabel
            text: root.valueText(root.windowData.label)
            font.weight: root.summary ? Font.Normal : Font.DemiBold
            font.pointSize: root.summary
                ? Kirigami.Theme.smallFont.pointSize
                : Kirigami.Theme.defaultFont.pointSize * 1.05
            elide: Text.ElideRight
            Layout.minimumWidth: 0
            Layout.maximumWidth: root.summary ? Kirigami.Units.gridUnit * 6 : -1
            Layout.fillWidth: !root.summary
            Layout.preferredWidth: root.summary ? Math.min(implicitWidth, Kirigami.Units.gridUnit * 5) : -1
            Layout.alignment: Qt.AlignVCenter
            Layout.bottomMargin: root.summary ? 0 : Math.round(Kirigami.Units.smallSpacing / 2)
        }

        Item {
            id: summaryBar
            objectName: "summaryUsageProgressBar"
            visible: root.summary && root.showBar
            Layout.fillWidth: root.summary && root.showBar
            Layout.minimumWidth: 0
            Layout.preferredWidth: root.summary && root.showBar ? Kirigami.Units.gridUnit * 3 : 0
            Layout.preferredHeight: visible ? root.barHeight : 0
            Layout.maximumHeight: visible ? root.barHeight : 0
            Layout.alignment: Qt.AlignVCenter
            readonly property real value: root.hasFinitePercent ? root.windowData.usedPercent : 0
            Accessible.role: Accessible.ProgressBar
            Accessible.name: Translation.translate("%1% used", [root.windowData.usedPercent],
                typeof i18n === "function" ? i18n : null)

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Kirigami.Theme.disabledTextColor
                opacity: 0.28
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.round(parent.width * root.barRatio)
                radius: height / 2
                color: Kirigami.Theme.highlightColor
            }
        }

        Item {
            visible: !root.summary
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredHeight: 1
        }

        PlasmaComponents.Label {
            id: summaryPercentageLabel
            objectName: "summaryPercentageLabel"
            visible: root.summary && root.hasFinitePercent
            text: visible ? Translation.translate("%1% used", [root.windowData.usedPercent],
                typeof i18n === "function" ? i18n : null) : ""
            color: Kirigami.Theme.disabledTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            elide: Text.ElideRight
            Layout.minimumWidth: 0
            Layout.preferredWidth: implicitWidth
            Layout.maximumWidth: implicitWidth
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Detail-only full-width progress bar.
    // Host takes Layout width; inner bar fills the host (avoids zero-size
    // circular width: root.width bindings inside ColumnLayout).
    Item {
        id: detailBarHost
        visible: !root.summary && root.showBar
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: visible ? root.barHeight : 0
        Layout.minimumHeight: visible ? root.barHeight : 0
        Layout.maximumHeight: visible ? root.barHeight : 0
        Layout.topMargin: Kirigami.Units.smallSpacing
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        implicitHeight: root.barHeight

        Item {
            id: detailBar
            objectName: "detailUsageProgressBar"
            anchors.fill: parent
            readonly property real value: root.hasFinitePercent ? root.windowData.usedPercent : 0
            Accessible.role: Accessible.ProgressBar
            Accessible.name: Translation.translate("%1% used", [root.windowData.usedPercent],
                typeof i18n === "function" ? i18n : null)

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Kirigami.Theme.disabledTextColor
                opacity: 0.28
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width > 0 ? Math.round(parent.width * root.barRatio) : 0
                radius: height / 2
                color: Kirigami.Theme.highlightColor
            }
        }
    }

    // Detail-only trailing band: percent left, reset right.
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        visible: !root.summary
        Layout.topMargin: Math.round(Kirigami.Units.smallSpacing / 2)

        PlasmaComponents.Label {
            id: bandPercentageLabel
            objectName: "bandPercentageLabel"
            visible: root.hasFinitePercent && !root.summary
            text: visible ? Translation.translate("%1% used", [root.windowData.usedPercent],
                typeof i18n === "function" ? i18n : null) : ""
            color: Kirigami.Theme.textColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            Layout.minimumWidth: implicitWidth
            Layout.maximumWidth: implicitWidth
        }

        Item {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredHeight: 1
        }

        PlasmaComponents.Label {
            id: resetsAtLabel
            visible: root.resetText.length > 0 && root.resetDescriptionText.length === 0 && !root.summary
            text: visible ? Translation.translate("Reset: %1", [root.resetText], typeof i18n === "function" ? i18n : null) : ""
            color: Kirigami.Theme.disabledTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            Layout.minimumWidth: 0
            Layout.maximumWidth: root.width > 0 ? root.width * 0.55 : Kirigami.Units.gridUnit * 12
            horizontalAlignment: Text.AlignRight
        }

        PlasmaComponents.Label {
            id: resetDescriptionLabel
            visible: root.resetDescriptionText.length > 0 && !root.summary
            text: visible ? root.resetDescriptionText : ""
            color: Kirigami.Theme.disabledTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            Layout.minimumWidth: 0
            Layout.maximumWidth: root.width > 0 ? root.width * 0.55 : Kirigami.Units.gridUnit * 12
            horizontalAlignment: Text.AlignRight
        }
    }

    PlasmaComponents.Label {
        id: paceSummaryLabel
        objectName: "paceSummaryLabel"
        visible: root.paceSummary.length > 0 && !root.summary
        text: visible ? root.paceSummary : ""
        color: Kirigami.Theme.disabledTextColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.topMargin: Math.round(Kirigami.Units.smallSpacing / 2)
    }
}
