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
            console.error("CostHistogramHarness failure:", message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
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
            // Day 0: cost 10.0 -> ratio 1.0
            // Day 1: cost 0.0, tokens 50M -> ratio MUST be 0.0 (not inflated to 1.0 by mixing tokens with dollars)
            // Day 2: cost 5.0 -> ratio 0.5
            var mixedBars = root.findChildrenByObjectName(mixedHistogram, "costHistogramBar")
            root.assert(mixedBars.length === 3, "mixed histogram must render 3 bars")

            // Token-only mode when no day has positive cost
            root.assert(tokenOnlyHistogram.visible, "token-only dataset must be visible")
            root.assert(tokenOnlyHistogram.isCostMode === false, "token-only dataset must not activate isCostMode")
            root.assert(tokenOnlyHistogram.maxMetric === 5000, "maxMetric in token mode must equal maximum tokens (5000)")

            Qt.exit(root.assertionFailed ? 1 : 0)
        }
    }
}
