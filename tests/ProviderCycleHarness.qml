import QtQuick
import "../contents/code/ProviderCycle.js" as ProviderCycle
import "../contents/code/UsageModel.js" as UsageModel

Item {
    id: root
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("ProviderCycleHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        // 1. Index cycling arithmetic
        assert(ProviderCycle.nextIndex(0, 1, 3) === 1, "nextIndex 0 +1 in 3 -> 1")
        assert(ProviderCycle.nextIndex(1, 1, 3) === 2, "nextIndex 1 +1 in 3 -> 2")
        assert(ProviderCycle.nextIndex(2, 1, 3) === 0, "nextIndex 2 +1 in 3 wraps to 0")
        assert(ProviderCycle.nextIndex(0, -1, 3) === 2, "nextIndex 0 -1 in 3 wraps to 2")
        assert(ProviderCycle.nextIndex(2, -1, 3) === 1, "nextIndex 2 -1 in 3 -> 1")
        assert(ProviderCycle.nextIndex(0, 1, 0) === 0, "nextIndex in empty count returns 0")
        assert(ProviderCycle.nextIndex(0, 1, 1) === 0, "nextIndex in singleton count returns 0")

        // 2. Targets building
        var sampleProviders = [
            { provider: "claude", windows: [{ key: "primary", label: "Session", usedPercent: 75 }] },
            { provider: "codex", windows: [{ key: "primary", label: "Session", usedPercent: 40 }] }
        ]
        var targets = ProviderCycle.buildCycleTargets(sampleProviders, function(id) {
            return id === "claude" ? "Claude" : "Codex"
        })
        assert(targets.length === 3, "targets must include 'All' + 2 providers")
        assert(targets[0].isAll === true && targets[0].id === "all", "target 0 must be All")
        assert(targets[1].id === "claude" && targets[1].name === "Claude", "target 1 must be Claude")
        assert(targets[2].id === "codex" && targets[2].name === "Codex", "target 2 must be Codex")

        // 3. Resolving cycled usage for 'All' (index 0)
        var allResolved = ProviderCycle.resolveCycledUsage(
            targets, 0, "session",
            UsageModel.selectCompact,
            UsageModel.selectRepresentative
        )
        assert(allResolved.isAll === true, "index 0 must report isAll true")
        assert(allResolved.usedPercent === 75, "allResolved must reflect global max (Claude 75%)")

        // 4. Resolving cycled usage for Claude (index 1)
        var claudeResolved = ProviderCycle.resolveCycledUsage(
            targets, 1, "session",
            UsageModel.selectCompact,
            UsageModel.selectRepresentative
        )
        assert(claudeResolved.isAll === false, "index 1 must report isAll false")
        assert(claudeResolved.targetId === "claude", "targetId must be claude")
        assert(claudeResolved.usedPercent === 75, "usedPercent must be 75")
        assert(claudeResolved.label === "Session", "label must be Session")

        // 5. Resolving cycled usage for Codex (index 2)
        var codexResolved = ProviderCycle.resolveCycledUsage(
            targets, 2, "session",
            UsageModel.selectCompact,
            UsageModel.selectRepresentative
        )
        assert(codexResolved.isAll === false, "index 2 must report isAll false")
        assert(codexResolved.targetId === "codex", "targetId must be codex")
        assert(codexResolved.usedPercent === 40, "usedPercent must be 40")

        // 6. Out of bounds index falls back safely to All
        var outOfBounds = ProviderCycle.resolveCycledUsage(
            targets, 99, "session",
            UsageModel.selectCompact,
            UsageModel.selectRepresentative
        )
        assert(outOfBounds.isAll === true, "out of bounds index must fall back to All")

        finish()
    }
}
