import QtQuick
import "../contents/code/RequestTimeout.js" as RequestTimeout

Item {
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("RequestTimeoutHarness failure: " + message)
            assertionFailed = true
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        assert(RequestTimeout.parse(60) === 60, "the default preset must be valid")
        assert(RequestTimeout.parse(120) === 120, "the Claude preset must be valid")
        assert(RequestTimeout.parse(180) === 180, "the long preset must be valid")
        assert(RequestTimeout.parse(30) === 30, "the minimum custom timeout must be valid")
        assert(RequestTimeout.parse(600) === 600, "the maximum custom timeout must be valid")
        assert(RequestTimeout.secondsOrDefault(undefined) === 60, "missing persistence must use 60 seconds")
        assert(RequestTimeout.secondsOrDefault("120") === 60, "strings must not reach the watchdog")
        assert(RequestTimeout.secondsOrDefault(NaN) === 60, "NaN must use the fallback")
        assert(RequestTimeout.secondsOrDefault(120.5) === 60, "fractional values must use the fallback")
        assert(RequestTimeout.secondsOrDefault(29) === 60, "below-range values must use the fallback")
        assert(RequestTimeout.secondsOrDefault(601) === 60, "above-range values must use the fallback")
        assert(RequestTimeout.millisecondsOrDefault(120) === 120000, "seconds must convert to milliseconds")
        assert(RequestTimeout.millisecondsOrDefault(29) === 60000, "invalid seconds must convert from the fallback")
        finish()
    }
}
