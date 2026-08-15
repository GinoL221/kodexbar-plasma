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
        verify(version.visible)
        compare(version.text, "9.8.7")
        verify(login.visible)
        compare(login.text, "synthetic-login")
        verify(findText(validRow, "Session") !== null)

        var malformedVersion = findByObjectName(malformedRow, "versionLabel")
        var malformedLogin = findByObjectName(malformedRow, "loginLabel")
        verify(malformedVersion.visible)
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
        verify(email.visible)
        compare(email.text, "synthetic@example.invalid")
        verify(organization.visible)
        compare(organization.text, "Synthetic Labs Inc.")
        verify(updatedAt.visible)
        verify(creditsRemaining.visible)
        verify(creditsRemaining.text.indexOf("12") !== -1)
        verify(resetAvailable.visible)
        verify(resetAvailable.text.indexOf("2") !== -1)
        verify(findText(validRow, "On pace, 42% used") !== null)
        verify(!validRow.resetCreditsSection.expanded)
        verify(findText(validRow, "2026-09-01T00:00:00Z") === null, "collapsed disclosure must not render expiry rows")
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
        verify(findByObjectName(maliciousRow, "versionLabel").visible)
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

        // A correctly-shaped, authorized identity field must still display
        // even inside an otherwise hostile payload; every incorrectly-shaped
        // or opaque field around it must stay hidden.
        var email = findByObjectName(maliciousRow, "emailLabel")
        verify(email.visible)
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
        verify(email.visible)
        compare(email.text, "gxxxxxxxxxxxx@gmail.com")
        verify(!findByObjectName(codexFixtureRow, "organizationLabel").visible)
        verify(!codexFixtureRow.resetCreditsSection.visible)
        var creditsRemaining = findByObjectName(codexFixtureRow, "creditsRemainingLabel")
        verify(creditsRemaining.visible)
        verify(creditsRemaining.text.indexOf("0") !== -1)
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
        verify(validRow.Accessible.name.indexOf("synthetic-provider") !== -1)
        verify(malformedRow.Accessible.name.indexOf("malformed-provider") !== -1)
        verify(providerLabel.Accessible.name.length > 0)
        verify(sourceLabel.Accessible.name.length > 0)
        verify(validRow.width === testWindow.width && malformedRow.width === testWindow.width)
        verify(validRow.x >= 0 && validRow.x + validRow.width <= testWindow.width)
        verify(malformedRow.x >= 0 && malformedRow.x + malformedRow.width <= testWindow.width)
        verify(providerLabel.x >= 0 && providerLabel.x + providerLabel.width <= validRow.width)
        verify(sourceLabel.x >= 0 && sourceLabel.x + sourceLabel.width <= validRow.width)
        verify(costPresent.x >= 0 && costPresent.x + costPresent.width <= validRow.width)
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
}
