import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false
    property var controller: null
    property var fresh: null
    property var mixed: null
    property var noSnapshot: null
    property var copy: null
    property var cachedController: null
    property var coldController: null

    function assert(condition, message) {
        if (!condition) {
            console.error("UsageControllerRateLimitHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    function complete(controller, stdout, exitCode) {
        controller.requestRefresh()
        controller.completeForTest(controller.generation, stdout, exitCode)
    }

    Component.onCompleted: {
        controller = controllerComponent.createObject(root, {
            commandPath: "/tmp/codexbar",
            testMode: true
        })

        complete(controller, JSON.stringify([
            { provider: "claude", usage: { primary: { usedPercent: 42 } } }
        ]), 0)
        assert(controller.phase === "ready", "a valid response must commit usable data")
        assert(controller.committedProviders.length === 1, "the committed snapshot must contain valid providers")
        assert(controller.consecutiveRateLimits === 0, "a healthy response must not count rate limits")

        complete(controller, JSON.stringify([
            { provider: "claude", error: { kind: "api_error", code: 429, message: "rate_limit_error: too many requests" } }
        ]), 0)
        assert(controller.committedProviders.length === 1, "a rate-limit response must preserve the committed snapshot")
        assert(controller.committedProviders[0].provider === "claude", "the preserved snapshot must stay intact")
        assert(controller.phase === "ready", "a rate-limit response with a snapshot must stay ready")
        assert(controller.errorMessage === "", "a rate-limit response with a snapshot must not surface an error")
        assert(controller.consecutiveRateLimits === 1, "the first rate-limit response must count one strike")
        assert(controller.retryDelayMs(60000) === 120000, "the first strike must stretch the next poll to 2 minutes")

        complete(controller, JSON.stringify([
            { provider: "claude", error: { kind: "api_error", code: 3, message: "Usage endpoint throttled" } }
        ]), 0)
        assert(controller.committedProviders.length === 1, "a second rate-limit response must keep preserving the snapshot")
        assert(controller.phase === "ready", "a second rate-limit response must stay ready")
        assert(controller.consecutiveRateLimits === 2, "the second rate-limit response must count two strikes")
        assert(controller.retryDelayMs(60000) === 240000, "the second strike must stretch the next poll to 4 minutes")

        complete(controller, JSON.stringify([
            { provider: "claude", usage: { primary: { usedPercent: 55 } } }
        ]), 0)
        assert(controller.consecutiveRateLimits === 0, "a successful response must reset the strike counter")
        assert(controller.phase === "ready", "a successful response must stay ready")
        assert(controller.committedProviders.length === 1
            && controller.committedProviders[0].raw.usage.primary.usedPercent === 55,
            "a successful response must replace the preserved snapshot with the new data")

        fresh = controllerComponent.createObject(root, {
            commandPath: "/tmp/codexbar",
            testMode: true
        })
        complete(fresh, JSON.stringify([
            { provider: "claude", error: { kind: "api_error", message: "HTTP 429 rate limit exceeded" } }
        ]), 0)
        assert(fresh.phase === "error", "a rate-limit response without a snapshot must report an error")
        assert(fresh.committedProviders.length === 0, "a rate-limit response must not fabricate providers")
        assert(fresh.consecutiveRateLimits === 1, "a rate-limit response without a snapshot must still count a strike")
        assert(fresh.errorMessage.indexOf("minutes") !== -1,
            "the rate-limit error message must communicate the retry delay in minutes")

        // Mixed payload mirroring the real `codexbar usage --provider all`
        // output: fresh data for providers that answered, a claude rate
        // limit, and unrelated provider noise in the same response.
        mixed = controllerComponent.createObject(root, {
            commandPath: "/tmp/codexbar",
            testMode: true
        })
        complete(mixed, JSON.stringify([
            { provider: "claude", usage: { primary: { usedPercent: 12 } } }
        ]), 0)
        assert(mixed.committedProviders.length === 1 && mixed.committedProviders[0].provider === "claude",
            "the mixed case must start from a committed claude snapshot")
        complete(mixed, JSON.stringify([
            { provider: "codex", usage: { primary: { usedPercent: 20 } } },
            { provider: "claude", error: { kind: "provider", code: 3, message: "429 rate limit exceeded, retry later" } },
            { provider: "zed", error: { kind: "provider", code: 1, message: "Zed is only supported on macOS." } }
        ]), 0)
        assert(mixed.phase === "ready", "a mixed payload with fresh data must stay ready")
        assert(mixed.committedProviders.length === 2,
            "a mixed payload must commit fresh providers and preserve the rate-limited snapshot")
        assert(mixed.committedProviders[0].provider === "codex", "fresh providers must come first")
        assert(mixed.committedProviders[1].provider === "claude",
            "the rate-limited provider must be preserved after the fresh providers")
        assert(mixed.committedProviders[1].raw.usage.primary.usedPercent === 12,
            "the preserved entry must reuse the previous snapshot, not fabricate fresh data")
        assert(mixed.committedErrors.length === 2, "provider errors must stay committed")
        assert(mixed.consecutiveRateLimits === 1, "one rate-limit error in the response must count one strike")
        assert(mixed.errorMessage === "", "a mixed payload with fresh data must not surface an error")

        complete(mixed, JSON.stringify([
            { provider: "codex", usage: { primary: { usedPercent: 25 } } }
        ]), 0)
        assert(mixed.committedProviders.length === 1 && mixed.committedProviders[0].provider === "codex",
            "a healthy response must drop the preserved rate-limited snapshot")
        assert(mixed.consecutiveRateLimits === 0, "a healthy response must reset the strike counter")

        // A rate-limited provider without a previous snapshot must not be
        // fabricated; only the providers that answered are committed.
        noSnapshot = controllerComponent.createObject(root, {
            commandPath: "/tmp/codexbar",
            testMode: true
        })
        complete(noSnapshot, JSON.stringify([
            { provider: "codex", usage: { primary: { usedPercent: 30 } } },
            { provider: "kimi", error: { kind: "provider", code: 3, message: "rate_limit_error: throttled" } }
        ]), 0)
        assert(noSnapshot.committedProviders.length === 1 && noSnapshot.committedProviders[0].provider === "codex",
            "a rate-limited provider without a prior snapshot must not be fabricated")
        assert(noSnapshot.consecutiveRateLimits === 1,
            "a mixed payload with an unsnapshotted rate limit must still count one strike")
        assert(noSnapshot.phase === "ready", "fresh data from other providers must keep the phase ready")

        // Unrelated provider errors only: no strike, no preservation.
        complete(noSnapshot, JSON.stringify([
            { provider: "codex", usage: { primary: { usedPercent: 35 } } },
            { provider: "zed", error: { kind: "provider", code: 1, message: "Zed is only supported on macOS." } }
        ]), 0)
        assert(noSnapshot.consecutiveRateLimits === 0, "unrelated provider errors must not count a strike")
        assert(noSnapshot.committedProviders.length === 1
            && noSnapshot.committedProviders[0].raw.usage.primary.usedPercent === 35,
            "unrelated provider errors must not preserve stale providers")
        assert(noSnapshot.phase === "ready", "unrelated provider errors must not change the phase")

        // The retry copy must agree with the timer: with a 10 minute base
        // refresh and strike 1, the next poll is 10 minutes away, not 2.
        copy = controllerComponent.createObject(root, {
            commandPath: "/tmp/codexbar",
            testMode: true,
            baseRefreshMs: 600000
        })
        complete(copy, JSON.stringify([
            { provider: "claude", error: { kind: "api_error", message: "HTTP 429 rate limit exceeded" } }
        ]), 0)
        assert(copy.errorMessage.indexOf("10 minutes") !== -1,
            "the retry message must report the real 10 minute wait, not the 2 minute backoff step")

        // Cold-start cache hydration: proves that even if the very first poll
        // after a restart returns HTTP 429 for Claude, the hydrated snapshot
        // is preserved and Claude never vanishes from the popup.
        var cacheTestDb = "KodexBarColdStartTest_" + Date.now()
        cachedController = controllerComponent.createObject(root, {
            commandPath: "/tmp/codexbar",
            testMode: true,
            cacheEnabled: true,
            storageDbName: cacheTestDb
        })
        complete(cachedController, JSON.stringify([
            { provider: "claude", usage: { primary: { usedPercent: 15 }, secondary: { usedPercent: 25 } } }
        ]), 0)
        assert(cachedController.committedProviders.length === 1, "seed provider must be committed")

        // Simulate a new plasmashell process: cold controller auto-hydrates from cache on completion.
        coldController = controllerComponent.createObject(root, {
            commandPath: "/tmp/codexbar",
            testMode: true,
            cacheEnabled: true,
            storageDbName: cacheTestDb
        })
        assert(coldController.committedProviders.length === 1, "cold controller must auto-hydrate snapshot from cache")
        assert(coldController.committedProviders[0].provider === "claude", "hydrated provider must be claude")
        assert(coldController.phase === "ready", "hydrated controller must be ready immediately")

        // First poll returns HTTP 429 rate limit error.
        complete(coldController, JSON.stringify([
            { provider: "codex", usage: { primary: { usedPercent: 10 } } },
            { provider: "claude", error: { kind: "provider", code: 3, message: "rate_limit_error: throttled" } }
        ]), 0)
        assert(coldController.committedProviders.length === 2,
            "cold-started controller under 429 must keep hydrated claude alongside fresh codex")
        assert(coldController.committedProviders[0].provider === "codex", "fresh codex comes first")
        assert(coldController.committedProviders[1].provider === "claude", "hydrated claude is preserved")
        assert(coldController.committedProviders[1].windows[0].usedPercent === 15,
            "claude preserves the hydrated 15% figure across the cold-start 429")
        assert(coldController.consecutiveRateLimits === 1, "rate limit strike must be counted")
        assert(coldController.phase === "ready", "phase stays ready")

        finish()
    }

    Component {
        id: controllerComponent
        UsageUi.UsageController { }
    }
}
