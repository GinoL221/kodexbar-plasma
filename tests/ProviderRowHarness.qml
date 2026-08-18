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
        if (!item) {
            return 0
        }
        var n = 0
        // Thin custom bars (visible only); legacy QQC2.ProgressBar still counts.
        if (item instanceof QQC2.ProgressBar) {
            n++
        } else if ((item.objectName === "summaryUsageProgressBar" || item.objectName === "detailUsageProgressBar"
                    || item.objectName === "usageProgressBar") && item.visible) {
            n++
        }
        for (var i = 0; i < item.children.length; i++) {
            n += countProgressBars(item.children[i])
        }
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

    function isWithinRow(row, item) {
        var position = item.mapToItem(row, 0, 0)
        return position.x >= 0 && position.x + item.width <= row.width
    }

    function assertResponsiveGeometry(row, widerWidth, message) {
        var barWidth = row.progressBar.width
        var isSummary = row.summary === true
        assert(row.percentageLabel.visible,
               message + ": finite percentage must remain visible")
        assert(row.percentageLabel.paintedWidth <= row.percentageLabel.width,
               message + ": percentage must remain fully visible")
        assert(row.windowLabel.x >= 0 && row.windowLabel.x + row.windowLabel.width <= row.width
               && row.progressBar.x >= 0 && row.progressBar.x + row.progressBar.width <= row.width
               && row.percentageLabel.x >= 0 && row.percentageLabel.x + row.percentageLabel.width <= row.width,
                message + ": visible content must stay within row bounds")
        if (isSummary) {
            // Overview single-line: bar shares the row with label + percent.
            assert(row.progressBar.width < row.width,
                   message + ": summary progress bar must share the row with label and percent")
            assert(row.progressBar.width > 0,
                   message + ": summary progress bar must retain positive width")
        } else {
            assert(row.progressBar.width > 0 && row.progressBar.width <= row.width + 1.0,
                   message + ": detail progress bar must span within the row width")
        }
        // Title is hard-capped in UsageWindowRow (gridUnit * 6); do not read
        // Layout.maximumWidth from outside — attached props are unreliable cross-item.
        assert(row.windowLabel.width > 0 && row.windowLabel.width <= row.width,
               message + ": title label must stay within the row")
        assert(row.resetsAtLabel.visible === false && row.resetDescriptionLabel.visible === false,
               message + ": band must show percent only with no reset placeholder when neither reset field is present (D3)")
        row.width = widerWidth
        assert(row.percentageLabel.paintedWidth <= row.percentageLabel.width,
               message + ": wider percentage must remain fully visible")
        if (isSummary) {
            assert(row.progressBar.width > barWidth,
                    message + ": summary progress bar must grow with additional width")
            assert(row.progressBar.width < row.width,
                   message + ": summary progress bar must still share the wider row")
        } else {
            // Standalone width writes do not always reflow Layout.fillWidth
            // children in the same turn. Growth under real layout is covered
            // by the popup-composition stages below; here only require the
            // bar stays within the row and remains visible/positive.
            assert(row.progressBar.width > 0,
                    message + ": progress bar must retain positive width when wider")
            assert(row.progressBar.width <= row.width + 1.0,
                   message + ": progress bar must stay within the wider row")
        }
    }

    // Overview summary: single horizontal line — label | bar | percent.
    // Vertical centers may differ slightly (ProgressBar vs Label baseline);
    // prove same line via vertical overlap + strict left-to-right x order.
    function assertSummaryInlineOrder(row, message) {
        var titlePos = row.windowLabel.mapToItem(row, 0, 0)
        var percentPos = row.percentageLabel.mapToItem(row, 0, 0)
        var barPos = row.progressBar.mapToItem(row, 0, 0)
        var percentRight = percentPos.x + row.percentageLabel.width
        var titleBottom = titlePos.y + row.windowLabel.height
        var barBottom = barPos.y + row.progressBar.height
        var percentBottom = percentPos.y + row.percentageLabel.height
        assert(titlePos.y < barBottom && barPos.y < titleBottom,
               message + ": progress bar must vertically overlap the title (summary inline)")
        assert(titlePos.y < percentBottom && percentPos.y < titleBottom,
               message + ": percentage label must vertically overlap the title (summary inline)")
        assert(barPos.x > titlePos.x + row.windowLabel.width - 1.0,
               message + ": progress bar must sit to the right of the title (summary inline)")
        assert(percentPos.x > barPos.x + row.progressBar.width - 1.0,
               message + ": percentage label must sit to the right of the bar (summary inline)")
        assert(percentRight >= row.width - 1.0 && percentRight > row.width / 2,
               message + ": percentage label must be right-aligned within the summary row")
        assert(row.progressBar.width > 0 && row.progressBar.width < row.width,
               message + ": summary progress bar must share width with label and percent")
    }

    // Detail-mode anti-regression: percent stays BELOW the full-width bar
    // (macOS CodexBar hierarchy / Image 2).
    function assertDetailPercentBelowBar(row, message) {
        var percentPos = row.percentageLabel.mapToItem(row, 0, 0)
        var barPos = row.progressBar.mapToItem(row, 0, 0)
        assert(percentPos.y > barPos.y,
               message + ": detail-mode percentage must remain below the progress bar")
        assert(row.progressBar.visible && row.progressBar.height > 0,
               message + ": detail-mode progress bar must be visible with height")
        assert(row.progressBar.width > 0 && row.progressBar.width <= row.width + 1.0,
               message + ": detail-mode progress bar must span within the row width")
    }

    function assertProviderPopupGeometry(providerRow, windowRow, popupComposition, popupColumn, message) {
        assert(windowRow.Layout.fillWidth,
                "provider-composed row must opt into its parent's width allocation")
        assert(popupColumn.width === popupComposition.availableWidth,
                message + ": popup content must use the ScrollView viewport width")
        assert(providerRow.width === popupColumn.width,
                message + ": provider card must receive the popup column width")
        // Overview 2-col: window rows sit in the right column beside the icon,
        // so they are narrower than the full card — not a regression.
        assert(windowRow.width > 0 && windowRow.width <= providerRow.width,
                message + ": summary window row must lay out within the card")
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
        assert(windowRow.progressBar.width < windowRow.width,
                message + ": summary progress bar must share the composed-row width"
                + " (bar=" + windowRow.progressBar.width + ", row=" + windowRow.width + ")")
        assert(windowRow.resetsAtLabel.visible === false && windowRow.resetDescriptionLabel.visible === false,
                message + ": band must show percent only with no reset placeholder when neither reset field is present (D3)")
        var icon = findObject(providerRow, "summaryProviderIcon")
        var name = findObject(providerRow, "providerLabel")
        assert(icon !== null && name !== null, message + ": overview card must expose icon and name")
        var iconPos = icon.mapToItem(providerRow, 0, 0)
        var namePos = name.mapToItem(providerRow, 0, 0)
        assert(iconPos.x < namePos.x,
                message + ": overview icon column must sit left of the name/bars column")
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
            ],
            raw: {
                version: "9.9.9",
                usage: { loginMethod: "google" }
            }
        })
    }

    UsageUi.ProviderRow {
        id: tripleWindowSummaryRow
        width: root.width
        summary: true
        providerData: ({
            provider: "opencodego",
            source: "web",
            windows: [
                { key: "primary", label: "Session", usedPercent: 0, resetsAt: null, resetDescription: null },
                { key: "secondary", label: "Weekly", usedPercent: 73, resetsAt: null, resetDescription: null },
                { key: "tertiary", label: "Monthly", usedPercent: 40, resetsAt: null, resetDescription: null }
            ]
        })
    }

    UsageUi.ProviderRow {
        id: reversedPayloadOrderSummaryRow
        width: root.width
        summary: true
        providerData: ({
            provider: "reversed-payload-order-provider",
            source: "Reversed Payload Order CLI source",
            windows: [
                { key: "secondary", label: "Weekly", usedPercent: 75, resetsAt: null, resetDescription: null },
                { key: "primary", label: "Session", usedPercent: 55, resetsAt: "2026-08-09T14:00:00Z", resetDescription: "Summary reset" }
            ]
        })
    }

    UsageUi.ProviderRow {
        id: singleFiniteSummaryRow
        width: root.width
        summary: true
        providerData: ({
            provider: "single-finite-provider",
            source: "Single Finite CLI source",
            windows: [
                { label: "Session", usedPercent: 65, resetsAt: "2026-08-09T14:00:00Z", resetDescription: "Summary reset" }
            ]
        })
    }

    UsageUi.ProviderRow {
        id: monthlyOnlySummaryRow
        width: root.width
        summary: true
        providerData: ({
            provider: "monthly-only-provider",
            source: "Monthly Only CLI source",
            windows: [
                { label: "Session", usedPercent: null, resetsAt: null, resetDescription: null },
                { label: "Weekly", usedPercent: NaN, resetsAt: null, resetDescription: null },
                { label: "Monthly", usedPercent: 85, resetsAt: null, resetDescription: null }
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
        width: 450
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
        id: zeroCreditsDetailRow
        width: 450
        providerData: ({
            provider: "zero-credits-provider",
            source: "Zero Credits CLI source",
            windows: [{ label: "Session", usedPercent: 10 }],
            raw: {
                credits: { remaining: 0 },
                usage: {
                    updatedAt: "2026-08-17T00:00:00Z",
                    loginMethod: "plus"
                }
            }
        })
    }

    UsageUi.ProviderRow {
        id: largeCostRow
        width: 450
        providerData: ({
            provider: "large-cost-provider",
            source: "Large Cost CLI source",
            windows: [{ label: "Session", usedPercent: 40 }]
        })
        costSnapshot: ({
            provider: "large-cost-provider", source: "local",
            sessionCostUSD: 10.4552, sessionTokens: 139811000,
            last30DaysCostUSD: 245.6, last30DaysTokens: 987654321
        })
    }

    UsageUi.ProviderRow {
        id: costFailureRow
        width: 450
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

    // Single-line summary needs room for label + bar + percent; 200px is still
    // well under the popup minimum (gridUnit * 30) and exercises shrink.
    UsageUi.UsageWindowRow {
        id: constrainedSummaryWindowRow
        width: 200
        summary: true
        windowData: ({ label: "Long Summary Window", usedPercent: 100, resetsAt: null, resetDescription: null })
    }

    ColumnLayout {
        id: popupShell
        width: 200
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
                            { label: "Session", usedPercent: 100, resetsAt: null, resetDescription: null }
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
        assert(countProgressBars(summaryRow) === 2, "summary row must render two progress bars when Session and Weekly are both finite (Overview D10)")
        assert(countUsageWindowRows(summaryRow) === 2, "summary row must render two usage window rows when Session and Weekly are both finite (Overview D10)")
        assert(summaryRow.displayedWindows[0].label === "Session" && summaryRow.displayedWindows[1].label === "Weekly",
               "summary row must order Session before Weekly (Overview D10)")
        assert(summaryRow.providerValue === "summary-provider" && summaryRow.sourceValue === "Summary CLI source", "summary row must preserve provider identity")
        assert(summaryRow.providerText === "Summary-provider",
               "summary display name must capitalize the first letter")

        assert(tripleWindowSummaryRow.displayedWindows.length === 3
               && tripleWindowSummaryRow.displayedWindows[0].label === "Session"
               && tripleWindowSummaryRow.displayedWindows[1].label === "Weekly"
               && tripleWindowSummaryRow.displayedWindows[2].label === "Monthly",
               "overview must show Session+Weekly+Monthly when all three are finite")
        assert(countProgressBars(tripleWindowSummaryRow) === 3,
               "overview must render three progress bars when Session+Weekly+Monthly are finite")
        assert(tripleWindowSummaryRow.providerText === "OpenCode Go",
               "opencodego display name must be OpenCode Go")
        var overviewIcon = findObject(tripleWindowSummaryRow, "summaryProviderIcon")
        assert(overviewIcon !== null && overviewIcon.visible && overviewIcon.isMask === true,
               "overview card must show a theme-adaptive summaryProviderIcon")
        var overviewName = findObject(tripleWindowSummaryRow, "providerLabel")
        assert(overviewName !== null && overviewName.text === "OpenCode Go",
               "overview card providerLabel must use the display name")
        var overviewIconPos = overviewIcon.mapToItem(tripleWindowSummaryRow, 0, 0)
        var overviewNamePos = overviewName.mapToItem(tripleWindowSummaryRow, 0, 0)
        assert(overviewIconPos.x < overviewNamePos.x,
               "overview icon column must sit left of the name/bars column")

        // Hanging indent: window rows (Session/Weekly/Monthly) sit indented
        // under the provider name, not flush with it, matching the
        // reference wireframe's nested list structure.
        var overviewFirstWindowRow = firstUsageWindowRow(tripleWindowSummaryRow)
        assert(overviewFirstWindowRow !== null, "overview card must render at least one usage window row")
        var overviewWindowLabelPos = overviewFirstWindowRow.windowLabel.mapToItem(tripleWindowSummaryRow, 0, 0)
        assert(overviewWindowLabelPos.x > overviewNamePos.x,
               "overview window rows must be indented (hanging indent) relative to the provider name")

        assert(reversedPayloadOrderSummaryRow.displayedWindows.length === 2, "summary row must still render two bars when the payload orders Weekly before Session")
        assert(reversedPayloadOrderSummaryRow.displayedWindows[0].label === "Session" && reversedPayloadOrderSummaryRow.displayedWindows[1].label === "Weekly",
               "summary row must render Session before Weekly regardless of payload order (Overview D10)")
        assert(countProgressBars(reversedPayloadOrderSummaryRow) === 2, "reversed-payload summary row must render two progress bars")

        assert(singleFiniteSummaryRow.displayedWindows.length === 1 && singleFiniteSummaryRow.displayedWindows[0].label === "Session",
               "summary row with only a finite Session window must render exactly that one window")
        assert(countProgressBars(singleFiniteSummaryRow) === 1, "single-finite summary row must render exactly one progress bar")

        assert(monthlyOnlySummaryRow.displayedWindows.length === 1 && monthlyOnlySummaryRow.displayedWindows[0].label === "Monthly",
               "summary row with only a finite Monthly window must fall back to that one window")
        assert(countProgressBars(monthlyOnlySummaryRow) === 1, "Monthly-only summary row must render exactly one progress bar")

        assert(identityOnlyRow.displayedWindows.length === 0, "identity-only summary row must render no displayed windows")
        assert(countUsageWindowRows(identityOnlyRow) === 0, "identity-only summary row must render no usage window rows")
        assert(countProgressBars(identityOnlyRow) === 0, "identity-only summary row must render no progress bar")
        assert(countVisibleUsageDetails(identityOnlyRow) === 0, "identity-only summary row must render no percentage or reset detail")
        assert(identityOnlyRow.providerValue === "identity-only-provider", "identity-only row must preserve provider identity")

        var barsBefore = countProgressBars(activeSummaryRow)
        var rowsBefore = countUsageWindowRows(activeSummaryRow)
        assert(barsBefore === 2, "active summary row must render two progress bars before activation (Session+Weekly both finite)")
        assert(rowsBefore === 2, "active summary row must render two window rows before activation (Session+Weekly both finite)")
        assert(allResetLabelsHidden(activeSummaryRow), "active summary row must hide reset labels before activation")

        activeSummaryRow.forceActiveFocus()
        assert(countProgressBars(activeSummaryRow) === barsBefore, "activating summary row must not reveal additional progress bars")
        assert(countUsageWindowRows(activeSummaryRow) === rowsBefore, "activating summary row must not expand into additional window rows")
        assert(allResetLabelsHidden(activeSummaryRow), "activating summary row must not reveal reset labels")

        // D12: an Overview card's header never exposes the selected-detail-only
        // login badge or version string, even when the raw payload supplies them.
        var summaryLoginLabel = findObject(summaryRow, "loginLabel")
        assert(summaryLoginLabel === null || !summaryLoginLabel.visible,
               "summary row must never show loginLabel, even with a valid raw login method (D12)")
        var summaryVersionLabel = findObject(summaryRow, "versionLabel")
        assert(summaryVersionLabel === null || !summaryVersionLabel.visible,
               "summary row must never show versionLabel, even with a valid raw version (D12)")

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

        // Detail chrome: name/updated/badge + usage/cost. Email/version/org stay off
        // the primary header; credits only when > 0 (enriched has 7).
        assert(findObject(enrichedDetailRow, "emailLabel") !== null
               && !findObject(enrichedDetailRow, "emailLabel").visible,
               "detail header must not show email in primary chrome")
        assert(findObject(enrichedDetailRow, "organizationLabel") !== null
               && !findObject(enrichedDetailRow, "organizationLabel").visible,
               "detail header must not show organization in primary chrome")
        assert(findObject(enrichedDetailRow, "versionLabel") !== null
               && !findObject(enrichedDetailRow, "versionLabel").visible,
               "detail header must not show version in primary chrome")
        assert(findObject(enrichedDetailRow, "creditsRemainingLabel").visible, "enriched row must show remaining credits when > 0")
        assert(findObject(enrichedDetailRow, "resetAvailableLabel").visible, "enriched row must show reset-credit availability")
        assert(findObject(enrichedDetailRow, "costLabel").visible, "enriched row must show the local cost estimate label")
        assert(findObject(enrichedDetailRow, "costSessionLabel").text.indexOf("1,5") !== -1, "enriched row must show session cost")
        assert(findObject(enrichedDetailRow, "costLocalEstimateLabel") !== null
               && findObject(enrichedDetailRow, "costLocalEstimateLabel").visible,
               "local-source cost snapshot must show the local-estimate caption")

        // Zero credits must not clutter detail chrome (reference density).
        var zeroCredits = findObject(zeroCreditsDetailRow, "creditsRemainingLabel")
        assert(zeroCredits !== null && !zeroCredits.visible,
               "credits remaining of 0 must stay hidden in the detail body")
        assert(findObject(zeroCreditsDetailRow, "providerLabel").visible,
               "zero-credits detail must still show the provider name")
        assert(findObject(zeroCreditsDetailRow, "updatedAtLabel").visible,
               "zero-credits detail must still show updated-at when present")
        assert(findObject(zeroCreditsDetailRow, "loginLabel").visible,
               "zero-credits detail must still show the plan/login badge when present")
        assert(countProgressBars(zeroCreditsDetailRow) === 1,
               "detail mode must render the usage progress bar for a finite Session window")
        var zeroSessionBar = findObject(zeroCreditsDetailRow, "detailUsageProgressBar")
        assert(zeroSessionBar !== null && zeroSessionBar.visible && zeroSessionBar.height > 0,
               "detail usage bar must be a visible detailUsageProgressBar with height")

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

        // Cost-present and Cost-absent selected-provider states must retain
        // bounded visible content and semantic names before visual capture.
        var presentProviderLabel = findObject(enrichedDetailRow, "providerLabel")
        var absentProviderLabel = findObject(costFailureRow, "providerLabel")
        var presentCostLabel = findObject(enrichedDetailRow, "costLabel")
        var absentCostLabel = findObject(costFailureRow, "costLabel")
        assert(presentCostLabel !== null && presentCostLabel.visible,
                "cost-present selected provider must expose its visible cost label")
        assert(absentCostLabel === null || !absentCostLabel.visible,
                "cost-absent selected provider must not expose a cost label")
        assert(enrichedDetailRow.Accessible.name.indexOf("Enriched-provider") !== -1
                && costFailureRow.Accessible.name.indexOf("Cost-failure-provider") !== -1,
                "both selected-provider states must expose accessible provider names")
        assert(presentProviderLabel.Accessible.name.length > 0 && absentProviderLabel.Accessible.name.length > 0,
                "provider headers must expose accessible labels")
        assert(isWithinRow(enrichedDetailRow, presentProviderLabel)
                && isWithinRow(enrichedDetailRow, presentCostLabel),
                "cost-present selected provider labels must remain within row bounds")
        assert(isWithinRow(costFailureRow, absentProviderLabel),
                "cost-absent selected provider header must remain within row bounds")

        // Large cost/token values must render as plain grouped/abbreviated numbers,
        // never scientific notation or a locale-dependent decimal separator.
        var largeCostSession = findObject(largeCostRow, "costSessionLabel")
        var largeCostLast30 = findObject(largeCostRow, "costLast30DaysLabel")
        assert(largeCostSession.text.indexOf("e+") === -1 && largeCostLast30.text.indexOf("e+") === -1,
               "large cost/token values must never render in scientific notation")
        assert(largeCostSession.text.indexOf("10,46") !== -1, "session cost must round to two decimals with comma-decimal format")
        assert(largeCostSession.text.indexOf("139,8M") !== -1, "session tokens must abbreviate to one-decimal M with comma-decimal separator")
        assert(largeCostLast30.text.indexOf("245,60") !== -1, "last-30-days cost must round to two decimals with comma-decimal format")
        assert(largeCostLast30.text.indexOf("987,7M") !== -1, "last-30-days tokens must abbreviate to one-decimal M with comma-decimal separator")

        var providerLabel = findObject(row, "providerLabel")
        var sourceLabel = findObject(row, "sourceLabel")
        assert(providerLabel !== null && sourceLabel !== null, "provider labels must remain discoverable")
        assert(providerLabel.elide === Text.ElideRight && sourceLabel.elide === Text.ElideRight, "name and source must elide")
        assert(row.Accessible.description.indexOf("CLI raw source") !== -1, "accessible description must expose full source")

        assert(windowRow.progressBar.visible === true && windowRow.percentageLabel.text.indexOf("72") !== -1, "finite percentage")
        // D2: resetDescription is verbatim and takes precedence over the resetsAt fallback.
        assert(windowRow.resetDescriptionLabel.visible === true && windowRow.resetDescriptionLabel.text === "Exact reset note",
               "band must show verbatim resetDescription when present (D2)")
        assert(windowRow.resetsAtLabel.visible === false,
               "resetsAt fallback must be hidden when resetDescription is present (D2 precedence)")
        assert(summaryWindowRow.progressBar.visible === true && summaryWindowRow.percentageLabel.text.indexOf("72") !== -1, "summary window row must show percentage and bar")

        assert(summaryWindowRow.resetsAtLabel.visible === false && summaryWindowRow.resetDescriptionLabel.visible === false
               && summaryWindowRow.resetsAtLabel.parent.visible === false,
               "summary window row must hide reset fields and their containing band (D14-D15: band RowLayout parent itself must be hidden, not just its child labels)")

        // percentageLabel handle resolves to one of two Label instances.
        // Both must exist and never be visible simultaneously for a finite percent.
        var summaryPercentLabel = findObject(summaryWindowRow, "summaryPercentageLabel")
        var bandPercentLabel = findObject(summaryWindowRow, "bandPercentageLabel")
        assert(summaryPercentLabel !== null && bandPercentLabel !== null,
               "summary window row must expose both the summary and band percentage label instances")
        assert(summaryPercentLabel.visible !== bandPercentLabel.visible,
               "summary and band percentage label instances must never both be visible for a finite percent")
        assert(summaryWindowRow.percentageLabel === summaryPercentLabel,
               "percentageLabel handle must resolve to the inline instance in summary mode")
        assert(windowRow.percentageLabel === findObject(windowRow, "bandPercentageLabel"),
               "percentageLabel handle must resolve to the band instance in detail mode")

        windowRow.windowData = { label: "Monthly", usedPercent: null, resetsAt: null, resetDescription: null }
        assert(windowRow.progressBar.visible === false && windowRow.percentageLabel.text.indexOf("%") === -1, "null percentage")
        windowRow.windowData = { label: "Daily", usedPercent: "80", resetsAt: null, resetDescription: null }
        assert(windowRow.progressBar.visible === false, "string percentage")
        windowRow.windowData = { label: "Weekly", usedPercent: Infinity, resetsAt: null, resetDescription: null }
        assert(windowRow.progressBar.visible === false, "infinite percentage")

        // D3: neither resetDescription nor resetsAt present -> percent only, no placeholder.
        windowRow.windowData = { label: "Daily", usedPercent: 15, resetsAt: null, resetDescription: null }
        assert(windowRow.percentageLabel.visible === true && windowRow.percentageLabel.text.indexOf("15") !== -1,
               "percent must remain visible with neither reset field present (D3)")
        assert(windowRow.resetsAtLabel.visible === false && windowRow.resetDescriptionLabel.visible === false,
               "band must show percent only with no reset placeholder when neither field is present (D3)")

        // D2 fallback: resetsAt renders verbatim "Reset: {resetsAt}" only when resetDescription is absent.
        windowRow.windowData = { label: "Weekly", usedPercent: 42, resetsAt: "2026-08-09T15:00:00Z", resetDescription: null }
        assert(windowRow.resetsAtLabel.visible === true && windowRow.resetsAtLabel.text === "Reset: 2026-08-09T15:00:00Z",
               "resetsAt fallback must render verbatim 'Reset: {resetsAt}' when resetDescription is absent (D2 fallback)")
        assert(windowRow.resetDescriptionLabel.visible === false,
               "resetDescriptionLabel must stay hidden when resetDescription is absent")

        windowRow.windowData = { label: "Hourly", usedPercent: NaN, resetsAt: "2026-08-09T13:00:00Z", resetDescription: "NaN reset" }
        assert(windowRow.progressBar.visible === false, "NaN percentage")
        assert(windowRow.resetDescriptionLabel.visible === true && windowRow.resetDescriptionLabel.text === "NaN reset",
               "resetDescription must stay exact and be shown verbatim when present (D2)")
        assert(windowRow.resetsAtLabel.visible === false,
               "resetsAt fallback must be hidden when resetDescription is present, even mid-sequence (D2 precedence)")

        windowRow.windowData = { label: "Session", usedPercent: 72, resetsAt: "2026-08-09T12:00:00Z", resetDescription: "Exact reset note" }
        windowRow.compact = true
        assert(windowRow.percentageLabel.text.indexOf("72") !== -1 && windowRow.progressBar.visible === false, "compact keeps text, hides bar")
        assert(windowRow.resetsAtLabel.elide === Text.ElideRight && windowRow.resetsAtLabel.wrapMode === Text.NoWrap,
               "compact reset text must elide without using an invalid wrap mode")
        assert(windowRow.resetDescriptionLabel.elide === Text.ElideRight && windowRow.resetDescriptionLabel.wrapMode === Text.NoWrap,
               "compact reset descriptions must elide without using an invalid wrap mode")
        windowRow.compact = false
        assert(windowRow.resetsAtLabel.elide === Text.ElideRight && windowRow.resetsAtLabel.wrapMode === Text.NoWrap,
               "detail reset text must elide on one line (reference density)")
        assert(windowRow.resetDescriptionLabel.elide === Text.ElideRight && windowRow.resetDescriptionLabel.wrapMode === Text.NoWrap,
               "detail reset description must elide on one line (reference density)")

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
                root.assertSummaryInlineOrder(constrainedSummaryWindowRow, "summary constrained row inline order")
                root.assertDetailPercentBelowBar(constrainedWindowRow, "direct constrained row detail lock")
                root.assertProviderPopupGeometry(constrainedProviderRow, providerWindowRow, popupComposition, popupColumn,
                                            "narrow popup composition")
                narrowBarWidth = providerWindowRow.progressBar.width
                stage++
                popupShell.width = 320
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
