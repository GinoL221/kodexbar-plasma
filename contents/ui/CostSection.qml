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
    spacing: Kirigami.Units.smallSpacing / 2

    // Plain, deterministic display formatting -- never a price calculation.
    // i18n()'s locale-aware substitution renders large raw numbers in
    // scientific notation with a locale decimal separator, so these are
    // pre-formatted into fixed strings before being handed to %1/%2.
    function formatUsd(value) {
        return (Math.round(value * 100) / 100).toFixed(2)
    }

    function formatTokens(value) {
        var rounded = Math.round(value)
        var digits = String(Math.abs(rounded))
        var grouped = digits.replace(/\B(?=(\d{3})+(?!\d))/g, ",")
        return (rounded < 0 ? "-" : "") + grouped
    }

    PlasmaComponents.Label {
        id: costLabel
        objectName: "costLabel"
        visible: root.hasSnapshot
        text: Translation.translate("Local token-cost estimate", [], typeof i18n === "function" ? i18n : null)
        font.weight: Font.DemiBold
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }

    PlasmaComponents.Label {
        id: costSessionLabel
        objectName: "costSessionLabel"
        visible: root.hasSnapshot
        text: root.hasSnapshot
            ? Translation.translate("Session: $%1 (%2 tokens)",
                [root.formatUsd(root.snapshot.sessionCostUSD), root.formatTokens(root.snapshot.sessionTokens)],
                typeof i18n === "function" ? i18n : null)
            : ""
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }

    PlasmaComponents.Label {
        id: costLast30DaysLabel
        objectName: "costLast30DaysLabel"
        visible: root.hasSnapshot
        text: root.hasSnapshot
            ? Translation.translate("Last 30 days: $%1 (%2 tokens)",
                [root.formatUsd(root.snapshot.last30DaysCostUSD), root.formatTokens(root.snapshot.last30DaysTokens)],
                typeof i18n === "function" ? i18n : null)
            : ""
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }
}
