import QtQuick
import "../contents/code/NotificationPolicy.js" as NotificationPolicy

Item {
    id: root
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("NotificationPolicyHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        // 1. Quota notification threshold decision
        assert(NotificationPolicy.shouldNotifyQuota("ok", "critical") === true,
            "escalation from ok to critical must trigger notification")
        assert(NotificationPolicy.shouldNotifyQuota("warn", "critical") === true,
            "escalation from warn to critical must trigger notification")
        assert(NotificationPolicy.shouldNotifyQuota("critical", "exhausted") === true,
            "escalation from critical to exhausted must trigger notification")
        assert(NotificationPolicy.shouldNotifyQuota("ok", "exhausted") === true,
            "jump from ok to exhausted must trigger notification")

        // 2. Anti-spam: repeated polls at the same level must NOT trigger
        assert(NotificationPolicy.shouldNotifyQuota("critical", "critical") === false,
            "unchanged critical level must not trigger notification spam")
        assert(NotificationPolicy.shouldNotifyQuota("exhausted", "exhausted") === false,
            "unchanged exhausted level must not trigger notification spam")

        // 3. De-escalation or safe levels must not trigger
        assert(NotificationPolicy.shouldNotifyQuota("critical", "ok") === false,
            "reset from critical to ok must not notify")
        assert(NotificationPolicy.shouldNotifyQuota("exhausted", "critical") === false,
            "drop from exhausted to critical must not notify")
        assert(NotificationPolicy.shouldNotifyQuota("", "warn") === false,
            "reaching warn (70%) is sub-critical and must not trigger intrusive notifications")

        // 4. Rate-limit notification rules (only on strike 1)
        assert(NotificationPolicy.shouldNotifyRateLimit(0, 1) === true,
            "entering rate limit backoff (first strike) must trigger notification")
        assert(NotificationPolicy.shouldNotifyRateLimit(1, 2) === false,
            "subsequent rate limit backoff strike must not spam notification")
        assert(NotificationPolicy.shouldNotifyRateLimit(2, 3) === false,
            "third rate limit backoff strike must not spam notification")
        assert(NotificationPolicy.shouldNotifyRateLimit(1, 0) === false,
            "recovering from rate limit must not trigger rate limit alert")

        // 5. Message payload construction
        var notifCritical = NotificationPolicy.buildQuotaNotification("Claude", "Session", 92, "Nov 5 at 4:20 PM")
        assert(notifCritical.title.indexOf("Claude") !== -1 && notifCritical.title.indexOf("90%") !== -1,
            "critical notification title must name provider and threshold")
        assert(notifCritical.text.indexOf("Session") !== -1 && notifCritical.text.indexOf("92%") !== -1,
            "critical notification text must name window and exact percentage")
        assert(notifCritical.urgency === "normal", "critical usage should use normal urgency")

        var notifExhausted = NotificationPolicy.buildQuotaNotification("Grok", "Weekly", 100, "")
        assert(notifExhausted.title.indexOf("Grok") !== -1 && notifExhausted.title.indexOf("exhausted") !== -1,
            "exhausted notification title must state quota exhausted")
        assert(notifExhausted.urgency === "critical", "exhausted usage should use critical urgency")

        var notif429 = NotificationPolicy.buildRateLimitNotification("Claude", 2)
        assert(notif429.title.indexOf("Claude") !== -1 && notif429.title.indexOf("Rate limit") !== -1,
            "rate limit notification title must name provider and rate limit")
        assert(notif429.text.indexOf("2 minutes") !== -1,
            "rate limit notification text must include retry window in minutes")

        // 6. evaluateTransitions stateful engine
        var displayNameFn = function(p) { return p === "claude" ? "Claude" : p }
        var prevState = {}

        // Poll 1: Claude at 42% -> no notifications
        var providers1 = [
            { provider: "claude", windows: [{ key: "primary", label: "Session", usedPercent: 42 }] }
        ]
        var eval1 = NotificationPolicy.evaluateTransitions(prevState, providers1, [], 0, 0, displayNameFn)
        assert(eval1.notifications.length === 0, "healthy initial usage must yield 0 notifications")
        assert(eval1.nextState["claude:primary"] === "ok", "nextState must track ok level")

        // Poll 2: Claude crosses to 92% -> exactly 1 critical notification
        var providers2 = [
            { provider: "claude", windows: [{ key: "primary", label: "Session", usedPercent: 92, resetDescription: "in 2h" }] }
        ]
        var eval2 = NotificationPolicy.evaluateTransitions(eval1.nextState, providers2, [], 0, 0, displayNameFn)
        assert(eval2.notifications.length === 1, "escalation to 92% must yield exactly 1 notification")
        assert(eval2.notifications[0].title.indexOf("90%") !== -1, "notification must announce 90% threshold")
        assert(eval2.nextState["claude:primary"] === "critical", "nextState must record critical")

        // Poll 3: Claude still at 94% -> 0 notifications (no repeat spam)
        var providers3 = [
            { provider: "claude", windows: [{ key: "primary", label: "Session", usedPercent: 94 }] }
        ]
        var eval3 = NotificationPolicy.evaluateTransitions(eval2.nextState, providers3, [], 0, 0, displayNameFn)
        assert(eval3.notifications.length === 0, "staying in critical must not yield new notifications")
        assert(eval3.nextState["claude:primary"] === "critical", "nextState remains critical")

        // Poll 4: Claude reaches 100% -> exactly 1 exhausted notification
        var providers4 = [
            { provider: "claude", windows: [{ key: "primary", label: "Session", usedPercent: 100 }] }
        ]
        var eval4 = NotificationPolicy.evaluateTransitions(eval3.nextState, providers4, [], 0, 0, displayNameFn)
        assert(eval4.notifications.length === 1, "escalation to 100% must yield exhausted notification")
        assert(eval4.notifications[0].title.indexOf("exhausted") !== -1, "notification must announce exhausted")

        // Poll 5: Claude enters 429 rate limit -> rate limit alert
        var eval5 = NotificationPolicy.evaluateTransitions(eval4.nextState, providers4, ["claude"], 1, 2, displayNameFn)
        assert(eval5.notifications.length === 1, "first strike of 429 must yield 1 rate limit notification")
        assert(eval5.notifications[0].title.indexOf("Rate limit") !== -1, "notification must announce rate limit")

        // Poll 6: Claude still in 429 strike 2 -> 0 notifications
        var eval6 = NotificationPolicy.evaluateTransitions(eval5.nextState, providers4, ["claude"], 2, 4, displayNameFn)
        assert(eval6.notifications.length === 0, "second strike of 429 must not spam notification")

        finish()
    }
}
