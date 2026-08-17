import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    width: 400
    height: 200
    property bool assertionFailed: false

    function assert(c, m) {
        if (!c) {
            console.error("SummaryBarNormalizeHarness failure:", m)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(m)
        }
    }

    UsageUi.UsageWindowRow {
        id: normSession1
        width: 320
        summary: true
        windowData: ({ label: "Session", usedPercent: 1, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: normWeekly100
        width: 320
        y: 40
        summary: true
        windowData: ({ label: "Weekly", usedPercent: 100, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: normMonthly42
        width: 320
        y: 80
        summary: true
        windowData: ({ label: "Monthly", usedPercent: 42, resetsAt: null, resetDescription: null })
    }

    Timer {
        interval: 100
        running: true
        onTriggered: {
            var tol = 1.0
            root.assert(normSession1.progressBar.visible && normWeekly100.progressBar.visible
                        && normMonthly42.progressBar.visible,
                        "bars must be visible")
            root.assert(Math.abs(normSession1.windowLabel.width - normWeekly100.windowLabel.width) <= tol
                        && Math.abs(normSession1.windowLabel.width - normMonthly42.windowLabel.width) <= tol,
                        "label cols equal: "
                        + normSession1.windowLabel.width + "/"
                        + normWeekly100.windowLabel.width + "/"
                        + normMonthly42.windowLabel.width)
            root.assert(Math.abs(normSession1.percentageLabel.width - normWeekly100.percentageLabel.width) <= tol
                        && Math.abs(normSession1.percentageLabel.width - normMonthly42.percentageLabel.width) <= tol,
                        "percent cols equal: "
                        + normSession1.percentageLabel.width + "/"
                        + normWeekly100.percentageLabel.width + "/"
                        + normMonthly42.percentageLabel.width)
            root.assert(Math.abs(normSession1.progressBar.width - normWeekly100.progressBar.width) <= tol
                        && Math.abs(normSession1.progressBar.width - normMonthly42.progressBar.width) <= tol,
                        "bar tracks equal: "
                        + normSession1.progressBar.width + "/"
                        + normWeekly100.progressBar.width + "/"
                        + normMonthly42.progressBar.width)
            root.assert(normSession1.progressBar.width >= 48,
                        "bar usable: " + normSession1.progressBar.width)
            Qt.exit(root.assertionFailed ? 1 : 0)
        }
    }
}
