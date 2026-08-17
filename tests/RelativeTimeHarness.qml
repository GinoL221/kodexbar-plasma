import QtQuick
import "../contents/code/RelativeTime.js" as RelativeTime

Item {
    id: root
    width: 1
    height: 1
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("RelativeTimeHarness failure:", message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() {
        Qt.exit(assertionFailed ? 1 : 0)
    }

    Component.onCompleted: {
        var now = Date.parse("2026-08-17T15:00:00Z")

        assert(RelativeTime.formatUpdatedLabel("", now) === "", "empty stays empty")
        assert(RelativeTime.formatUpdatedLabel(null, now) === "", "null stays empty")
        assert(RelativeTime.formatUpdatedLabel("not-a-date", now) === "", "garbage stays empty")

        assert(RelativeTime.formatUpdatedLabel("2026-08-17T14:59:30Z", now) === "Updated just now",
               "under 45s → just now")
        assert(RelativeTime.formatUpdatedLabel("2026-08-17T14:58:30Z", now) === "Updated 1 minute ago",
               "~90s window → 1 minute")
        assert(RelativeTime.formatUpdatedLabel("2026-08-17T14:40:00Z", now) === "Updated 20 minutes ago",
               "minutes ago")
        assert(RelativeTime.formatUpdatedLabel("2026-08-17T13:30:00Z", now) === "Updated 1 hour ago",
               "about one hour")
        assert(RelativeTime.formatUpdatedLabel("2026-08-17T10:00:00Z", now) === "Updated 5 hours ago",
               "hours ago")
        assert(RelativeTime.formatUpdatedLabel("2026-08-16T15:00:00Z", now) === "Updated 1 day ago",
               "one day")
        assert(RelativeTime.formatUpdatedLabel("2026-08-14T15:00:00Z", now) === "Updated 3 days ago",
               "few days")
        assert(RelativeTime.formatUpdatedLabel("2026-07-01T15:00:00Z", now).indexOf("Updated:") === 0,
               "older than two weeks falls back to Updated: raw")

        finish()
    }
}
