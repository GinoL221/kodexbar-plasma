import QtQuick

Item {
    id: root
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("RefreshTimerHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component {
        id: schedulerComponent

        Item {
            id: scheduler
            property int refreshSeconds: 600
            property int retryDelayMs: 0
            property bool rateLimited: retryDelayMs > 0
            property int effectiveRefreshSeconds: Math.max(refreshSeconds, Math.ceil(retryDelayMs / 1000))
            property int refreshCalls: 0

            function refresh() {
                refreshCalls++
            }

            Timer {
                id: refreshTimer
                interval: scheduler.effectiveRefreshSeconds * 1000
                repeat: true
                running: true
                triggeredOnStart: false
                onTriggered: scheduler.refresh()
            }

            Component.onCompleted: scheduler.refresh()

            onEffectiveRefreshSecondsChanged: refreshTimer.restart()

            onRefreshSecondsChanged: {
                refreshTimer.restart()
                if (!rateLimited) {
                    refresh()
                }
            }
        }
    }

    Component.onCompleted: {
        // 1. Initial startup: Component.onCompleted triggers exactly one refresh.
        // With triggeredOnStart: false, the running Timer must not emit an extra poll.
        var sched = schedulerComponent.createObject(root)
        assert(sched.refreshCalls === 1,
            "startup must issue exactly one poll via Component.onCompleted (got: " + sched.refreshCalls + ")")

        // 2. Entering rate-limit backoff changes effectiveRefreshSeconds.
        // Timer.restart() with triggeredOnStart: false must NOT fire an immediate poll.
        sched.retryDelayMs = 1200000 // 20 minutes backoff (> 600s base)
        assert(sched.effectiveRefreshSeconds === 1200, "effectiveRefreshSeconds must reflect backoff")
        assert(sched.refreshCalls === 1,
            "changing effectiveRefreshSeconds must restart the timer without an immediate poll (got: " + sched.refreshCalls + ")")

        // 3. Changing configured refreshSeconds while in backoff must NOT trigger an immediate poll.
        sched.refreshSeconds = 300
        assert(sched.effectiveRefreshSeconds === 1200, "effectiveRefreshSeconds remains at backoff delay")
        assert(sched.refreshCalls === 1,
            "changing configured refreshSeconds during backoff must not poll immediately (got: " + sched.refreshCalls + ")")

        // 4. Recovering from backoff restores normal schedule.
        sched.retryDelayMs = 0
        assert(sched.effectiveRefreshSeconds === 300, "effectiveRefreshSeconds must restore to configured interval")
        assert(sched.refreshCalls === 1,
            "recovering from backoff must restart the timer without an immediate poll (got: " + sched.refreshCalls + ")")

        // 5. Changing configured refreshSeconds in normal (non-rate-limited) state
        // triggers an immediate poll to give the user instant feedback.
        sched.refreshSeconds = 600
        assert(sched.refreshCalls === 2,
            "changing configured refreshSeconds in normal state must refresh immediately (got: " + sched.refreshCalls + ")")

        finish()
    }
}
