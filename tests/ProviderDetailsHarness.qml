import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../contents/ui" as UsageUi
import "../contents/code/ProviderDetails.mjs" as ProviderDetails

Item {
    id: root
    width: 160
    height: 640
    property bool assertionFailed: false

    function assert(c, m) {
        if (!c) {
            console.error("ProviderDetailsHarness failure:", m)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(m)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    function firstLabelWithText(item, text) {
        if (item.text !== undefined && String(item.text) === text) return item
        for (var i = 0; i < item.children.length; i++) {
            var result = firstLabelWithText(item.children[i], text)
            if (result !== null) return result
        }
        return null
    }

    function labelColorOk(label) {
        var c = label.color
        return c === Kirigami.Theme.textColor
            || c === Kirigami.Theme.disabledTextColor
            || c === Kirigami.Theme.negativeTextColor
            || c === Kirigami.Theme.highlightedTextColor
    }

    function hasHardcodedColor(item) {
        var itemString = item.toString()
        if (itemString.indexOf("Label") !== -1 && item.color !== undefined) {
            if (!labelColorOk(item)) return true
        }
        for (var i = 0; i < item.children.length; i++) {
            if (hasHardcodedColor(item.children[i])) return true
        }
        return false
    }

    function assertWrapAndTheme(label, message) {
        assert(label.wrapMode === Text.WordWrap, message + ": label must wrap")
        assert(label.Layout.minimumWidth === 0, message + ": label must allow zero minimum width")
        assert(label.textFormat === Text.PlainText, message + ": label must render plain text")
    }

    Component.onCompleted: {
        var rawBase = {
            provider: "test-provider",
            source: "test-source",
            version: "1.2.3",
            usage: {
                loginMethod: "oauth",
                details: [
                    {
                        title: "Limits",
                        rows: [
                            { label: "Requests", value: "1200", secondaryValue: "this month" },
                            { label: "Plan", value: "Pro" }
                        ]
                    }
                ]
            },
            identity: { loginMethod: "ignored-identity" }
        }

        assert(ProviderDetails.validVersion({ raw: rawBase }) === "1.2.3", "valid version must be returned")
        assert(ProviderDetails.validVersion({ raw: {} }) === "", "missing version must be omitted")
        assert(ProviderDetails.validVersion({ raw: { version: "" } }) === "", "empty version must be omitted")
        assert(ProviderDetails.validVersion({ raw: { version: 123 } }) === "", "non-string version must be omitted")
        assert(ProviderDetails.validVersion({ raw: { version: null } }) === "", "null version must be omitted")

        assert(ProviderDetails.validLoginMethod({ raw: rawBase }) === "oauth", "valid usage loginMethod must be returned")
        assert(ProviderDetails.validLoginMethod({ raw: { identity: { loginMethod: "identity-only" } } }) === "",
               "identity-only loginMethod must be ignored")
        assert(ProviderDetails.validLoginMethod({ raw: { usage: { loginMethod: "" } } }) === "",
               "empty usage loginMethod must be omitted")
        assert(ProviderDetails.validLoginMethod({ raw: { usage: { loginMethod: 123 } } }) === "",
               "non-string usage loginMethod must be omitted")
        assert(ProviderDetails.validLoginMethod({ raw: { usage: { identity: { loginMethod: "conflict" }, loginMethod: "winner" } } }) === "winner",
               "conflicting identity loginMethod must lose to usage loginMethod")
        assert(ProviderDetails.validLoginMethod({ raw: { usage: { identity: { loginMethod: "Gentle" } } } }) === "Gentle",
               "usage.identity loginMethod must be used when usage loginMethod is absent")
        assert(ProviderDetails.validLoginMethod({
            provider: "antigravity",
            raw: {
                provider: "antigravity",
                usage: {
                    identity: { providerID: "antigravity" },
                    extraRateWindows: [{ id: "antigravity-quota-summary-gemini-argon-wtu-weekly", title: "Gemini 4 Argon weekly", window: { usedPercent: 47.5 } }]
                }
            }
        }) === "Pro", "antigravity CLI snapshot with separate Argon bucket must infer Pro plan")
        assert(ProviderDetails.validLoginMethod({
            provider: "antigravity",
            raw: {
                provider: "antigravity",
                usage: {
                    identity: { providerID: "antigravity" },
                    extraRateWindows: [{ id: "antigravity-quota-summary-gemini-5h", title: "Gemini 5-hour", window: { usedPercent: 10 } }]
                }
            }
        }) === "", "antigravity snapshot without explicit plan or Argon bucket must remain empty")

        assert(ProviderDetails.acceptedDetails({ raw: {} }).length === 0, "missing details must be omitted")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: {} } }).length === 0, "missing details in usage must be omitted")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: null } } }).length === 0, "null details must be omitted")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: {} } } }).length === 0, "non-array details must be omitted")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [] } } }).length === 0, "empty details must be omitted")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: ["not-an-object"] } } }).length === 0, "non-object detail must be omitted")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "No rows" }] } } }).length === 0, "detail without rows must be omitted")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Bad rows", rows: "nope" }] } } }).length === 0, "detail with non-array rows must be omitted")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Empty rows", rows: [] }] } } }).length === 0, "detail with empty rows must be omitted")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Bad row", rows: [{ label: "Only label" }] }] } } }).length === 0, "row without value must be omitted")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Bad row", rows: [{ value: "Only value" }] }] } } }).length === 0, "row without label must be omitted")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Bad secondary", rows: [{ label: "A", value: "1", secondaryValue: 42 }] }] } } }).length === 0, "row with non-string secondaryValue must be omitted")

        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Email summary", rows: [{ label: "A", value: "1" }] }] } } }).length === 0, "email in title must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "E-mail summary", rows: [{ label: "A", value: "1" }] }] } } }).length === 0, "e-mail in title must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Org", rows: [{ label: "Organization name", value: "X" }] }] } } }).length === 0, "organization in label must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Org", rows: [{ label: "A", value: "Organisation value" }] }] } } }).length === 0, "organisation in value must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Pace", rows: [{ label: "A", value: "1" }] }] } } }).length === 0, "pace in title must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Credits", rows: [{ label: "A", value: "1" }] }] } } }).length === 0, "credits in title must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Costs", rows: [{ label: "A", value: "1" }] }] } } }).length === 0, "costs in title must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Tokens", rows: [{ label: "A", value: "1" }] }] } } }).length === 0, "tokens in title must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Mixed", rows: [{ label: "Email signature", value: "1" }] }] } } }).length === 0, "email signature in label must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "CamelCasePace", rows: [{ label: "A", value: "1" }] }] } } }).length === 0, "camelCase pace must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Mixed", rows: [{ label: "Credit(s)", value: "1" }] }] } } }).length === 0, "credit(s) in label must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Contact", rows: [{ label: "Support", value: "help@example.com" }] }] } } }).length === 0, "bare email address value must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Contact", rows: [{ label: "Support", value: "Help@Example.COM" }] }] } } }).length === 0, "mixed-case bare email address value must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Contact", rows: [{ label: "Support", value: "user.name+tag@sub.example.co.uk" }] }] } } }).length === 0, "complex bare email address value must be rejected")
        assert(ProviderDetails.acceptedDetails({ raw: { usage: { details: [{ title: "Reach us", rows: [{ label: "help@example.com", value: "1" }] }] } } }).length === 0, "bare email address label must be rejected")

        var mixed = ProviderDetails.acceptedDetails({
            raw: {
                usage: {
                    details: [
                        {
                            title: "Mixed",
                            rows: [
                                { label: "Token usage", value: "12" },
                                { label: "Requests", value: "1200" }
                            ]
                        }
                    ]
                }
            }
        })
        assert(mixed.length === 1, "detail with mixed rows must survive")
        assert(mixed[0].rows.length === 1, "rejected row must be removed")
        assert(mixed[0].rows[0].label === "Requests", "accepted row label must be preserved")
        assert(mixed[0].rows[0].value === "1200", "accepted row value must be preserved")

        var verbatim = ProviderDetails.acceptedDetails({
            raw: {
                usage: {
                    details: [
                        {
                            title: "Exact",
                            rows: [
                                { label: "Code", value: "<script>alert('x')</script>", secondaryValue: null }
                            ]
                        }
                    ]
                }
            }
        })
        assert(verbatim.length === 1, "verbatim detail must survive")
        assert(verbatim[0].rows[0].value === "<script>alert('x')</script>", "verbatim value must not be altered")
        assert(verbatim[0].rows[0].secondaryValue === null, "null secondaryValue must stay null")

        // Phase 3: selected-provider enrichment extractors -- pure, narrow,
        // and fail-closed. Identity fields prefer usage.identity, then the
        // documented usage-level fallback.
        assert(ProviderDetails.validEmail({ raw: { usage: { identity: { accountEmail: "user@example.com" } } } }) === "user@example.com",
               "identity accountEmail must be preferred")
        assert(ProviderDetails.validEmail({ raw: { usage: { accountEmail: "fallback@example.com" } } }) === "fallback@example.com",
               "usage accountEmail must be the documented fallback")
        assert(ProviderDetails.validEmail({ raw: { usage: { identity: { accountEmail: "not-an-email" } } } }) === "",
               "a malformed email must be omitted")
        assert(ProviderDetails.validEmail({ raw: {} }) === "", "missing email must be omitted")

        assert(ProviderDetails.validOrganization({ raw: { usage: { identity: { accountOrganization: "Acme Corp" } } } }) === "Acme Corp",
               "a human-readable organization must be shown")
        assert(ProviderDetails.validOrganization({ raw: { usage: { identity: { accountOrganization: "3f2504e0-4f89-41d3-9a0c-0305e82c3301" } } } }) === "",
               "a UUID organization must be rejected")
        assert(ProviderDetails.validOrganization({ raw: { usage: { identity: { accountOrganization: "5f2c9b7a1e3d4f6a8b9c0d1e2f3a4b5c" } } } }) === "",
               "a long hex-like organization must be rejected")
        assert(ProviderDetails.validOrganization({ raw: { usage: { identity: { accountOrganization: "org_9K3lM2pQ7rS1tU4vW8xY0z" } } } }) === "",
               "a long opaque token organization must be rejected")
        assert(ProviderDetails.validOrganization({ raw: { usage: { accountOrganization: "Fallback Labs" } } }) === "Fallback Labs",
               "usage accountOrganization must be the documented fallback")

        assert(ProviderDetails.validCreditsRemaining({ raw: { credits: { remaining: 12 } } }) === 12, "finite remaining credit must be shown")
        assert(ProviderDetails.validCreditsRemaining({ raw: { credits: { remaining: 0 } } }) === 0, "zero remaining credit must still be shown")
        assert(ProviderDetails.validCreditsRemaining({ raw: { credits: { remaining: "12" } } }) === null, "a non-numeric remaining credit must be omitted")
        assert(ProviderDetails.validCreditsRemaining({ raw: {} }) === null, "a missing credits object must be omitted")

        assert(ProviderDetails.paceSummaryByLabel({ raw: { pace: { primary: { summary: "42% used" } } } }).Session === "42% used",
               "pace.primary must map to Session")
        assert(ProviderDetails.paceSummaryByLabel({ raw: { pace: { secondary: { summary: "67% used" } } } }).Weekly === "67% used",
               "pace.secondary must map to Weekly")
        assert(ProviderDetails.paceSummaryByLabel({ raw: { pace: { tertiary: { stage: "farAhead" } } } }).Monthly === undefined,
               "a pace entry without a summary must be omitted")
        assert(Object.keys(ProviderDetails.paceSummaryByLabel({ raw: {} })).length === 0, "a missing pace object must be omitted")

        var paceByKey = ProviderDetails.paceSummaryByKey({
            raw: {
                pace: {
                    primary: { summary: "42% used" },
                    secondary: { summary: "67% used" },
                    tertiary: { summary: "10% in reserve" }
                }
            }
        })
        assert(paceByKey.primary === "42% used" && paceByKey.secondary === "67% used" && paceByKey.tertiary === "10% in reserve",
               "paceSummaryByKey must preserve window keys regardless of custom labels")

        // Universal pace computation fallback when CLI omits pace on >=5h (300m) windows
        var fakeNow = Date.parse("2026-11-16T01:00:00Z")
        var localPaceInfo = ProviderDetails.paceInfoByKey({
            provider: "codex",
            windows: [
                { key: "primary", label: "Session", usedPercent: 10 },
                { key: "secondary", label: "Weekly", usedPercent: 40 },
                { key: "tertiary", label: "Burst", usedPercent: 20 }
            ],
            raw: {
                provider: "codex",
                usage: {
                    primary: { usedPercent: 10, windowMinutes: 300, resetsAt: "2026-11-16T04:00:00Z" },
                    secondary: { usedPercent: 40, windowMinutes: 10080, resetsAt: "2026-11-18T01:00:00Z" },
                    tertiary: { usedPercent: 20, windowMinutes: 60, resetsAt: "2026-11-16T01:30:00Z" }
                }
            }
        }, fakeNow)
        assert(localPaceInfo.primary !== undefined
               && localPaceInfo.primary.expectedUsedPercent === 40
               && localPaceInfo.primary.summary === "30% in reserve | Expected 40% used | Lasts until reset",
               "5h session windows (300m) must compute local pace matching Claude")
        assert(localPaceInfo.secondary !== undefined
               && localPaceInfo.secondary.expectedUsedPercent === 71
               && localPaceInfo.secondary.summary === "31% in reserve | Expected 71% used | Lasts until reset",
               "weekly codex window must compute local expectedUsedPercent and reserve summary")
        assert(localPaceInfo.tertiary === undefined,
               "sub-5h burst windows (<300m) must not invent a pace estimate")

        // Deficit calculation must append 'Runs out in ...' projection matching CodexBar CLI
        var deficitNow = Date.parse("2026-11-16T01:00:00Z")
        // 300m window resetting in 150m -> 50% elapsed (150m elapsed), 75% used -> delta +25,
        // remaining 25% at rate 75%/150m = 50m -> Runs out in 50m.
        var deficitInfo = ProviderDetails.paceInfoByKey({
            provider: "antigravity",
            windows: [{ key: "primary", label: "Session", usedPercent: 75 }],
            raw: {
                provider: "antigravity",
                usage: {
                    primary: { usedPercent: 75, windowMinutes: 300, resetsAt: "2026-11-16T03:30:00Z" }
                }
            }
        }, deficitNow)
        assert(deficitInfo.primary !== undefined
               && deficitInfo.primary.expectedUsedPercent === 50
               && deficitInfo.primary.summary === "25% in deficit | Expected 50% used | Runs out in 50m",
               "deficit pace summary must include expected percentage and 'Runs out in <duration>' projection")

        var cliPaceInfo = ProviderDetails.paceInfoByKey({
            provider: "claude",
            windows: [{ key: "secondary", label: "Weekly", usedPercent: 44 }],
            raw: {
                provider: "claude",
                pace: {
                    secondary: { expectedUsedPercent: 70, summary: "26% in reserve | Expected 70% used | Lasts until reset" }
                },
                usage: {
                    secondary: { usedPercent: 44, windowMinutes: 10080, resetsAt: "2026-11-18T03:59:59Z" }
                }
            }
        }, fakeNow)
        assert(cliPaceInfo.secondary !== undefined && cliPaceInfo.secondary.expectedUsedPercent === 70,
               "CLI-provided pace.expectedUsedPercent must be preserved")

        var resetCredits = ProviderDetails.validResetCredits({
            raw: { usage: { codexResetCredits: { availableCount: 2, credits: [
                { amount: 1, expiresAt: "2026-09-01T00:00:00Z" }, { amount: 1, expiresAt: "2026-10-01T00:00:00Z" }
            ] } } }
        })
        assert(resetCredits !== null && resetCredits.availableCount === 2 && resetCredits.credits.length === 2,
               "a positive reset-credit inventory with valid expirations must be returned")
        assert(ProviderDetails.validResetCredits({ raw: { usage: { codexResetCredits: { availableCount: 0, credits: [] } } } }) === null,
               "a zero-count reset-credit inventory must be omitted")
        assert(ProviderDetails.validResetCredits({ raw: { usage: { codexResetCredits: "opaque" } } }) === null,
               "a malformed reset-credit inventory must be omitted")

        detailsWithData.providerData = { raw: rawBase }
        assert(detailsWithData.acceptedDetails.length === 1, "component must compute accepted details")
        assert(detailsWithData.visible, "component with accepted details must be visible")
        assert(!detailsWithData.expanded, "disclosure must start collapsed")
        assert(detailsWithData.disclosureButton.activeFocusOnTab, "disclosure must participate in Tab traversal")
        assert(detailsWithData.disclosureButton.focusPolicy === Qt.StrongFocus, "disclosure must accept keyboard focus")
        assert(detailsWithData.disclosureButton.Accessible.name.length > 0, "disclosure must expose accessible name")
        assert(detailsWithData.disclosureButton.Accessible.description.length > 0, "disclosure must expose accessible description")

        detailsWithData.disclosureButton.click()
        assert(detailsWithData.expanded, "click must expand details")
        var limitsTitle = firstLabelWithText(detailsWithData, "Limits")
        var requestsLabel = firstLabelWithText(detailsWithData, "Requests")
        var requestsValue = firstLabelWithText(detailsWithData, "1200")
        assert(limitsTitle !== null, "expanded details must show title")
        assert(requestsLabel !== null, "expanded details must show row label")
        assert(requestsValue !== null, "expanded details must show row value")
        assertWrapAndTheme(limitsTitle, "title")
        assertWrapAndTheme(requestsLabel, "label")
        assertWrapAndTheme(requestsValue, "value")

        detailsWithData.disclosureButton.click()
        assert(!detailsWithData.expanded, "second click must collapse details")

        assert(!detailsEmpty.visible, "component with no accepted details must be hidden")

        assert(ProviderDetails.validStatus({ raw: {} }) === null, "missing status must return null")
        assert(ProviderDetails.validStatus({ raw: { status: { indicator: "none", description: "All Systems Operational" } } }) === null,
            "operational indicator 'none' must return null")
        var minorStatus = ProviderDetails.validStatus({
            raw: {
                status: {
                    indicator: "minor",
                    description: "Partial API degradation",
                    url: "https://status.example.com"
                }
            }
        })
        assert(minorStatus !== null && minorStatus.indicator === "minor", "minor status must return indicator")
        assert(minorStatus.description === "Partial API degradation", "minor status must preserve description")
        assert(minorStatus.url === "https://status.example.com", "minor status must preserve url")

        var criticalFallback = ProviderDetails.validStatus({ raw: { status: { indicator: "critical" } } })
        assert(criticalFallback !== null && criticalFallback.indicator === "critical",
            "critical status without description must still return object")
        assert(criticalFallback.description === "Service incident",
            "critical status without description must provide localized-ready fallback text")

        detailsNarrow.providerData = {
            raw: {
                usage: {
                    details: [
                        {
                            title: "Very long title that must wrap inside the narrow column",
                            rows: [
                                { label: "Very long label that must wrap", value: "Very long value that must wrap" }
                            ]
                        }
                    ]
                }
            }
        }
        detailsNarrow.expanded = true
        // Geometry and theme checks need a layout pass; continue in a Timer.
    }

    Timer {
        interval: 50
        running: true
        repeat: false
        onTriggered: {
            var narrowTitle = root.firstLabelWithText(detailsNarrow, "Very long title that must wrap inside the narrow column")
            root.assert(narrowTitle !== null, "narrow row must render long title")
            root.assert(narrowTitle.width <= detailsNarrow.width, "long title must not exceed component width")
            root.assert(!root.hasHardcodedColor(detailsWithData), "details must use theme colors, not literal colors")
            root.finish()
        }
    }

    UsageUi.ProviderDetails {
        id: detailsWithData
    }

    UsageUi.ProviderDetails {
        id: detailsEmpty
        providerData: ({ raw: { usage: {} } })
    }

    UsageUi.ProviderDetails {
        id: detailsNarrow
        width: 120
    }
}
