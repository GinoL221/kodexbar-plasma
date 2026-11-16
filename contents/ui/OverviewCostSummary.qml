pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "../code/CostModel.mjs" as CostModel
import "../code/Translation.mjs" as Translation

ColumnLayout {
    id: root

    property var summaryData: null
    property string languagePreference: "auto"

    readonly property bool hasSummary: root.summaryData !== null && root.summaryData !== undefined
        && typeof root.summaryData.count === "number" && root.summaryData.count > 0

    readonly property string titleText: Translation.translate(
        "Total cost",
        [],
        typeof i18n === "function" ? i18n : null,
        root.languagePreference
    )

    readonly property string todayValueText: root.hasSummary
        ? ("$" + CostModel.formatUsd(root.summaryData.sessionCostUSD)
            + " (" + CostModel.formatTokensAbbreviated(root.summaryData.sessionTokens) + ")")
        : ""

    readonly property string monthlyValueText: root.hasSummary
        ? ("$" + CostModel.formatUsd(root.summaryData.last30DaysCostUSD)
            + " (" + CostModel.formatTokensAbbreviated(root.summaryData.last30DaysTokens) + ")")
        : ""

    readonly property string todayLabelText: root.hasSummary
        ? Translation.translate(
            "Today: %1",
            [root.todayValueText],
            typeof i18n === "function" ? i18n : null,
            root.languagePreference
        )
        : ""

    readonly property string monthlyLabelText: root.hasSummary
        ? Translation.translate(
            "30 days: %1",
            [root.monthlyValueText],
            typeof i18n === "function" ? i18n : null,
            root.languagePreference
        )
        : ""

    visible: root.hasSummary
    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing
    Accessible.name: root.hasSummary
        ? (root.titleText + " — " + root.todayLabelText + ", " + root.monthlyLabelText)
        : ""

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        PlasmaComponents.Label {
            id: overviewTotalCostLabel
            objectName: "overviewTotalCostLabel"
            text: root.titleText
            font.weight: Font.Medium
            color: Kirigami.Theme.textColor
        }

        Item {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        PlasmaComponents.Label {
            id: overviewTodayTotalLabel
            objectName: "overviewTodayTotalLabel"
            visible: root.hasSummary
            text: root.todayLabelText
            color: Kirigami.Theme.disabledTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.features: ({ "tnum": 1 })
        }

        PlasmaComponents.Label {
            id: overview30DaysTotalLabel
            objectName: "overview30DaysTotalLabel"
            visible: root.hasSummary
            text: root.monthlyLabelText
            color: Kirigami.Theme.textColor
            font.weight: Font.DemiBold
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.features: ({ "tnum": 1 })
        }
    }
}
