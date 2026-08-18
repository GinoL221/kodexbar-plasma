import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui" as UsageUi

TestCase {
    id: testCase
    name: "ProviderDetailsIntegration"
    when: windowShown

    Window {
        id: testWindow
        width: 450
        height: 400
        visible: true

        Item {
            id: host
            anchors.fill: parent

            UsageUi.ProviderRow {
                id: validRow
                width: parent.width
                providerData: ({
                    provider: "synthetic-provider",
                    source: "synthetic-source",
                    windows: [{ label: "Session", usedPercent: 42 }],
                    raw: {
                        version: "9.8.7",
                        pace: { primary: { summary: "On pace, 42% used" } },
                        credits: { remaining: 12 },
                        usage: {
                            loginMethod: "synthetic-login",
                            updatedAt: "2026-08-14T19:01:20Z",
                            identity: { accountEmail: "synthetic@example.invalid", accountOrganization: "Synthetic Labs Inc." },
                            codexResetCredits: {
                                availableCount: 2,
                                credits: [
                                    { amount: 1, expiresAt: "2026-09-01T00:00:00Z" },
                                    { amount: 1, expiresAt: "2026-10-01T00:00:00Z" }
                                ]
                            },
                            details: [{
                                title: "Synthetic limits",
                                rows: [{ label: "Requests", value: "42" }]
                            }]
                        }
                    }
                })
                costSnapshot: ({
                    provider: "synthetic-provider",
                    source: "local",
                    sessionCostUSD: 1.5,
                    sessionTokens: 1000,
                    last30DaysCostUSD: 12,
                    last30DaysTokens: 50000
                })
            }

            UsageUi.ProviderRow {
                id: malformedRow
                y: validRow.height
                width: parent.width
                providerData: ({
                    provider: "malformed-provider",
                    source: "malformed-source",
                    windows: [{ label: "Session", usedPercent: 55 }],
                    raw: {
                        version: "2.0",
                        usage: { loginMethod: "safe-login", details: { invalid: true } }
                    }
                })
            }

            UsageUi.ProviderRow { id: absentMetadataRow; y: malformedRow.y + malformedRow.height; width: parent.width; providerData: ({ provider: "absent-metadata", source: "synthetic-source", windows: [{ label: "Session", usedPercent: 1 }], raw: { usage: { details: [] } } }) }
            UsageUi.ProviderRow { id: emptyMetadataRow; y: absentMetadataRow.y + absentMetadataRow.height; width: parent.width; providerData: ({ provider: "empty-metadata", source: "synthetic-source", windows: [{ label: "Session", usedPercent: 1 }], raw: { version: "", usage: { loginMethod: "", details: [] } } }) }
            UsageUi.ProviderRow { id: malformedMetadataRow; y: emptyMetadataRow.y + emptyMetadataRow.height; width: parent.width; providerData: ({ provider: "malformed-metadata", source: "synthetic-source", windows: [{ label: "Session", usedPercent: 1 }], raw: { version: 7, usage: { loginMethod: {}, details: [] } } }) }
            // updatedAt present but not a parseable ISO-8601 stamp -- must stay
            // omitted, never render as raw "Updated: not-a-real-date" text.
            UsageUi.ProviderRow { id: malformedUpdatedAtRow; y: malformedMetadataRow.y + malformedMetadataRow.height; width: parent.width; providerData: ({ provider: "malformed-updated-at", source: "synthetic-source", windows: [{ label: "Session", usedPercent: 1 }], raw: { usage: { updatedAt: "not-a-real-date", details: [] } } }) }

            UsageUi.ProviderRow {
                id: maliciousRow
                y: malformedRow.y + malformedRow.height
                width: parent.width
                providerData: ({
                    provider: "malicious-provider",
                    source: "malicious-source",
                    windows: [{ label: "Session", usedPercent: 65 }],
                    raw: {
                        version: "3.0",
                        pace: { secondary: { stage: "excluded pace" } }, credits: { remaining: "excluded credits" }, codexResetCredits: "excluded reset credits", providerCost: "excluded cost", token: "excluded token",
                        usage: {
                            loginMethod: "approved-login",
                            identity: {
                                accountEmail: "authorized@example.invalid",
                                accountOrganization: "5f2c9b7a1e3d4f6a8b9c0d1e2f3a4b5c",
                                token: "identity token"
                            },
                            codexResetCredits: { availableCount: 0, credits: [] },
                            details: [
                                { title: "Approved details", rows: [{ label: "Approved label", value: "Approved value" }] },
                                { title: "Email secret@example.invalid", rows: [{ label: "Email", value: "secret@example.invalid" }] },
                                { title: "Organization", rows: [{ label: "Organization", value: "Synthetic Org" }] },
                                { title: "Pace", rows: [{ label: "Pace", value: "fast" }] },
                                { title: "Credits", rows: [{ label: "Credits", value: "10" }] },
                                { title: "Cost", rows: [{ label: "Cost", value: "$1" }] },
                                { title: "Tokens", rows: [{ label: "Tokens", value: "100" }] },
                                { title: "Reach us", rows: [{ label: "Support", value: "help@example.com" }] }
                            ]
                        }
                    }
                })
            }

            UsageUi.ProviderRow {
                id: codexFixtureRow
                y: maliciousRow.y + maliciousRow.height
                width: parent.width
                providerData: ({
                    provider: "codex",
                    source: "oauth",
                    windows: [{ label: "Weekly", usedPercent: 67, resetsAt: "2026-08-20T12:21:18Z", resetDescription: "Aug 20 at 9:21 AM" }],
                    raw: {
                        version: "0.147.0",
                        pace: { secondary: { stage: "farAhead", summary: "49% in deficit | Expected 18% used | Runs out in 15h 7m" } },
                        credits: { remaining: 0 },
                        usage: {
                            loginMethod: "plus",
                            codexResetCredits: { credits: [], availableCount: 0 },
                            identity: { accountEmail: "gxxxxxxxxxxxx@gmail.com", loginMethod: "plus" },
                            accountEmail: "gxxxxxxxxxxxx@gmail.com"
                        }
                    }
                })
            }

            UsageUi.StatusFooter {
                id: statusFooterWithProvider
                y: codexFixtureRow.y + codexFixtureRow.height
                width: 200
                phase: "ready"
            }

            UsageUi.StatusFooter {
                id: statusFooterOverview
                y: statusFooterWithProvider.y + statusFooterWithProvider.height
                width: 200
                phase: "ready"
            }

            UsageUi.StatusFooter {
                id: statusFooterLoading
                y: statusFooterOverview.y + statusFooterOverview.height
                width: 200
                phase: "loading"
            }

            UsageUi.StatusFooter {
                id: statusFooterError
                y: statusFooterLoading.y + statusFooterLoading.height
                width: 200
                phase: "error"
            }
        }

        QQC2.ScrollView {
            id: boundedDetailsView
            x: 250
            width: 180
            height: 120
            contentWidth: availableWidth
            QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
                id: horizontalBar
                policy: QQC2.ScrollBar.AlwaysOff
            }
            QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                id: verticalBar
                policy: QQC2.ScrollBar.AsNeeded
            }

            ColumnLayout {
                width: boundedDetailsView.availableWidth

                UsageUi.ProviderRow {
                    id: overHeightRow
                    Layout.fillWidth: true
                    providerData: ({
                    provider: "over-height-provider",
                    source: "synthetic-source",
                    windows: [{ label: "Session", usedPercent: 1 }],
                    raw: {
                        version: "1.0",
                        usage: {
                            loginMethod: "synthetic-login",
                            details: [{
                                title: "Reachable details",
                                rows: [
                                    { label: "Row 1", value: "value 1" }, { label: "Row 2", value: "value 2" },
                                    { label: "Row 3", value: "value 3" }, { label: "Row 4", value: "value 4" },
                                    { label: "Row 5", value: "value 5" }, { label: "Row 6", value: "value 6" },
                                    { label: "Row 7", value: "value 7" }, { label: "Row 8", value: "value 8" }
                                ]
                            }]
                        }
                    }
                    })
                }
            }
        }
    }

    function findByObjectName(item, name) {
        if (item.objectName === name)
            return item
        for (var index = 0; index < item.children.length; ++index) {
            var result = findByObjectName(item.children[index], name)
            if (result)
                return result
        }
        return null
    }

    function findText(item, text) {
        if (item.text !== undefined && item.text === text)
            return item
        for (var index = 0; index < item.children.length; ++index) {
            var result = findText(item.children[index], text)
            if (result)
                return result
        }
        return null
    }

    function findTextContaining(item, substring) {
        if (item.text !== undefined && String(item.text).indexOf(substring) !== -1)
            return item
        for (var index = 0; index < item.children.length; ++index) {
            var result = findTextContaining(item.children[index], substring)
            if (result)
                return result
        }
        return null
    }

    function assertMetadataOmitted(row) {
        var version = findByObjectName(row, "versionLabel")
        var login = findByObjectName(row, "loginLabel")
        verify(!version.visible)
        compare(version.text, "")
        verify(!login.visible)
        compare(login.text, "")
    }

    function assertEnrichmentOmitted(row) {
        verify(!findByObjectName(row, "emailLabel").visible)
        verify(!findByObjectName(row, "organizationLabel").visible)
        verify(!findByObjectName(row, "updatedAtLabel").visible)
        verify(!findByObjectName(row, "creditsRemainingLabel").visible)
        verify(!row.resetCreditsSection.visible)
    }

    function initTestCase() {
        testWindow.requestActivate()
        tryCompare(testWindow, "active", true)
    }

    function test_conditionalMetadataAndMalformedDetailsKeepUsageVisible() {
        var version = findByObjectName(validRow, "versionLabel")
        var login = findByObjectName(validRow, "loginLabel")
        // Version stays off primary chrome; login badge remains.
        verify(!version.visible)
        compare(version.text, "9.8.7")
        verify(login.visible)
        compare(login.text, "synthetic-login")
        verify(findText(validRow, "Session") !== null)

        var malformedVersion = findByObjectName(malformedRow, "versionLabel")
        var malformedLogin = findByObjectName(malformedRow, "loginLabel")
        verify(!malformedVersion.visible)
        compare(malformedVersion.text, "2.0")
        verify(malformedLogin.visible)
        compare(malformedLogin.text, "safe-login")
        verify(findText(malformedRow, "Session") !== null)
        verify(!malformedRow.providerDetails.visible)

        var email = findByObjectName(validRow, "emailLabel")
        var organization = findByObjectName(validRow, "organizationLabel")
        var updatedAt = findByObjectName(validRow, "updatedAtLabel")
        var creditsRemaining = findByObjectName(validRow, "creditsRemainingLabel")
        var resetAvailable = findByObjectName(validRow, "resetAvailableLabel")
        verify(!email.visible)
        compare(email.text, "synthetic@example.invalid")
        verify(!organization.visible)
        compare(organization.text, "Synthetic Labs Inc.")
        verify(updatedAt.visible)
        verify(updatedAt.text !== "Updated: 2026-08-14T19:01:20Z",
            "updatedAtLabel must render a relative label, not the raw ISO fallback, for a parseable stamp")
        verify(updatedAt.text.indexOf("2026-08-14T19:01:20Z") === -1,
            "updatedAtLabel must never leak the raw ISO stamp when relative formatting succeeds")
        verify(creditsRemaining.visible)
        verify(creditsRemaining.text.indexOf("12") !== -1)
        verify(resetAvailable.visible)
        verify(resetAvailable.text.indexOf("2") !== -1)
        verify(findText(validRow, "On pace, 42% used") !== null)
        verify(!validRow.resetCreditsSection.expanded)
        verify(findText(validRow, "2026-09-01T00:00:00Z") === null, "collapsed disclosure must not render expiry rows")
    }

    function test_updatedAtOmittedForUnparseableValue() {
        var updatedAt = findByObjectName(malformedUpdatedAtRow, "updatedAtLabel")
        verify(!updatedAt.visible,
            "a present but unparseable updatedAt must be omitted, never shown as raw text (D-relative)")
        compare(updatedAt.text, "")
    }

    function test_invalidMetadataIsOmittedWithoutPlaceholdersInRealProviderRows() {
        assertMetadataOmitted(absentMetadataRow)
        assertMetadataOmitted(emptyMetadataRow)
        assertMetadataOmitted(malformedMetadataRow)
        verify(findText(absentMetadataRow, "Session") !== null)
    }

    function test_invalidOrMissingEnrichmentIsOmitted() {
        assertEnrichmentOmitted(absentMetadataRow)
        assertEnrichmentOmitted(emptyMetadataRow)
        assertEnrichmentOmitted(malformedMetadataRow)
    }

    function test_returnAndSpaceToggleRealDisclosureAccessibleState() {
        var details = validRow.providerDetails
        verify(details.visible)
        verify(!details.expanded)
        details.disclosureButton.forceActiveFocus()
        verify(details.disclosureButton.activeFocus)
        compare(testWindow.activeFocusItem, details.disclosureButton)
        wait(0)
        keyClick(Qt.Key_Return)
        verify(details.expanded)
        verify(details.disclosureButton.Accessible.description.indexOf("Collapse") !== -1)
        keyClick(Qt.Key_Space)
        verify(!details.expanded)
        verify(details.disclosureButton.Accessible.description.indexOf("Expand") !== -1)
    }

    function test_returnAndSpaceToggleResetCreditsDisclosureAccessibleState() {
        var reset = validRow.resetCreditsSection
        verify(reset.visible)
        verify(!reset.expanded)
        reset.disclosureButton.forceActiveFocus()
        verify(reset.disclosureButton.activeFocus)
        compare(testWindow.activeFocusItem, reset.disclosureButton)
        wait(0)
        keyClick(Qt.Key_Return)
        verify(reset.expanded)
        verify(reset.disclosureButton.Accessible.description.indexOf("Collapse") !== -1)
        verify(findTextContaining(validRow, "2026-09-01T00:00:00Z") !== null)
        keyClick(Qt.Key_Space)
        verify(!reset.expanded)
        verify(reset.disclosureButton.Accessible.description.indexOf("Expand") !== -1)
    }

    function test_maliciousProviderDisplaysOnlyApprovedFields() {
        var details = maliciousRow.providerDetails
        // Version/email stay off primary chrome even when validated.
        verify(!findByObjectName(maliciousRow, "versionLabel").visible)
        compare(findByObjectName(maliciousRow, "versionLabel").text, "3.0")
        verify(findByObjectName(maliciousRow, "loginLabel").visible)
        compare(findByObjectName(maliciousRow, "loginLabel").text, "approved-login")
        verify(details.visible)
        details.expanded = true
        verify(findText(details, "Approved details") !== null)
        verify(findText(details, "Approved value") !== null)
        verify(findText(details, "secret@example.invalid") === null)
        verify(findText(details, "Synthetic Org") === null)
        verify(findText(details, "fast") === null)
        verify(findText(details, "10") === null)
        verify(findText(details, "$1") === null)
        verify(findText(details, "100") === null)
        verify(findText(details, "help@example.com") === null)
        verify(findText(details, "Reach us") === null)
        verify(findText(details, "Support") === null)

        var email = findByObjectName(maliciousRow, "emailLabel")
        verify(!email.visible)
        compare(email.text, "authorized@example.invalid")
        verify(!findByObjectName(maliciousRow, "organizationLabel").visible)
        verify(!maliciousRow.resetCreditsSection.visible)
        verify(!findByObjectName(maliciousRow, "creditsRemainingLabel").visible)

        var excludedValues = ["5f2c9b7a1e3d4f6a8b9c0d1e2f3a4b5c", "excluded pace", "excluded credits", "excluded reset credits", "excluded cost", "excluded token", "identity token", "help@example.com"]
        compare(excludedValues.length, 8)
        for (var index = 0; index < excludedValues.length; ++index)
            verify(findText(maliciousRow, excludedValues[index]) === null)
    }

    function test_fixturePiiRemainsFailClosedForRealCapturedShape() {
        var email = findByObjectName(codexFixtureRow, "emailLabel")
        // Email is validated but kept off primary chrome (PII / density).
        verify(!email.visible)
        compare(email.text, "gxxxxxxxxxxxx@gmail.com")
        verify(!findByObjectName(codexFixtureRow, "organizationLabel").visible)
        verify(!codexFixtureRow.resetCreditsSection.visible)
        var creditsRemaining = findByObjectName(codexFixtureRow, "creditsRemainingLabel")
        // Zero credits must not clutter the detail body.
        verify(!creditsRemaining.visible)
        verify(findText(codexFixtureRow, "49% in deficit | Expected 18% used | Runs out in 15h 7m") !== null)
    }

    function test_themeAdaptiveDisclosureIsReadable() {
        var details = validRow.providerDetails
        verify(details.disclosureButton.visible)
        verify(details.disclosureButton.Accessible.name.length > 0)
        verify(Kirigami.Theme.textColor.a > 0)
    }

    function test_selectedProviderCostStatesStayBoundedAndAccessible() {
        var costPresent = findByObjectName(validRow, "costLabel")
        var costAbsent = findByObjectName(malformedRow, "costLabel")
        var providerLabel = findByObjectName(validRow, "providerLabel")
        var sourceLabel = findByObjectName(validRow, "sourceLabel")

        verify(costPresent.visible)
        verify(!costAbsent.visible)
        verify(validRow.Accessible.name.indexOf("Synthetic-provider") !== -1
               || validRow.Accessible.name.indexOf("synthetic-provider") !== -1)
        verify(malformedRow.Accessible.name.indexOf("Malformed-provider") !== -1
               || malformedRow.Accessible.name.indexOf("malformed-provider") !== -1)
        verify(providerLabel.Accessible.name.length > 0)
        // Source is header-hidden but still carried on Accessible.description.
        verify(!sourceLabel.visible)
        verify(validRow.Accessible.description.indexOf("synthetic-source") !== -1)
        verify(validRow.width === testWindow.width && malformedRow.width === testWindow.width)
        verify(validRow.x >= 0 && validRow.x + validRow.width <= testWindow.width)
        verify(malformedRow.x >= 0 && malformedRow.x + malformedRow.width <= testWindow.width)
        verify(providerLabel.x >= 0 && providerLabel.x + providerLabel.width <= validRow.width)
        verify(costPresent.x >= 0 && costPresent.x + costPresent.width <= validRow.width)
    }

    function test_headerBadgeOccupiesRightColumnWhenLoginMethodValid() {
        var login = findByObjectName(validRow, "loginLabel")
        var provider = findByObjectName(validRow, "providerLabel")
        verify(login.visible)
        compare(login.text, "synthetic-login")

        // The badge lives in a right-aligned column: its right edge must reach
        // the row's right edge, and it must start to the right of the left
        // column's identity label instead of stacking directly beneath it.
        var loginRight = login.mapToItem(validRow, login.width, 0).x
        var providerLeft = provider.mapToItem(validRow, 0, 0).x
        var loginLeft = login.mapToItem(validRow, 0, 0).x
        verify(loginRight > validRow.width - Kirigami.Units.smallSpacing * 2,
               "badge right edge (" + loginRight + ") must reach row right edge (" + validRow.width + ")")
        verify(loginLeft > providerLeft,
               "badge (x=" + loginLeft + ") must sit right of the left identity column (x=" + providerLeft + "), not beneath it")
    }

    function test_headerBadgeOmittedWithoutPlaceholderLeavesLeftColumnUnaffected() {
        var login = findByObjectName(emptyMetadataRow, "loginLabel")
        var provider = findByObjectName(emptyMetadataRow, "providerLabel")
        var source = findByObjectName(emptyMetadataRow, "sourceLabel")
        verify(!login.visible)
        compare(login.text, "")
        verify(provider.visible)
        compare(provider.text, "Empty-metadata")
        // Source stays on Accessible.description only — body header is name-first.
        verify(!source.visible)
        verify(emptyMetadataRow.Accessible.description.indexOf("synthetic-source") !== -1)
        verify(findText(emptyMetadataRow, "Unknown") === null)
    }

    function test_expandedOverHeightDetailsAreVerticallyReachableWithoutHorizontalOverflow() {
        var details = overHeightRow.providerDetails
        details.expanded = true
        tryVerify(function() { return verticalBar.size < 1 }, 1000,
                  "over-height content must expose a vertical scrollbar (size=" + verticalBar.size
                  + ", row=" + overHeightRow.height + ")")
        compare(horizontalBar.policy, QQC2.ScrollBar.AlwaysOff)
        verify(!horizontalBar.visible)
        verticalBar.position = 1
        wait(0)
        var lastValue = findText(overHeightRow, "value 8")
        verify(lastValue !== null)
        verify(verticalBar.position > 0)
    }

    function test_footerShowsStatus() {
        var status = findByObjectName(statusFooterWithProvider, "footerStatusLabel")
        verify(status.visible)
        compare(status.text, "Ready")

        // Status is shown the same way regardless of provider selection --
        // the footer no longer carries a selectedProvider concept at all.
        var overviewStatus = findByObjectName(statusFooterOverview, "footerStatusLabel")
        verify(overviewStatus.visible)
        compare(overviewStatus.text, "Ready")
    }

    function test_footerReflectsLoadingAndErrorPhases() {
        var loadingStatus = findByObjectName(statusFooterLoading, "footerStatusLabel")
        compare(loadingStatus.text, "Loading usage…")
        var errorStatus = findByObjectName(statusFooterError, "footerStatusLabel")
        compare(errorStatus.text, "Error")
    }

    function test_footerExcludesCountsControlsAndTimestamp() {
        var footers = [statusFooterWithProvider, statusFooterOverview, statusFooterLoading, statusFooterError]
        for (var i = 0; i < footers.length; i++) {
            var footer = footers[i]
            verify(findByObjectName(footer, "footerUpdatedAtLabel") === null)
            verify(findByObjectName(footer, "providerCountLabel") === null)
            verify(findByObjectName(footer, "errorCountLabel") === null)
            verify(findByObjectName(footer, "settingsButton") === null)
            verify(findByObjectName(footer, "aboutButton") === null)
            verify(findByObjectName(footer, "quitButton") === null)
            verify(findByObjectName(footer, "addAccountButton") === null)
            verify(findText(footer, "Settings") === null)
            verify(findText(footer, "About") === null)
            verify(findText(footer, "Quit") === null)
            verify(findText(footer, "Add Account") === null)
            verify(findText(footer, "Updated") === null)
        }
    }
}
