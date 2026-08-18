import QtQuick
import org.kde.kirigami as Kirigami
import "../contents/ui" as UsageUi

Item {
    id: root
    width: 400
    height: 620
    property bool assertionFailed: false

    function assert(c, m) {
        if (!c) {
            console.error("UsageWindowThresholdHarness failure:", m)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(m)
        }
    }

    // The fill Rectangle is always the second child of the bar Item itself:
    // summaryBar directly (summary mode), or detailBar nested one level
    // inside detailBarHost (detail mode, row.progressBar).
    function fillRectFor(row) {
        var bar = row.summary ? row.progressBar : row.progressBar.children[0]
        return bar.children[1]
    }

    // 10-fixture matrix: usedPercent in {50, 75, 95, 100, null} x summary in {true, false}.
    UsageUi.UsageWindowRow {
        id: pct50Summary
        width: 400
        y: 0
        summary: true
        windowData: ({ label: "Session", usedPercent: 50, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: pct50Detail
        width: 400
        y: 40
        summary: false
        windowData: ({ label: "Session", usedPercent: 50, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: pct75Summary
        width: 400
        y: 100
        summary: true
        windowData: ({ label: "Weekly", usedPercent: 75, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: pct75Detail
        width: 400
        y: 140
        summary: false
        windowData: ({ label: "Weekly", usedPercent: 75, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: pct95Summary
        width: 400
        y: 220
        summary: true
        windowData: ({ label: "Monthly", usedPercent: 95, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: pct95Detail
        width: 400
        y: 260
        summary: false
        windowData: ({ label: "Monthly", usedPercent: 95, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: pct100Summary
        width: 400
        y: 300
        summary: true
        windowData: ({ label: "Session", usedPercent: 100, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: pct100Detail
        width: 400
        y: 340
        summary: false
        windowData: ({ label: "Session", usedPercent: 100, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: pctNullSummary
        width: 400
        y: 380
        summary: true
        windowData: ({ label: "Session", usedPercent: null, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: pctNullDetail
        width: 400
        y: 420
        summary: false
        windowData: ({ label: "Session", usedPercent: null, resetsAt: null, resetDescription: null })
    }

    // Reserved-slot invariant (D24, spec scenario "Bar track length is
    // threshold-independent"): identical label text and identical
    // percent-text width (both fixed columns, D13), differing only in
    // threshold level -- one renders no marker (ok), one renders a visible
    // critical marker, one renders a visible exhausted marker. Their bar
    // tracks (row.progressBar.width) must be pixel-equal because the
    // marker's layout slot is always reserved.
    UsageUi.UsageWindowRow {
        id: reservedSlotOk
        width: 400
        y: 460
        summary: true
        windowData: ({ label: "Session", usedPercent: 50, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: reservedSlotCritical
        width: 400
        y: 500
        summary: true
        windowData: ({ label: "Session", usedPercent: 95, resetsAt: null, resetDescription: null })
    }
    UsageUi.UsageWindowRow {
        id: reservedSlotExhausted
        width: 400
        y: 540
        summary: true
        windowData: ({ label: "Session", usedPercent: 100, resetsAt: null, resetDescription: null })
    }

    Timer {
        interval: 100
        running: true
        onTriggered: {
            var fixtures = [
                { row: pct50Summary, level: "ok" },
                { row: pct50Detail, level: "ok" },
                { row: pct75Summary, level: "warn" },
                { row: pct75Detail, level: "warn" },
                { row: pct95Summary, level: "critical" },
                { row: pct95Detail, level: "critical" },
                { row: pct100Summary, level: "exhausted" },
                { row: pct100Detail, level: "exhausted" },
                { row: pctNullSummary, level: "" },
                { row: pctNullDetail, level: "" }
            ]

            for (var i = 0; i < fixtures.length; i++) {
                var row = fixtures[i].row
                var level = fixtures[i].level
                // D25: direct handle, never null -- the Loader is always
                // active (D24), only the loaded icon's opacity toggles.
                var marker = row.thresholdMarker
                root.assert(marker !== null,
                    "thresholdMarker handle must never be null (level=" + level + ", summary=" + row.summary + ")")

                var expectRisk = level === "warn" || level === "critical" || level === "exhausted"
                var expectOpacity = expectRisk ? 1 : 0
                root.assert(marker.opacity === expectOpacity,
                    "thresholdMarker opacity mismatch (level=" + level + ", summary=" + row.summary + ")")

                if (expectRisk) {
                    var expectedColor = level === "critical" || level === "exhausted"
                        ? Kirigami.Theme.negativeTextColor
                        : Kirigami.Theme.neutralTextColor
                    root.assert(Qt.colorEqual(marker.color, expectedColor),
                        "thresholdMarker color mismatch (level=" + level + ", summary=" + row.summary + ")")

                    var expectedSourceFragment = level === "exhausted"
                        ? "threshold-exhausted"
                        : level === "critical" ? "threshold-critical" : "threshold-warning"
                    root.assert(String(marker.source).indexOf(expectedSourceFragment) !== -1,
                        "thresholdMarker source must contain \"" + expectedSourceFragment
                        + "\" (level=" + level + ", summary=" + row.summary + ")")
                }

                var fill = root.fillRectFor(row)
                root.assert(Qt.colorEqual(fill.color, row.barFillColor),
                    "bar fill color must remain threshold-independent (D9)")
            }

            // Cross-mode identity: summary and detail must agree at the same percent.
            var pairs = [[pct75Summary, pct75Detail], [pct95Summary, pct95Detail], [pct100Summary, pct100Detail]]
            for (var p = 0; p < pairs.length; p++) {
                var a = pairs[p][0].thresholdMarker
                var b = pairs[p][1].thresholdMarker
                root.assert(a.opacity === b.opacity, "cross-mode thresholdMarker opacity must agree")
                root.assert(Qt.colorEqual(a.color, b.color), "cross-mode thresholdMarker color must agree")
            }

            // D24/D26 reserved-slot invariant (spec scenario "Bar track
            // length is threshold-independent"): same label text, same
            // percent-text width, only the threshold level differs -- the
            // marker's layout slot is always reserved, so the bar TRACK
            // (row.progressBar.width, not the marker) must be pixel-equal
            // whether or not a marker is visible.
            root.assert(Math.abs(reservedSlotOk.progressBar.width - reservedSlotCritical.progressBar.width) < 0.01,
                "bar track width must stay identical whether or not the row shows a threshold marker (reserved slot, D24): "
                + reservedSlotOk.progressBar.width + " vs " + reservedSlotCritical.progressBar.width)
            root.assert(Math.abs(reservedSlotOk.progressBar.width - reservedSlotExhausted.progressBar.width) < 0.01,
                "bar track width must stay identical for the exhausted level too (reserved slot, D24): "
                + reservedSlotOk.progressBar.width + " vs " + reservedSlotExhausted.progressBar.width)

            // a11y (D10): the risk phrase must appear immediately after the
            // percent entry, only when a finite percent exists.
            var d75 = pct75Summary.Accessible.description
            root.assert(d75.indexOf("75% used") !== -1, "75% fixture a11y must mention the percent")
            root.assert(d75.indexOf("Elevated usage") !== -1, "75% fixture a11y must mention Elevated usage")
            root.assert(d75.indexOf("Elevated usage") > d75.indexOf("75% used"),
                "Elevated usage must appear after the percent entry")
            root.assert(d75.indexOf("Critical usage") === -1, "75% fixture a11y must not mention Critical usage")

            var d75Detail = pct75Detail.Accessible.description
            root.assert(d75Detail.indexOf("Elevated usage") !== -1
                && d75Detail.indexOf("Elevated usage") > d75Detail.indexOf("75% used"),
                "detail-mode 75% fixture a11y must also mention Elevated usage in order")

            var d95 = pct95Summary.Accessible.description
            root.assert(d95.indexOf("95% used") !== -1, "95% fixture a11y must mention the percent")
            root.assert(d95.indexOf("Critical usage") !== -1, "95% fixture a11y must mention Critical usage")
            root.assert(d95.indexOf("Critical usage") > d95.indexOf("95% used"),
                "Critical usage must appear after the percent entry")
            root.assert(d95.indexOf("Elevated usage") === -1, "95% fixture a11y must not mention Elevated usage")

            var d95Detail = pct95Detail.Accessible.description
            root.assert(d95Detail.indexOf("Critical usage") !== -1
                && d95Detail.indexOf("Critical usage") > d95Detail.indexOf("95% used"),
                "detail-mode 95% fixture a11y must also mention Critical usage in order")

            var d100 = pct100Summary.Accessible.description
            root.assert(d100.indexOf("100% used") !== -1, "100% fixture a11y must mention the percent")
            root.assert(d100.indexOf("Quota exhausted") !== -1, "100% fixture a11y must mention Quota exhausted")
            root.assert(d100.indexOf("Quota exhausted") > d100.indexOf("100% used"),
                "Quota exhausted must appear after the percent entry")
            root.assert(d100.indexOf("Critical usage") === -1, "100% fixture a11y must not mention Critical usage")
            root.assert(d100.indexOf("Elevated usage") === -1, "100% fixture a11y must not mention Elevated usage")

            var d100Detail = pct100Detail.Accessible.description
            root.assert(d100Detail.indexOf("Quota exhausted") !== -1
                && d100Detail.indexOf("Quota exhausted") > d100Detail.indexOf("100% used"),
                "detail-mode 100% fixture a11y must also mention Quota exhausted in order")

            var d50 = pct50Summary.Accessible.description
            root.assert(d50.indexOf("Elevated usage") === -1 && d50.indexOf("Critical usage") === -1,
                "50% fixture a11y must not mention any risk phrase")
            root.assert(d50 === "50% used",
                "50% fixture a11y must be unchanged (byte-identical to today's percent-only entry)")

            var dNull = pctNullSummary.Accessible.description
            root.assert(dNull.indexOf("Elevated usage") === -1 && dNull.indexOf("Critical usage") === -1,
                "null fixture a11y must not mention any risk phrase")
            root.assert(dNull === "", "null fixture a11y must stay empty, unchanged from today")

            Qt.exit(root.assertionFailed ? 1 : 0)
        }
    }
}
