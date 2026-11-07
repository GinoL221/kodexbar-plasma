pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "../code/Translation.js" as Translation

// Optional local token-cost estimate for the selected provider. `snapshot` is
// a validated CostModel.normalize() result (or null); this component never
// requests or computes cost itself, and stays absent without a snapshot.
ColumnLayout {
    id: root

    property var snapshot: null
    property string languagePreference: "auto"
    property string accentColor: ""

    readonly property bool hasSnapshot: root.snapshot !== null && root.snapshot !== undefined
    readonly property var dailyEntries: root.hasSnapshot && Array.isArray(root.snapshot.daily) ? root.snapshot.daily : []
    readonly property string primaryModelText: root.hasSnapshot && typeof root.snapshot.primaryModel === "string" ? root.snapshot.primaryModel : ""

    visible: root.hasSnapshot
    Layout.fillWidth: true
    Layout.topMargin: Kirigami.Units.smallSpacing
    spacing: Kirigami.Units.smallSpacing

    function formatUsd(value) {
        var rounded = Math.round(value * 100) / 100
        var negative = rounded < 0
        var fixed = Math.abs(rounded).toFixed(2)
        var parts = fixed.split(".")
        var grouped = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ".")
        return (negative ? "-" : "") + grouped + "," + parts[1]
    }

    function formatTokensAbbreviated(value) {
        var rounded = Math.round(value)
        var negative = rounded < 0
        var absValue = Math.abs(rounded)

        var suffix = ""
        var divisor = 1
        if (absValue >= 1000000000) {
            suffix = "B"
            divisor = 1000000000
        } else if (absValue >= 1000000) {
            suffix = "M"
            divisor = 1000000
        } else if (absValue >= 1000) {
            suffix = "K"
            divisor = 1000
        }

        if (suffix === "") {
            return (negative ? "-" : "") + String(absValue)
        }

        var fixed = (absValue / divisor).toFixed(1)
        var parts = fixed.split(".")
        return (negative ? "-" : "") + parts[0] + "," + parts[1] + suffix
    }

    PlasmaComponents.Label {
        id: costLabel
        objectName: "costLabel"
        visible: root.hasSnapshot
        text: Translation.translate("Cost", [], typeof i18n === "function" ? i18n : null, root.languagePreference)
        font.weight: Font.Medium
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }

    GridLayout {
        id: costGrid
        columns: 2
        Layout.fillWidth: true
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        // Row 1, Col 1: Today Cost
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 2

            PlasmaComponents.Label {
                text: Translation.translate("Today", [], typeof i18n === "function" ? i18n : null, root.languagePreference)
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                id: costSessionLabel
                objectName: "costSessionLabel"
                visible: root.hasSnapshot
                text: root.hasSnapshot ? "$" + root.formatUsd(root.snapshot.sessionCostUSD) : ""
                font.weight: Font.Bold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
        }

        // Row 1, Col 2: Last 30 Days Cost
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 2

            PlasmaComponents.Label {
                text: Translation.translate("Last 30 days cost", [], typeof i18n === "function" ? i18n : null, root.languagePreference)
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                id: costLast30DaysLabel
                objectName: "costLast30DaysLabel"
                visible: root.hasSnapshot
                text: root.hasSnapshot ? "$" + root.formatUsd(root.snapshot.last30DaysCostUSD) : ""
                font.weight: Font.Bold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
        }

        // Row 2, Col 1: Last 30 Days Tokens
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 2

            PlasmaComponents.Label {
                text: Translation.translate("Last 30 days tokens", [], typeof i18n === "function" ? i18n : null, root.languagePreference)
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                id: costLast30DaysTokensLabel
                objectName: "costLast30DaysTokensLabel"
                visible: root.hasSnapshot
                text: root.hasSnapshot ? root.formatTokensAbbreviated(root.snapshot.last30DaysTokens) : ""
                font.weight: Font.Bold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
        }

        // Row 2, Col 2: Recent Tokens
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 2

            PlasmaComponents.Label {
                text: Translation.translate("Recent tokens", [], typeof i18n === "function" ? i18n : null, root.languagePreference)
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                id: costSessionTokensLabel
                objectName: "costSessionTokensLabel"
                visible: root.hasSnapshot
                text: root.hasSnapshot ? root.formatTokensAbbreviated(root.snapshot.sessionTokens) : ""
                font.weight: Font.Bold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
        }
    }

    CostHistogram {
        id: costHistogram
        objectName: "costHistogram"
        daily: root.dailyEntries
        accentColor: root.accentColor
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
    }

    PlasmaComponents.Label {
        id: costPrimaryModelLabel
        objectName: "costPrimaryModelLabel"
        visible: root.hasSnapshot && root.primaryModelText.length > 0
        text: visible
            ? Translation.translate("Primary model: %1", [root.primaryModelText], typeof i18n === "function" ? i18n : null, root.languagePreference)
            : ""
        font.weight: Font.DemiBold
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }

    PlasmaComponents.Label {
        id: costLocalEstimateLabel
        objectName: "costLocalEstimateLabel"
        visible: root.hasSnapshot && root.snapshot.source === "local"
        text: visible
            ? Translation.translate("Local token-cost estimate", [], typeof i18n === "function" ? i18n : null, root.languagePreference)
            : ""
        color: Kirigami.Theme.disabledTextColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }
}
