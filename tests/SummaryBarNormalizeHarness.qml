import QtQuick
import org.kde.kirigami as Kirigami
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

    // D20 regression fixture: a short, realistic window label ("Weekly") at
    // a realistic Overview popup width. "Weekly"'s implicit text width is
    // well under this row's available space, so it must render in full --
    // the live Breeze Dark screenshot caught it eliding to "Wee..." because
    // the title RowLayout's two Layout.fillWidth siblings (windowLabel, the
    // spacer) split stretch space instead of ceding 100% of it to the
    // spacer.
    UsageUi.UsageWindowRow {
        id: weeklySummaryWindowRow
        width: 260
        y: 120
        summary: true
        windowData: ({ label: "Weekly", usedPercent: 42, resetsAt: null, resetDescription: null })
    }

    // Regression: "Monthly" is the exact reference string the label column
    // sizes itself against (summaryLabelColumnWidth's TextMetrics), so a
    // column sized to precisely that metric can still clip it by a
    // sub-pixel rounding difference between TextMetrics and actual Text
    // rendering -- live Breeze Dark caught "OpenCode Go"'s Monthly row
    // eliding to "Mont...".
    UsageUi.UsageWindowRow {
        id: monthlySummaryWindowRow
        width: 260
        y: 160
        summary: true
        windowData: ({ label: "Monthly", usedPercent: 87, resetsAt: null, resetDescription: null })
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

            // The percent column must hug its own "100% used" worst-case text
            // metrics, not an oversized fixed floor -- an artificial floor wider
            // than the text left a large visual gap between the bar and the
            // percentage (user-reported: overview text sits too far from its bar).
            root.assert(normSession1.summaryPercentColumnWidth < Kirigami.Units.gridUnit * 6,
                        "summary percent column must not be padded by a fixed gridUnit*6 floor wider than its own text")
            // Same gap bug on the label side: "Session"/"Weekly"/"Monthly" text
            // is far narrower than the old fixed gridUnit*5 column, leaving a
            // large visual gap between the window label and the bar.
            root.assert(normSession1.summaryLabelColumnWidth < Kirigami.Units.gridUnit * 5,
                        "summary label column must not be padded by a fixed gridUnit*5 floor wider than its own text")

            // D20: a short, realistic window title must never be truncated by
            // the summary title row's spacer stretch-factor split. `.text`
            // always holds the untruncated source string even when visually
            // elided (Text.ElideRight only affects rendering), so this checks
            // paintedWidth against implicitWidth -- the reliable signal for
            // whether the rendered glyphs were actually cut short.
            root.assert(weeklySummaryWindowRow.windowLabel.paintedWidth >= weeklySummaryWindowRow.windowLabel.implicitWidth - 0.5,
                        "summary window row title must render a short label in full, not elided, at a realistic width (D20)")
            root.assert(monthlySummaryWindowRow.windowLabel.paintedWidth >= monthlySummaryWindowRow.windowLabel.implicitWidth - 0.5,
                        "summary window row title must render \"Monthly\" in full, not elided to \"Mont...\", even though it is the label column's own sizing reference")

            Qt.exit(root.assertionFailed ? 1 : 0)
        }
    }
}
