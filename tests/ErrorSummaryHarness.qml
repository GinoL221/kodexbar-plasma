import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false
    width: 160
    height: 320

    function assert(condition, message) {
        if (!condition) {
            console.error("ErrorSummaryHarness failure:", message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    UsageUi.ErrorSummary {
        id: summary
        width: root.width
        errors: {
            var failures = []
            failures.push({ provider: "provider-auth", source: "raw-source-auth", error: { kind: "auth", message: "Authentication failed: API key missing. Set OPENAI_API_KEY or run codexbar auth login." } })
            failures.push({ provider: "provider-path", source: "raw-source-path", error: "Command failed: /home/redacted-user/.config/codexbar/bin/provider --api-key SECRET: No such file or directory" })
            failures.push({ provider: "provider-platform", source: "raw-source-platform", error: "Unsupported platform: spawn /opt/codexbar/provider ENOEXEC; run provider --verbose" })
            for (var index = 3; index < 23; index++) {
                failures.push({ provider: "provider-" + index, source: "raw-source-" + index, error: "failure-" + index })
            }
            return failures
        }
    }

    Component.onCompleted: {
        assert(summary.errorCount === 23, "the disclosure must retain the full failure count")
        assert(summary.renderedErrors.length === 20, "the disclosure must render no more than 20 failures")
        assert(summary.omittedErrorCount === 3, "the disclosure must report omitted failures")
        assert(summary.renderedErrors[0].provider === "provider-auth", "expanded failures must preserve response order")
        assert(summary.renderedErrors[1].provider === "provider-path", "expanded failures must preserve response order")
        assert(summary.failureText(summary.renderedErrors[0]) === "Provider authentication is required",
               "authentication failures must use a safe category message")
        assert(summary.failureText(summary.renderedErrors[0]).indexOf("OPENAI_API_KEY") === -1,
               "authentication guidance must not be rendered")
        assert(summary.failureText(summary.renderedErrors[1]) === "Provider is unavailable",
               "CLI failures must use a safe availability message")
        assert(summary.failureText(summary.renderedErrors[1]).indexOf("/home/redacted-user") === -1,
               "local filesystem paths must not be rendered")
        assert(summary.failureText(summary.renderedErrors[1]).indexOf("--api-key") === -1,
               "commands and API-key arguments must not be rendered")
        assert(summary.failureText(summary.renderedErrors[2]) === "Provider is not supported on this platform",
               "platform failures must use a safe support message")
        assert(summary.failureText(summary.renderedErrors[2]).indexOf("ENOEXEC") === -1,
               "platform diagnostics must not be rendered")
        assert(summary.failureText({ error: { kind: "provider", message: "The provider returned a token value" } }) === "Provider is unavailable",
               "incidental token text must not classify authentication failures")
        assert(summary.failureText({ error: { kind: "provider", message: "Platform metadata was included in the response" } }) === "Provider is unavailable",
               "incidental platform text must not classify platform failures")
        assert(summary.failureText({ error: { kind: "provider", message: "The provider configuration value was returned" } }) === "Provider is unavailable",
               "incidental configuration text must not classify configuration failures")
        assert(summary.width === root.width, "the disclosure must remain usable in narrow geometry")
        assert(summary.disclosureButton.activeFocusOnTab, "the disclosure must participate in keyboard traversal")
        assert(summary.disclosureButton.focusPolicy === Qt.StrongFocus, "the disclosure must accept keyboard focus")
        assert(summary.disclosureButton.Accessible.name === undefined || summary.disclosureButton.Accessible.name.indexOf("23") !== -1,
               "the disclosure must expose its count to assistive technology when translations are available")
        summary.expanded = true
        assert(summary.expanded, "the disclosure state must be keyboard-toggleable")
        assert(typeof summary.disclosureButton.click === "function", "the disclosure must expose its standard activation path")
        summary.disclosureButton.click()
        assert(!summary.expanded, "native disclosure activation must collapse the details")
        finish()
    }
}
