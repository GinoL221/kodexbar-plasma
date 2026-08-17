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
    // Optional brand accent (#rrggbb). Empty → Kirigami.Theme.highlightColor.
    property string accentColor: ""

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

    readonly property color barFillColor: root.accentColor.length > 0
        ? root.accentColor
        : Kirigami.Theme.highlightColor

    // Fixed summary columns so Session/Weekly/Monthly and 1%/100% share one
    // track length. Both hug their own worst-case text metrics -- earlier
    // gridUnit*5/*6 floors were wider than the text itself (label: 90px vs
    // ~62px, percent: 108px vs ~80px), leaving a large visual gap on both
    // sides of the bar. The small smallSpacing buffer guards against
    // TextMetrics under-measuring by a sub-pixel versus the live Breeze
    // font actually used to paint the Text item -- an exact-fit column
    // clipped "Monthly" to "Mont..." in a live Breeze Dark session even
    // though the same text fit fine against this offscreen test font.
    readonly property int summaryLabelColumnWidth: Math.ceil(labelColumnMetrics.width) + Kirigami.Units.smallSpacing
    readonly property int summaryPercentColumnWidth: Math.ceil(percentColumnMetrics.width) + Kirigami.Units.smallSpacing

    TextMetrics {
        id: labelColumnMetrics
        font: windowLabel.font
        // "Monthly" is the longest of the standard Session/Weekly/Monthly
        // window labels; longer CLI-supplied labels still elide safely.
        text: Translation.translate("Monthly", [], typeof i18n === "function" ? i18n : null)
    }

    TextMetrics {
        id: percentColumnMetrics
        font: summaryPercentageLabel.font
        text: Translation.translate("%1% used", [100], typeof i18n === "function" ? i18n : null)
    }

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
            font.weight: root.summary ? Font.Normal : Font.Medium
            font.pointSize: root.summary
                ? Kirigami.Theme.smallFont.pointSize
                : Kirigami.Theme.defaultFont.pointSize
            elide: Text.ElideRight
            // minimumWidth stays 0 (not the fixed column width) so this label
            // can shrink below its aligned column when the row is narrower
            // than label+bar+percent combined -- locking min==max here left
            // RowLayout unable to compress at constrained widths, overflowing
            // the row instead of shrinking (recursive-rearrange abort).
            Layout.minimumWidth: 0
            Layout.maximumWidth: root.summary ? root.summaryLabelColumnWidth : -1
            // fillWidth (not just non-summary) so a non-fillWidth item isn't
            // pinned to preferredWidth by Qt Quick Layouts' Fixed size policy
            // -- summary mode still can't grow past summaryLabelColumnWidth
            // (maximumWidth above), but it can now shrink under it.
            Layout.fillWidth: true
            Layout.preferredWidth: root.summary ? root.summaryLabelColumnWidth : -1
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
                color: root.barFillColor
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
            font.weight: Font.Normal
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            // Same shrink allowance as windowLabel above -- fixed min==max
            // overflowed the row at constrained widths instead of shrinking.
            // fillWidth: true is needed for the same reason as windowLabel
            // (Fixed size policy otherwise pins this to preferredWidth).
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: root.summary ? root.summaryPercentColumnWidth : implicitWidth
            Layout.maximumWidth: root.summary ? root.summaryPercentColumnWidth : implicitWidth
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
                color: root.barFillColor
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
