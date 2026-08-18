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

    readonly property bool hasSnapshot: root.snapshot !== null && root.snapshot !== undefined

    visible: root.hasSnapshot
    Layout.fillWidth: true
    Layout.topMargin: Kirigami.Units.smallSpacing
    spacing: Kirigami.Units.smallSpacing

    // Plain, deterministic display formatting -- never a price calculation.
    // i18n()'s locale-aware substitution renders large raw numbers in
    // scientific notation with a locale decimal separator, so these are
    // pre-formatted into fixed strings before being handed to %1/%2. Both
    // functions below use a fixed comma-decimal, period-thousands format on
    // every machine, regardless of system locale (explicit product decision
    // -- not Qt.locale()/Intl-driven).
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
        text: Translation.translate("Cost", [], typeof i18n === "function" ? i18n : null)
        font.weight: Font.Medium
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.hasSnapshot
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            text: Translation.translate("Today", [], typeof i18n === "function" ? i18n : null)
            color: Kirigami.Theme.disabledTextColor
        }

        Item {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        PlasmaComponents.Label {
            id: costSessionLabel
            objectName: "costSessionLabel"
            visible: root.hasSnapshot
            text: root.hasSnapshot
                ? Translation.translate("$%1 - %2 tokens",
                    [root.formatUsd(root.snapshot.sessionCostUSD), root.formatTokensAbbreviated(root.snapshot.sessionTokens)],
                    typeof i18n === "function" ? i18n : null)
                : ""
            color: Kirigami.Theme.disabledTextColor
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.WordWrap
            Layout.minimumWidth: 0
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.hasSnapshot
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            text: Translation.translate("Last 30 days", [], typeof i18n === "function" ? i18n : null)
            color: Kirigami.Theme.disabledTextColor
        }

        Item {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        PlasmaComponents.Label {
            id: costLast30DaysLabel
            objectName: "costLast30DaysLabel"
            visible: root.hasSnapshot
            text: root.hasSnapshot
                ? Translation.translate("$%1 - %2 tokens",
                    [root.formatUsd(root.snapshot.last30DaysCostUSD), root.formatTokensAbbreviated(root.snapshot.last30DaysTokens)],
                    typeof i18n === "function" ? i18n : null)
                : ""
            color: Kirigami.Theme.disabledTextColor
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.WordWrap
            Layout.minimumWidth: 0
        }
    }

    PlasmaComponents.Label {
        id: costLocalEstimateLabel
        objectName: "costLocalEstimateLabel"
        visible: root.hasSnapshot && root.snapshot.source === "local"
        text: visible
            ? Translation.translate("Local token-cost estimate", [], typeof i18n === "function" ? i18n : null)
            : ""
        color: Kirigami.Theme.disabledTextColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }
}
