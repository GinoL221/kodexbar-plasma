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
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    UsageUi.ErrorSummary {
        id: summary
        width: root.width
        errors: {
            var failures = []
            for (var index = 0; index < 23; index++) {
                failures.push({
                    provider: "provider-" + index,
                    source: "raw-source-" + index,
                    error: "failure-" + index
                })
            }
            return failures
        }
    }

    Component.onCompleted: Qt.callLater(function() {
        assert(summary.errorCount === 23, "the disclosure must retain the full failure count")
        assert(summary.renderedErrors.length === 20, "the disclosure must render no more than 20 failures")
        assert(summary.omittedErrorCount === 3, "the disclosure must report omitted failures")
        assert(summary.failureText(summary.renderedErrors[0]) === "failure-0", "failure text must preserve the CLI error")
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
    })
}
