import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
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

    function firstUsageWindowRow(item) {
        if (item instanceof UsageUi.UsageWindowRow) return item
        for (var i = 0; i < item.children.length; i++) {
            var result = firstUsageWindowRow(item.children[i])
            if (result !== null) return result
        }
        return null
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

    function assertResponsiveGeometry(row, widerWidth, message) {
        var barWidth = row.progressBar.width
        assert(row.percentageLabel.visible,
               message + ": finite percentage must remain visible")
        assert(row.percentageLabel.paintedWidth <= row.percentageLabel.width,
               message + ": percentage must remain fully visible")
        assert(row.windowLabel.x >= 0 && row.windowLabel.x + row.windowLabel.width <= row.width
               && row.progressBar.x >= 0 && row.progressBar.x + row.progressBar.width <= row.width
               && row.percentageLabel.x >= 0 && row.percentageLabel.x + row.percentageLabel.width <= row.width,
                message + ": visible content must stay within row bounds")
        assert(row.progressBar.width > 0, message + ": progress bar must retain available width")
        row.width = widerWidth
        assert(row.percentageLabel.paintedWidth <= row.percentageLabel.width,
               message + ": wider percentage must remain fully visible")
        assert(row.windowLabel.width <= row.windowLabel.implicitWidth,
               message + ": label must not consume progress-bar width beyond its preferred size")
        assert(row.progressBar.width > row.windowLabel.width,
               message + ": progress bar must consume the width remaining after the label")
        assert(row.progressBar.width > barWidth,
                message + ": progress bar must grow with additional width")
    }

    function assertProviderPopupGeometry(providerRow, windowRow, popupComposition, popupColumn, message) {
        assert(windowRow.Layout.fillWidth,
                "provider-composed row must opt into its parent's width allocation")
        assert(popupColumn.width === popupComposition.availableWidth,
                message + ": popup content must use the ScrollView viewport width")
        assert(providerRow.width === popupColumn.width && windowRow.width === providerRow.width,
                message + ": provider-composed row must receive the popup column width")
        assert(windowRow.windowLabel.x >= 0
                && windowRow.windowLabel.x + windowRow.windowLabel.width <= windowRow.width
                && windowRow.progressBar.x >= 0
                && windowRow.progressBar.x + windowRow.progressBar.width <= windowRow.width
                && windowRow.percentageLabel.x >= 0
                && windowRow.percentageLabel.x + windowRow.percentageLabel.width <= windowRow.width,
                message + ": label, progress bar, and percentage must stay within the composed row")
        assert(windowRow.progressBar.width > 0,
                message + ": provider-composed progress bar must retain popup-provided width")
        assert(windowRow.percentageLabel.visible
                && windowRow.percentageLabel.paintedWidth <= windowRow.percentageLabel.width,
                message + ": provider-composed percentage must remain fully visible")
        assert(windowRow.windowLabel.width <= windowRow.windowLabel.implicitWidth,
                message + ": label must not consume progress-bar width beyond its preferred size")
        assert(windowRow.progressBar.width > windowRow.windowLabel.width,
                message + ": progress bar must consume the width remaining after the label"
                + " (bar=" + windowRow.progressBar.width + ", label=" + windowRow.windowLabel.width + ")")
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

    UsageUi.ProviderRow {
        id: enrichedDetailRow
        width: 160
        providerData: ({
            provider: "enriched-provider",
            source: "Enriched CLI source",
            windows: [{ label: "Session", usedPercent: 40 }],
            raw: {
                pace: { primary: { summary: "Enriched pace summary that is somewhat long" } },
                credits: { remaining: 7 },
                usage: {
                    identity: { accountEmail: "enriched@example.invalid", accountOrganization: "Enriched Org" },
                    codexResetCredits: { availableCount: 1, credits: [{ amount: 1, expiresAt: "2026-11-01T00:00:00Z" }] }
                }
            }
        })
        costSnapshot: ({ provider: "enriched-provider", source: "local", sessionCostUSD: 1.5, sessionTokens: 1000, last30DaysCostUSD: 12, last30DaysTokens: 50000 })
    }

    UsageUi.ProviderRow {
        id: costFailureRow
        width: 160
        providerData: ({
            provider: "cost-failure-provider",
            source: "Cost Failure CLI source",
            windows: [{ label: "Session", usedPercent: 40 }]
        })
        costSnapshot: null
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

    UsageUi.UsageWindowRow {
        id: constrainedWindowRow
        width: 120
        windowData: ({ label: "Long Session Window", usedPercent: 100, resetsAt: null, resetDescription: null })
    }

    UsageUi.UsageWindowRow {
        id: constrainedSummaryWindowRow
        width: 120
        summary: true
        windowData: ({ label: "Long Summary Window", usedPercent: 100, resetsAt: null, resetDescription: null })
    }

    ColumnLayout {
        id: popupShell
        width: 120
        height: 180

        QQC2.ScrollView {
            id: popupComposition
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth

            ColumnLayout {
                id: popupColumn
                width: popupComposition.availableWidth
                spacing: 0

                UsageUi.ProviderRow {
                    id: constrainedProviderRow
                    Layout.fillWidth: true
                    summary: true
                    providerData: ({
                        provider: "responsive-provider",
                        source: "Responsive CLI source",
                        windows: [
                            { label: "Long Provider Window", usedPercent: 100, resetsAt: null, resetDescription: null }
                        ]
                    })
                }
            }
        }
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

        // Compact/summary rows never render selected-provider enrichment or
        // cost, matching "All" remaining compact and cost-free.
        var summaryEmail = findObject(summaryRow, "emailLabel")
        assert(summaryEmail === null || !summaryEmail.visible, "summary row must never show email")
        var compactCredits = findObject(compactRow, "creditsRemainingLabel")
        assert(compactCredits === null || !compactCredits.visible, "compact row must never show credits")
        var summaryCost = findObject(summaryRow, "costLabel")
        assert(summaryCost === null || !summaryCost.visible, "summary row must remain cost-free")

        // Conditional cost failure: usage/header stay visible, Cost section is absent.
        assert(findObject(costFailureRow, "providerLabel").visible, "usage/header must remain visible when cost is unavailable")
        var costFailureCostLabel = findObject(costFailureRow, "costLabel")
        assert(costFailureCostLabel === null || !costFailureCostLabel.visible, "Cost section must be absent without a snapshot")

        // Full enrichment renders together: pace, credits, reset disclosure, and cost.
        assert(findObject(enrichedDetailRow, "emailLabel").visible, "enriched row must show email")
        assert(findObject(enrichedDetailRow, "organizationLabel").visible, "enriched row must show a human-readable organization")
        assert(findObject(enrichedDetailRow, "creditsRemainingLabel").visible, "enriched row must show remaining credits")
        assert(findObject(enrichedDetailRow, "resetAvailableLabel").visible, "enriched row must show reset-credit availability")
        assert(findObject(enrichedDetailRow, "costLabel").visible, "enriched row must show the local cost estimate label")
        assert(findObject(enrichedDetailRow, "costSessionLabel").text.indexOf("1.5") !== -1, "enriched row must show session cost")

        var resetDisclosure = enrichedDetailRow.resetCreditsSection.disclosureButton
        assert(resetDisclosure.checkable && resetDisclosure.focusPolicy === Qt.StrongFocus && resetDisclosure.activeFocusOnTab,
               "reset-credit disclosure must be keyboard reachable")
        assert(resetDisclosure.Accessible.name.length > 0, "reset-credit disclosure must expose an accessible name")

        // Narrow-width reachability: wrapping labels must stay safe at narrow widths.
        var narrowCredits = findObject(enrichedDetailRow, "creditsRemainingLabel")
        assert(narrowCredits.wrapMode === Text.WordWrap && narrowCredits.Layout.minimumWidth === 0,
               "credits label must wrap safely at narrow widths")
        var narrowReset = findObject(enrichedDetailRow, "resetAvailableLabel")
        assert(narrowReset.wrapMode === Text.WordWrap && narrowReset.Layout.minimumWidth === 0,
               "reset-credit availability label must wrap safely at narrow widths")
        var narrowCost = findObject(enrichedDetailRow, "costSessionLabel")
        assert(narrowCost.wrapMode === Text.WordWrap && narrowCost.Layout.minimumWidth === 0,
               "cost label must wrap safely at narrow widths")

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

    }

    Timer {
        interval: 50
        running: true
        repeat: true
        property int stage: 0
        property real narrowBarWidth: 0
        property real mediumBarWidth: 0
        onTriggered: {
            var providerWindowRow = root.firstUsageWindowRow(constrainedProviderRow)
            root.assert(providerWindowRow !== null,
                    "provider-composed constrained row must render one usage window")
            if (stage === 0) {
                root.assertResponsiveGeometry(constrainedWindowRow, 600, "direct constrained row")
                root.assertResponsiveGeometry(constrainedSummaryWindowRow, 600, "summary constrained row")
                root.assertProviderPopupGeometry(constrainedProviderRow, providerWindowRow, popupComposition, popupColumn,
                                            "narrow popup composition")
                narrowBarWidth = providerWindowRow.progressBar.width
                stage++
                popupShell.width = 220
            } else if (stage === 1) {
                root.assertProviderPopupGeometry(constrainedProviderRow, providerWindowRow, popupComposition, popupColumn,
                                            "medium popup composition")
                root.assert(providerWindowRow.progressBar.width > narrowBarWidth,
                        "medium popup composition progress bar must grow from the narrow allocation")
                mediumBarWidth = providerWindowRow.progressBar.width
                stage++
                popupShell.width = 600
            } else {
                root.assertProviderPopupGeometry(constrainedProviderRow, providerWindowRow, popupComposition, popupColumn,
                                            "wide popup composition")
                root.assert(providerWindowRow.progressBar.width > mediumBarWidth,
                        "wide popup composition progress bar must grow from the medium allocation")
                running = false
                root.finish()
            }
        }
    }
}
