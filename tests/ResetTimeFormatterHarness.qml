import QtQuick
import "../contents/code/ResetTimeFormatter.js" as ResetTimeFormatter

Item {
    id: root
    width: 1
    height: 1
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("ResetTimeFormatterHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() {
        Qt.exit(assertionFailed ? 1 : 0)
    }

    Component.onCompleted: {
        var fixedIsoNow = Date.parse("2026-11-06T12:00:00Z")

        // 1. Future ISO-8601 resetsAt with fixed nowMs (Date.parse("2026-11-06T12:00:00Z"))
        assert(ResetTimeFormatter.formatResetText("2026-11-06T16:56:00Z", null, fixedIsoNow, "en") === "Resets in 4h 56m",
               "resetsAt 4h 56m ahead in en")
        assert(ResetTimeFormatter.formatResetText("2026-11-06T16:56:00Z", null, fixedIsoNow, "es") === "Se reinicia en 4 h 56 min",
               "resetsAt 4h 56m ahead in es")

        // Future resetsAt takes precedence even when resetDescription is "Dec 3" or "Nov 12 at 9:00 PM"
        assert(ResetTimeFormatter.formatResetText("2026-11-12T21:00:00Z", "Dec 3", fixedIsoNow, "en") === "Resets in 6d 9h",
               "resetsAt 6d 9h ahead overrides Dec 3 in en")
        assert(ResetTimeFormatter.formatResetText("2026-11-12T21:00:00Z", "Dec 3", fixedIsoNow, "es") === "Se reinicia en 6 d 9 h",
               "resetsAt 6d 9h ahead overrides Dec 3 in es")
        assert(ResetTimeFormatter.formatResetText("2026-11-12T21:00:00Z", "Nov 12 at 9:00 PM", fixedIsoNow, "en") === "Resets in 6d 9h",
               "resetsAt 6d 9h ahead overrides Nov 12 at 9:00 PM in en")
        assert(ResetTimeFormatter.formatResetText("2026-11-12T21:00:00Z", "Nov 12 at 9:00 PM", fixedIsoNow, "es") === "Se reinicia en 6 d 9 h",
               "resetsAt 6d 9h ahead overrides Nov 12 at 9:00 PM in es")

        assert(ResetTimeFormatter.formatResetText("2026-11-06T12:25:00Z", null, fixedIsoNow, "en") === "Resets in 25m",
               "resetsAt 25m ahead in en")
        assert(ResetTimeFormatter.formatResetText("2026-11-06T12:25:00Z", null, fixedIsoNow, "es") === "Se reinicia en 25 min",
               "resetsAt 25m ahead in es")

        assert(ResetTimeFormatter.formatResetText("2026-11-06T12:00:30Z", null, fixedIsoNow, "en") === "Resets in < 1m",
               "resetsAt 30s ahead in en")
        assert(ResetTimeFormatter.formatResetText("2026-11-06T12:00:30Z", null, fixedIsoNow, "es") === "Se reinicia en < 1 min",
               "resetsAt 30s ahead in es")

        // 2. Verbose duration resetDescription when resetsAt is null or past
        var pastIso = "2026-08-09T12:00:00Z"
        assert(ResetTimeFormatter.formatResetText(null, "Resets in 2 hours, 20 minutes", fixedIsoNow, "en") === "Resets in 2h 20m",
               "verbose 2 hours, 20 minutes with null resetsAt in en")
        assert(ResetTimeFormatter.formatResetText(pastIso, "Resets in 2 hours, 20 minutes", fixedIsoNow, "en") === "Resets in 2h 20m",
               "verbose 2 hours, 20 minutes with past resetsAt in en")
        assert(ResetTimeFormatter.formatResetText(null, "Resets in 2 hours, 20 minutes", fixedIsoNow, "es") === "Se reinicia en 2 h 20 min",
               "verbose 2 hours, 20 minutes in es")

        assert(ResetTimeFormatter.formatResetText(null, "Resets in 6 days, 21 hours", fixedIsoNow, "en") === "Resets in 6d 21h",
               "verbose 6 days, 21 hours in en")
        assert(ResetTimeFormatter.formatResetText(pastIso, "Resets in 6 days, 21 hours", fixedIsoNow, "es") === "Se reinicia en 6 d 21 h",
               "verbose 6 days, 21 hours in es")

        assert(ResetTimeFormatter.formatResetText(null, "refresh in 5h 0m", fixedIsoNow, "en") === "Resets in 5h 0m",
               "refresh in 5h 0m in en")
        assert(ResetTimeFormatter.formatResetText(pastIso, "refresh in 5h 0m", fixedIsoNow, "es") === "Se reinicia en 5 h 0 min",
               "refresh in 5h 0m in es")

        // 3. English date resetDescription when resetsAt is null (relative to local noon Nov 6, 2026)
        var localNowMs = new Date(2026, 10, 6, 12, 0, 0).getTime()
        assert(ResetTimeFormatter.formatResetText(null, "tomorrow, 12:45 AM", localNowMs, "en") === "Resets in 12h 45m",
               "tomorrow, 12:45 AM relative to local noon in en")
        assert(ResetTimeFormatter.formatResetText(null, "tomorrow, 12:45 AM", localNowMs, "es") === "Se reinicia en 12 h 45 min",
               "tomorrow, 12:45 AM relative to local noon in es")

        assert(ResetTimeFormatter.formatResetText(null, "Nov 10 at 5:24 PM", localNowMs, "en") === "Resets in 4d 5h",
               "Nov 10 at 5:24 PM relative to local noon in en")
        assert(ResetTimeFormatter.formatResetText(null, "Nov 10 at 5:24 PM", localNowMs, "es") === "Se reinicia en 4 d 5 h",
               "Nov 10 at 5:24 PM relative to local noon in es")

        assert(ResetTimeFormatter.formatResetText(null, "Dec 3", localNowMs, "en") === "Resets in 26d 12h",
               "Dec 3 relative to local noon in en")
        assert(ResetTimeFormatter.formatResetText(null, "Dec 3", localNowMs, "es") === "Se reinicia en 26 d 12 h",
               "Dec 3 relative to local noon in es")

        // 3b. Elapsed yearless date from earlier the same day must NOT roll forward 364 days;
        // it represents an already-elapsed session window and must report < 1m.
        var localNightMs = new Date(2026, 10, 6, 22, 18, 0).getTime()
        assert(ResetTimeFormatter.formatResetText(null, "Nov 6 at 8:00 PM", localNightMs, "es") === "Se reinicia en < 1 min",
               "same-day elapsed yearless date must not roll over 364 days in es")
        assert(ResetTimeFormatter.formatResetText(null, "Nov 6 at 8:00 PM", localNightMs, "en") === "Resets in < 1m",
               "same-day elapsed yearless date must not roll over 364 days in en")

        // Year-end boundary (Dec 28 -> Jan 2) without year must still roll into next year
        var dec28NoonMs = new Date(2026, 11, 28, 12, 0, 0).getTime()
        assert(ResetTimeFormatter.formatResetText(null, "Jan 2 at 12:00 PM", dec28NoonMs, "es") === "Se reinicia en 5 d 0 h",
               "Dec-to-Jan yearless date rolls into next year in es")

        // 4. Fallback preservation for non-temporal notes, past ISO timestamps, and invalid date/clock overflows
        assert(ResetTimeFormatter.formatResetText(null, "Feb 31", fixedIsoNow, "en") === "Feb 31",
               "calendar overflow Feb 31 falls back to raw string")
        assert(ResetTimeFormatter.formatResetText(null, "tomorrow, 25:99", fixedIsoNow, "en") === "tomorrow, 25:99",
               "clock overflow tomorrow, 25:99 falls back to raw string")
        assert(ResetTimeFormatter.formatResetText(null, "Nov 10 at 13:45 PM", fixedIsoNow, "en") === "Nov 10 at 13:45 PM",
               "clock overflow Nov 10 at 13:45 PM falls back to raw string")

        assert(ResetTimeFormatter.formatResetText("2026-08-09T12:00:00Z", "Exact reset note", fixedIsoNow, "en") === "Exact reset note",
               "Exact reset note preserved in en")
        assert(ResetTimeFormatter.formatResetText("2026-08-09T13:00:00Z", "NaN reset", fixedIsoNow, "en") === "NaN reset",
               "NaN reset preserved in en")
        assert(ResetTimeFormatter.formatResetText("2026-08-09T15:00:00Z", null, fixedIsoNow, "en") === "Reset: 2026-08-09T15:00:00Z",
               "past resetsAt without resetDescription renders Reset: ISO in en")
        assert(ResetTimeFormatter.formatResetText("2026-08-09T15:00:00Z", null, fixedIsoNow, "es") === "Reinicio: 2026-08-09T15:00:00Z",
               "past resetsAt without resetDescription renders Reinicio: ISO in es")

        // Empty fallbacks
        assert(ResetTimeFormatter.formatResetText(null, null, fixedIsoNow, "en") === "",
               "null resetsAt and null resetDescription returns empty")
        assert(ResetTimeFormatter.formatResetText(undefined, undefined, fixedIsoNow, "en") === "",
               "undefined resetsAt and undefined resetDescription returns empty")
        assert(ResetTimeFormatter.formatResetText("", "", fixedIsoNow, "en") === "",
               "empty resetsAt and empty resetDescription returns empty")

        // Explicit language overrides
        assert(ResetTimeFormatter.formatResetText("2026-11-06T16:56:00Z", null, fixedIsoNow, "en") === "Resets in 4h 56m",
               "explicit en forces English formatting")
        assert(ResetTimeFormatter.formatResetText("2026-11-06T16:56:00Z", null, fixedIsoNow, "es") === "Se reinicia en 4 h 56 min",
               "explicit es forces Spanish formatting")

        finish()
    }
}
