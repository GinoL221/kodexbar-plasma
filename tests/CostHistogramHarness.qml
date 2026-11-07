pragma ComponentBehavior: Bound

import QtQuick
import "../contents/ui" as UI

Item {
    id: root
    width: 400
    height: 300

    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("CostHistogramHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() {
        Qt.exit(assertionFailed ? 1 : 0)
    }

    function findChildrenByObjectName(parentItem, objName) {
        var results = []
        for (var i = 0; i < parentItem.children.length; i++) {
            var child = parentItem.children[i]
            if (child.objectName === objName) {
                results.push(child)
            }
            results = results.concat(findChildrenByObjectName(child, objName))
        }
        return results
    }

    UI.CostHistogram {
        id: mixedHistogram
        width: 300
        daily: [
            { date: "2026-11-01", totalCost: 10.0, totalTokens: 1000 },
            { date: "2026-11-02", totalCost: 0.0, totalTokens: 50000000 },
            { date: "2026-11-03", totalCost: 5.0, totalTokens: 500 }
        ]
    }

    UI.CostHistogram {
        id: tokenOnlyHistogram
        width: 300
        daily: [
            { date: "2026-11-01", totalCost: 0, totalTokens: 1000 },
            { date: "2026-11-02", totalCost: 0, totalTokens: 5000 },
            { date: "2026-11-03", totalCost: 0, totalTokens: 2500 }
        ]
    }

    UI.CostHistogram {
        id: emptyHistogram
        width: 300
        daily: []
    }

    UI.CostHistogram {
        id: twentyDaysHistogram
        width: 500
        daily: [
            { date: "2026-11-01", totalCost: 1.0, totalTokens: 100 },
            { date: "2026-11-02", totalCost: 2.0, totalTokens: 200 },
            { date: "2026-11-03", totalCost: 3.0, totalTokens: 300 },
            { date: "2026-11-04", totalCost: 4.0, totalTokens: 400 },
            { date: "2026-11-05", totalCost: 5.0, totalTokens: 500 },
            { date: "2026-11-06", totalCost: 6.0, totalTokens: 600 },
            { date: "2026-11-07", totalCost: 7.0, totalTokens: 700 },
            { date: "2026-11-08", totalCost: 8.0, totalTokens: 800 },
            { date: "2026-11-09", totalCost: 9.0, totalTokens: 900 },
            { date: "2026-11-10", totalCost: 10.0, totalTokens: 1000 },
            { date: "2026-11-11", totalCost: 11.0, totalTokens: 1100 },
            { date: "2026-11-12", totalCost: 12.0, totalTokens: 1200 },
            { date: "2026-11-13", totalCost: 13.0, totalTokens: 1300 },
            { date: "2026-11-14", totalCost: 14.0, totalTokens: 1400 },
            { date: "2026-11-15", totalCost: 15.0, totalTokens: 1500 },
            { date: "2026-11-16", totalCost: 16.0, totalTokens: 1600 },
            { date: "2026-11-17", totalCost: 17.0, totalTokens: 1700 },
            { date: "2026-11-18", totalCost: 18.0, totalTokens: 1800 }
        ]
    }

    Timer {
        interval: 30
        running: true
        repeat: false
        onTriggered: {
            // Empty dataset handling
            root.assert(!emptyHistogram.visible, "empty daily dataset must hide histogram")
            root.assert(!emptyHistogram.hasBars, "empty dataset hasBars must be false")

            // Homogeneous cost mode when any day has positive cost
            root.assert(mixedHistogram.visible, "mixed dataset must be visible")
            root.assert(mixedHistogram.isCostMode === true, "mixed dataset with positive costs must activate isCostMode")
            root.assert(mixedHistogram.maxMetric === 10.0, "maxMetric in cost mode must equal maximum cost (10.0)")

            // Verify bar ratios for mixed dataset
            var mixedBars = root.findChildrenByObjectName(mixedHistogram, "costHistogramBar")
            root.assert(mixedBars.length === 3, "mixed histogram must render 3 bars")

            // Token-only mode when no day has positive cost
            root.assert(tokenOnlyHistogram.visible, "token-only dataset must be visible")
            root.assert(tokenOnlyHistogram.isCostMode === false, "token-only dataset must not activate isCostMode")
            root.assert(tokenOnlyHistogram.maxMetric === 5000, "maxMetric in token mode must equal maximum tokens (5000)")

            // 14-day cap, bounded bar width, and right-edge alignment
            root.assert(Array.isArray(twentyDaysHistogram.recentDaily) && twentyDaysHistogram.recentDaily.length === 14,
                "recentDaily must cap at 14 days")
            var twentyDayBars = root.findChildrenByObjectName(twentyDaysHistogram, "costHistogramBar")
            root.assert(twentyDayBars.length === 14, "twentyDaysHistogram must render exactly 14 bars")

            var firstMixedBarPos = mixedBars[0].mapToItem(mixedHistogram, 0, 0)
            root.assert(firstMixedBarPos.x > mixedHistogram.width / 2,
                "short daily series must align to the right edge of the histogram")

            root.finish()
        }
    }
}
