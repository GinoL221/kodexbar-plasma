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
            ? Translation.translate("Session: $%1 (%2 tokens)", [root.snapshot.sessionCostUSD, root.snapshot.sessionTokens],
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
            ? Translation.translate("Last 30 days: $%1 (%2 tokens)", [root.snapshot.last30DaysCostUSD, root.snapshot.last30DaysTokens],
                typeof i18n === "function" ? i18n : null)
            : ""
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }
}
