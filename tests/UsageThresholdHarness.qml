import QtQuick
import "../contents/code/UsageThreshold.js" as UsageThreshold

Item {
    id: root
    width: 1
    height: 1
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("UsageThresholdHarness failure:", message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() {
        Qt.exit(assertionFailed ? 1 : 0)
    }

    Component.onCompleted: {
        assert(UsageThreshold.WARN_AT === 70, "WARN_AT must be 70")
        assert(UsageThreshold.CRITICAL_AT === 90, "CRITICAL_AT must be 90")
        assert(UsageThreshold.EXHAUSTED_AT === 100, "EXHAUSTED_AT must be 100")
        assert(UsageThreshold.LEVEL_NONE === "", "LEVEL_NONE must be empty string")
        assert(UsageThreshold.LEVEL_OK === "ok", "LEVEL_OK must be \"ok\"")
        assert(UsageThreshold.LEVEL_WARN === "warn", "LEVEL_WARN must be \"warn\"")
        assert(UsageThreshold.LEVEL_CRITICAL === "critical", "LEVEL_CRITICAL must be \"critical\"")
        assert(UsageThreshold.LEVEL_EXHAUSTED === "exhausted", "LEVEL_EXHAUSTED must be \"exhausted\"")

        // Non-finite / absent -> LEVEL_NONE ("")
        assert(UsageThreshold.level(null) === "", "null -> none")
        assert(UsageThreshold.level(undefined) === "", "undefined -> none")
        assert(UsageThreshold.level("80") === "", "string \"80\" -> none, no coercion")
        assert(UsageThreshold.level(NaN) === "", "NaN -> none")
        assert(UsageThreshold.level(Infinity) === "", "Infinity -> none")
        assert(UsageThreshold.level(-Infinity) === "", "-Infinity -> none")
        assert(UsageThreshold.level({}) === "", "object -> none")

        // ok: below WARN_AT, never clamped
        assert(UsageThreshold.level(0) === "ok", "0 -> ok")
        assert(UsageThreshold.level(69) === "ok", "69 -> ok")
        assert(UsageThreshold.level(69.9) === "ok", "69.9 -> ok")
        assert(UsageThreshold.level(-5) === "ok", "-5 -> ok (not clamped)")

        // warn: inclusive lower bound at WARN_AT, exclusive upper at CRITICAL_AT
        assert(UsageThreshold.level(70) === "warn", "70 -> warn (inclusive lower bound)")
        assert(UsageThreshold.level(70.0) === "warn", "70.0 -> warn")
        assert(UsageThreshold.level(89.9) === "warn", "89.9 -> warn (exclusive upper bound)")

        // critical: inclusive lower bound at CRITICAL_AT, exclusive upper at EXHAUSTED_AT
        assert(UsageThreshold.level(90) === "critical", "90 -> critical (inclusive lower bound)")
        assert(UsageThreshold.level(99.9) === "critical", "99.9 -> critical (exclusive upper bound)")

        // exhausted: inclusive lower bound at EXHAUSTED_AT, never clamped above 100
        assert(UsageThreshold.level(100) === "exhausted", "100 -> exhausted (inclusive lower bound)")
        assert(UsageThreshold.level(100.0) === "exhausted", "100.0 -> exhausted")
        assert(UsageThreshold.level(120) === "exhausted", "120 -> exhausted (not clamped)")

        // isRisk: true only for warn/critical/exhausted
        assert(UsageThreshold.isRisk(UsageThreshold.LEVEL_NONE) === false, "none is not risk")
        assert(UsageThreshold.isRisk(UsageThreshold.LEVEL_OK) === false, "ok is not risk")
        assert(UsageThreshold.isRisk(UsageThreshold.LEVEL_WARN) === true, "warn is risk")
        assert(UsageThreshold.isRisk(UsageThreshold.LEVEL_CRITICAL) === true, "critical is risk")
        assert(UsageThreshold.isRisk(UsageThreshold.LEVEL_EXHAUSTED) === true, "exhausted is risk")

        finish()
    }
}
