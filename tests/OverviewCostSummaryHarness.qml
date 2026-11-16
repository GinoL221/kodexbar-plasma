pragma ComponentBehavior: Bound

import QtQuick
import "../contents/code/CostModel.mjs" as CostModel
import "../contents/ui" as UsageUi

Item {
    id: root
    width: 420
    height: 200

    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("OverviewCostSummaryHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function findByObjectName(item, targetName) {
        if (!item) {
            return null
        }
        if (item.objectName === targetName) {
            return item
        }
        var kids = item.children || []
        for (var i = 0; i < kids.length; i++) {
            var found = findByObjectName(kids[i], targetName)
            if (found) {
                return found
            }
        }
        return null
    }

    UsageUi.OverviewCostSummary {
        id: summaryWidget
        width: 400
        languagePreference: "en"
        summaryData: null
    }

    Component.onCompleted: {
        assert(!summaryWidget.visible, "OverviewCostSummary must stay hidden when summaryData is null")

        var data = CostModel.summarizeSnapshots(
            [{ provider: "claude" }, { provider: "antigravity" }],
            function(id) {
                if (id === "claude") {
                    return { sessionCostUSD: 0.78, sessionTokens: 7900000, last30DaysCostUSD: 35.05, last30DaysTokens: 293800000 }
                }
                if (id === "antigravity") {
                    return { sessionCostUSD: 1.96, sessionTokens: 14900000, last30DaysCostUSD: 36.23, last30DaysTokens: 300700000 }
                }
                return null
            }
        )
        summaryWidget.summaryData = data
        assert(summaryWidget.visible, "OverviewCostSummary must be visible when combined cost data exists")

        var titleLabel = findByObjectName(summaryWidget, "overviewTotalCostLabel")
        var todayLabel = findByObjectName(summaryWidget, "overviewTodayTotalLabel")
        var monthlyLabel = findByObjectName(summaryWidget, "overview30DaysTotalLabel")
        assert(titleLabel !== null && titleLabel.text === "Total cost", "must show English heading")
        assert(todayLabel !== null && todayLabel.text.indexOf("$2,74") !== -1 && todayLabel.text.indexOf("22,8M") !== -1,
               "must format today total USD and tokens with comma-decimal contract")
        assert(monthlyLabel !== null && monthlyLabel.text.indexOf("$71,28") !== -1 && monthlyLabel.text.indexOf("594,5M") !== -1,
               "must format 30-day total USD and tokens with comma-decimal contract")

        summaryWidget.languagePreference = "es"
        assert(titleLabel.text === "Costo total", "must localize heading to Spanish")
        assert(todayLabel.text.indexOf("Hoy:") !== -1, "must localize today prefix to Spanish")
        assert(monthlyLabel.text.indexOf("30 días:") !== -1, "must localize 30 days prefix to Spanish")

        Qt.exit(assertionFailed ? 1 : 0)
    }
}
