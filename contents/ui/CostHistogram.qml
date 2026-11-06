pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var daily: []
    property string accentColor: ""

    readonly property var validDaily: Array.isArray(root.daily) ? root.daily : []
    readonly property bool hasBars: root.validDaily.length > 0
    readonly property color barFillColor: root.accentColor.length > 0
        ? root.accentColor
        : Kirigami.Theme.highlightColor

    readonly property real maxMetric: {
        var maxCost = 0
        var maxTokens = 0
        for (var i = 0; i < root.validDaily.length; i++) {
            var entry = root.validDaily[i]
            if (entry && typeof entry === "object") {
                if (typeof entry.totalCost === "number" && entry.totalCost > maxCost) {
                    maxCost = entry.totalCost
                }
                if (typeof entry.totalTokens === "number" && entry.totalTokens > maxTokens) {
                    maxTokens = entry.totalTokens
                }
            }
        }
        if (maxCost > 0) {
            return maxCost
        }
        return maxTokens > 0 ? maxTokens : 1
    }

    objectName: "costHistogram"
    visible: root.hasBars
    Layout.fillWidth: true
    implicitHeight: visible ? Kirigami.Units.gridUnit * 3 : 0
    Layout.preferredHeight: visible ? Kirigami.Units.gridUnit * 3 : 0

    RowLayout {
        anchors.fill: parent
        spacing: Math.max(2, Math.round(Kirigami.Units.smallSpacing / 2))

        Repeater {
            model: root.validDaily

            delegate: Item {
                id: barDelegate
                required property var modelData

                readonly property real metricValue: {
                    if (barDelegate.modelData && typeof barDelegate.modelData === "object") {
                        if (typeof barDelegate.modelData.totalCost === "number" && barDelegate.modelData.totalCost > 0) {
                            return barDelegate.modelData.totalCost
                        }
                        if (typeof barDelegate.modelData.totalTokens === "number" && barDelegate.modelData.totalTokens > 0) {
                            return barDelegate.modelData.totalTokens
                        }
                    }
                    return 0
                }
                readonly property real ratio: Math.max(0, Math.min(1, barDelegate.metricValue / root.maxMetric))

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 2

                Rectangle {
                    objectName: "costHistogramBar"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: barDelegate.ratio > 0
                        ? Math.max(4, Math.round(parent.height * barDelegate.ratio))
                        : 2
                    radius: 2
                    color: barDelegate.ratio > 0 ? root.barFillColor : Kirigami.Theme.disabledTextColor
                    opacity: barDelegate.ratio > 0 ? 0.85 : 0.28
                }
            }
        }
    }
}
