import QtQuick
import "../contents/code/RefreshInterval.js" as RefreshInterval

Item {
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("RefreshIntervalHarness failure: " + message)
            assertionFailed = true
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        assert(RefreshInterval.parse(1) === 1, "the minimum configured interval must remain valid")
        assert(RefreshInterval.parse(9) === 9, "valid intervals below ten seconds must remain unchanged")
        assert(RefreshInterval.parse(3600) === 3600, "the maximum configured interval must remain valid")
        assert(RefreshInterval.parse(0) === null, "zero must be rejected")
        assert(RefreshInterval.parse(-1) === null, "negative intervals must be rejected")
        assert(RefreshInterval.parse("30") === null, "nonnumeric intervals must be rejected")
        assert(RefreshInterval.parse(1.5) === null, "fractional intervals must be rejected")
        if (typeof RefreshInterval.correctionGuidance !== "function") {
            console.error("RefreshIntervalHarness failure: invalid intervals need correction guidance")
            Qt.exit(1)
            return
        }
        assert(RefreshInterval.correctionGuidance(1) === "", "valid intervals must not show correction guidance")
        assert(RefreshInterval.correctionGuidance(3600) === "", "the maximum valid interval must not show correction guidance")
        var guidance = "Enter a whole number from 1 to 3600 seconds. Invalid values are restored to the configured default."
        assert(RefreshInterval.correctionGuidance(0) === guidance, "zero must explain how to correct the interval")
        assert(RefreshInterval.correctionGuidance(-1) === guidance, "negative intervals must explain how to correct the interval")
        assert(RefreshInterval.correctionGuidance("30") === guidance, "nonnumeric intervals must explain how to correct the interval")
        assert(RefreshInterval.correctionGuidance(1.5) === guidance, "fractional intervals must explain how to correct the interval")
        finish()
    }
}
