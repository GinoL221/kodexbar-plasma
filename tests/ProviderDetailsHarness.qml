import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../contents/ui" as UsageUi
import "../contents/code/ProviderDetails.js" as ProviderDetails

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
            var narrowTitle = firstLabelWithText(detailsNarrow, "Very long title that must wrap inside the narrow column")
            assert(narrowTitle !== null, "narrow row must render long title")
            assert(narrowTitle.width <= detailsNarrow.width, "long title must not exceed component width")
            assert(!hasHardcodedColor(detailsWithData), "details must use theme colors, not literal colors")
            finish()
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
