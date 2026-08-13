import QtQuick
import QtQuick.Controls as QQC2
import "../contents/ui" as UsageUi

Item {
    id: root
    width: 160; height: 640
    property bool assertionFailed: false

    function assert(c, m) {
        if (!c) {
            console.error("ProviderRowHarness failure:", m)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(m)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    function countProgressBars(item) {
        var n = 0
        if (item instanceof QQC2.ProgressBar) n++
        for (var i = 0; i < item.children.length; i++) n += countProgressBars(item.children[i])
        return n
    }

    function countUsageWindowRows(item) {
        var n = 0
        if (item instanceof UsageUi.UsageWindowRow) n++
        for (var i = 0; i < item.children.length; i++) n += countUsageWindowRows(item.children[i])
        return n
    }

    function allResetLabelsHidden(item) {
        if (item instanceof UsageUi.UsageWindowRow) {
            if (item.resetsAtLabel.visible || item.resetDescriptionLabel.visible) return false
        }
        for (var i = 0; i < item.children.length; i++) {
            if (!allResetLabelsHidden(item.children[i])) return false
        }
        return true
    }

    function countVisibleUsageDetails(item) {
        var n = 0
        if (item instanceof UsageUi.UsageWindowRow) {
            if (item.percentageLabel.visible) n++
            if (item.resetsAtLabel.visible) n++
            if (item.resetDescriptionLabel.visible) n++
        }
        for (var i = 0; i < item.children.length; i++) n += countVisibleUsageDetails(item.children[i])
        return n
    }

    function findObject(item, name) {
        if (item.objectName === name) return item
        for (var i = 0; i < item.children.length; i++) {
            var result = findObject(item.children[i], name)
            if (result !== null) return result
        }
        return null
    }

    UsageUi.ProviderRow {
        id: row
        width: root.width
        providerData: ({
            provider: "unknown-provider",
            source: "CLI raw source",
            windows: [
                { label: "Session", usedPercent: 72, resetsAt: "2026-08-09T12:00:00Z", resetDescription: "Exact reset note" },
                { label: "Monthly", usedPercent: null, resetsAt: null, resetDescription: null }
            ]
        })
    }

    UsageUi.ProviderRow {
        id: detailRow
        width: root.width
        compact: false
        providerData: ({
            provider: "detail-provider",
            source: "Detail CLI source",
            windows: [
                { label: "Session", usedPercent: 72, resetsAt: "2026-08-09T12:00:00Z", resetDescription: "Exact reset note" },
                { label: "Monthly", usedPercent: null, resetsAt: null, resetDescription: null },
                { label: "Weekly", usedPercent: Infinity, resetsAt: null, resetDescription: null },
                { label: "Daily", usedPercent: "80", resetsAt: null, resetDescription: null },
                { label: "Hourly", usedPercent: NaN, resetsAt: "2026-08-09T13:00:00Z", resetDescription: "NaN reset" }
            ]
        })
    }

    UsageUi.ProviderRow {
        id: compactRow
        width: root.width
        compact: true
        providerData: ({
            provider: "compact-provider",
            source: "Compact CLI source",
            windows: [
                { label: "Session", usedPercent: 55, resetsAt: "2026-08-09T14:00:00Z", resetDescription: "Compact reset" }
            ]
        })
    }

    UsageUi.ProviderRow {
        id: summaryRow
        width: root.width
        summary: true
        providerData: ({
            provider: "summary-provider",
            source: "Summary CLI source",
            windows: [
                { label: "Session", usedPercent: 55, resetsAt: "2026-08-09T14:00:00Z", resetDescription: "Summary reset" },
                { label: "Weekly", usedPercent: 75, resetsAt: null, resetDescription: null }
            ]
        })
    }

    UsageUi.ProviderRow {
        id: preferredWeeklyRow
        width: root.width
        summary: true
        preferredWindowKey: "weekly"
        providerData: ({
            provider: "preferred-weekly-provider",
            source: "Preferred Weekly CLI source",
            windows: [
                { label: "Session", usedPercent: 55, resetsAt: "2026-08-09T14:00:00Z", resetDescription: "Summary reset" },
                { label: "Weekly", usedPercent: 75, resetsAt: null, resetDescription: null }
            ]
        })
    }

    UsageUi.ProviderRow {
        id: preferredFallbackRow
        width: root.width
        summary: true
        preferredWindowKey: "monthly"
        providerData: ({
            provider: "preferred-fallback-provider",
            source: "Preferred Fallback CLI source",
            windows: [
                { label: "Session", usedPercent: 65, resetsAt: "2026-08-09T14:00:00Z", resetDescription: "Summary reset" },
                { label: "Monthly", usedPercent: NaN, resetsAt: null, resetDescription: null }
            ]
        })
    }

    UsageUi.ProviderRow {
        id: preferredIdentityOnlyRow
        width: root.width
        summary: true
        preferredWindowKey: "weekly"
        providerData: ({
            provider: "preferred-identity-only-provider",
            source: "Preferred Identity CLI source",
            windows: [
                { label: "Session", usedPercent: null, resetsAt: null, resetDescription: null },
                { label: "Weekly", usedPercent: NaN, resetsAt: null, resetDescription: null }
            ]
        })
    }

    UsageUi.ProviderRow {
        id: identityOnlyRow
        width: root.width
        summary: true
        providerData: ({
            provider: "identity-only-provider",
            source: "Identity CLI source",
            windows: [
                { label: "Session", usedPercent: null, resetsAt: null, resetDescription: null },
                { label: "Weekly", usedPercent: NaN, resetsAt: null, resetDescription: null }
            ]
        })
    }

    UsageUi.ProviderRow {
        id: activeSummaryRow
        width: root.width
        focus: true
        summary: true
        providerData: ({
            provider: "active-summary-provider",
            source: "Active Summary CLI source",
            windows: [
                { label: "Session", usedPercent: 55, resetsAt: "2026-08-09T14:00:00Z", resetDescription: "Summary reset" },
                { label: "Weekly", usedPercent: 75, resetsAt: null, resetDescription: null }
            ]
        })
    }

    UsageUi.ProviderRow {
        id: resolverRow
        width: root.width
        iconResolver: function(value) { return "custom-" + value }
        providerData: ({
            provider: "openai",
            source: "Resolver source",
            windows: []
        })
    }

    UsageUi.UsageWindowRow {
        id: windowRow
        windowData: ({ label: "Session", usedPercent: 72, resetsAt: "2026-08-09T12:00:00Z", resetDescription: "Exact reset note" })
    }

    UsageUi.UsageWindowRow {
        id: summaryWindowRow
        summary: true
        windowData: ({ label: "Session", usedPercent: 72, resetsAt: "2026-08-09T12:00:00Z", resetDescription: "Exact reset note" })
    }

    Component.onCompleted: {
        assert(row.providerValue === "unknown-provider", "provider must remain raw")
        assert(row.sourceValue === "CLI raw source", "source must remain raw")
        assert(row.windows.length === 2, "missing windows must be omitted by the input model")
        assert(row.windows[0].label === "Session" && row.windows[1].label === "Monthly", "window order must be preserved")
        assert(row.windows[0].resetsAt === "2026-08-09T12:00:00Z", "reset values must remain exact")
        assert(row.iconSource("unknown-provider") === "dialog-information", "unknown providers must use the themed fallback icon")
        assert(row.width === root.width, "row must remain usable in narrow geometry")

        assert(detailRow.compact === false && compactRow.compact === true, "compact property must be exposed")
        assert(countProgressBars(detailRow) === 1, "detail row must render one progress bar for the single finite percentage")
        assert(countProgressBars(compactRow) === 0, "compact row must omit progress bars")

        assert(summaryRow.summary === true, "summary property must be exposed")
        assert(countProgressBars(summaryRow) === 1, "summary row must render exactly one progress bar for the representative window")
        assert(summaryRow.providerValue === "summary-provider" && summaryRow.sourceValue === "Summary CLI source", "summary row must preserve provider identity")
        assert(identityOnlyRow.displayedWindows.length === 0, "identity-only summary row must render no displayed windows")
        assert(countUsageWindowRows(identityOnlyRow) === 0, "identity-only summary row must render no usage window rows")
        assert(countProgressBars(identityOnlyRow) === 0, "identity-only summary row must render no progress bar")
        assert(countVisibleUsageDetails(identityOnlyRow) === 0, "identity-only summary row must render no percentage or reset detail")
        assert(identityOnlyRow.providerValue === "identity-only-provider", "identity-only row must preserve provider identity")

        var barsBefore = countProgressBars(activeSummaryRow)
        var rowsBefore = countUsageWindowRows(activeSummaryRow)
        assert(barsBefore === 1, "active summary row must render exactly one progress bar before activation")
        assert(rowsBefore === 1, "active summary row must render exactly one window row before activation")
        assert(allResetLabelsHidden(activeSummaryRow), "active summary row must hide reset labels before activation")

        activeSummaryRow.forceActiveFocus()
        assert(countProgressBars(activeSummaryRow) === barsBefore, "activating summary row must not reveal additional progress bars")
        assert(countUsageWindowRows(activeSummaryRow) === rowsBefore, "activating summary row must not expand into additional window rows")
        assert(allResetLabelsHidden(activeSummaryRow), "activating summary row must not reveal reset labels")

        assert(summaryRow.preferredWindowKey === "automatic", "default preferredWindowKey must be automatic")
        assert(countProgressBars(summaryRow) === 1, "unchanged summaryRow rendering must still show exactly one progress bar")
        assert(summaryRow.representativeWindow.label === "Session", "unchanged summaryRow must keep automatic Session selection")

        assert(preferredWeeklyRow.representativeWindow.label === "Weekly", "explicit weekly preference with a finite value must select Weekly")
        assert(countProgressBars(preferredWeeklyRow) === 1, "preferred weekly row must render exactly one progress bar")

        assert(preferredFallbackRow.representativeWindow.label === "Session", "monthly preference with a non-finite Monthly value must fall back to Session")
        assert(countProgressBars(preferredFallbackRow) === 1, "preferred fallback row must still render exactly one progress bar")

        assert(preferredIdentityOnlyRow.displayedWindows.length === 0, "preferred row with no finite window must render no displayed windows")
        assert(countUsageWindowRows(preferredIdentityOnlyRow) === 0, "preferred row with no finite window must render no usage window rows")
        assert(countProgressBars(preferredIdentityOnlyRow) === 0, "preferred row with no finite window must render no progress bar")

        assert(countVisibleUsageDetails(preferredFallbackRow) === countVisibleUsageDetails(preferredWeeklyRow), "fallback and explicit preference bars must expose the same visible-detail count")

        preferredWeeklyRow.preferredWindowKey = "session"
        assert(preferredWeeklyRow.representativeWindow.label === "Session", "changing preferredWindowKey at runtime must update the rendered representative window")
        assert(countProgressBars(preferredWeeklyRow) === 1, "reactivity change must still render exactly one progress bar")
        preferredWeeklyRow.preferredWindowKey = "weekly"

        assert(resolverRow.iconSource("openai") === "custom-openai", "iconResolver must be used")
        assert(row.iconSource("openai") !== "custom-openai", "default lookup must remain without iconResolver")

        var providerLabel = findObject(row, "providerLabel")
        var sourceLabel = findObject(row, "sourceLabel")
        assert(providerLabel !== null && sourceLabel !== null, "provider labels must remain discoverable")
        assert(providerLabel.elide === Text.ElideRight && sourceLabel.elide === Text.ElideRight, "name and source must elide")
        assert(row.Accessible.description.indexOf("CLI raw source") !== -1, "accessible description must expose full source")

        assert(windowRow.progressBar.visible === true && windowRow.percentageLabel.text.indexOf("72") !== -1, "finite percentage")
        assert(summaryWindowRow.progressBar.visible === true && summaryWindowRow.percentageLabel.text.indexOf("72") !== -1, "summary window row must show percentage and bar")
        assert(summaryWindowRow.resetsAtLabel.visible === false && summaryWindowRow.resetDescriptionLabel.visible === false, "summary window row must hide reset fields")

        windowRow.windowData = { label: "Monthly", usedPercent: null, resetsAt: null, resetDescription: null }
        assert(windowRow.progressBar.visible === false && windowRow.percentageLabel.text.indexOf("%") === -1, "null percentage")
        windowRow.windowData = { label: "Daily", usedPercent: "80", resetsAt: null, resetDescription: null }
        assert(windowRow.progressBar.visible === false, "string percentage")
        windowRow.windowData = { label: "Weekly", usedPercent: Infinity, resetsAt: null, resetDescription: null }
        assert(windowRow.progressBar.visible === false, "infinite percentage")
        windowRow.windowData = { label: "Hourly", usedPercent: NaN, resetsAt: "2026-08-09T13:00:00Z", resetDescription: "NaN reset" }
        assert(windowRow.progressBar.visible === false, "NaN percentage")
        assert(windowRow.resetsAtLabel.text.indexOf("2026-08-09T13:00:00Z") !== -1, "resetsAt must stay exact")
        assert(windowRow.resetDescriptionLabel.text.indexOf("NaN reset") !== -1, "resetDescription must stay exact")

        windowRow.windowData = { label: "Session", usedPercent: 72, resetsAt: "2026-08-09T12:00:00Z", resetDescription: "Exact reset note" }
        windowRow.compact = true
        assert(windowRow.percentageLabel.text.indexOf("72") !== -1 && windowRow.progressBar.visible === false, "compact keeps text, hides bar")
        assert(windowRow.resetsAtLabel.elide === Text.ElideRight && windowRow.resetsAtLabel.wrapMode === Text.NoWrap,
               "compact reset text must elide without using an invalid wrap mode")
        assert(windowRow.resetDescriptionLabel.elide === Text.ElideRight && windowRow.resetDescriptionLabel.wrapMode === Text.NoWrap,
               "compact reset descriptions must elide without using an invalid wrap mode")
        windowRow.compact = false
        assert(windowRow.resetsAtLabel.elide === Text.ElideNone && windowRow.resetsAtLabel.wrapMode === Text.Wrap,
               "detail reset text must wrap")

        finish()
    }
}
