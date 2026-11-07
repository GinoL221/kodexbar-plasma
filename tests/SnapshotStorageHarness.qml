import QtQuick
import QtQuick.LocalStorage as LocalStorage
import "../contents/code/SnapshotStorage.js" as SnapshotStorage

Item {
    id: root
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("SnapshotStorageHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        var testDbName = "KodexBarTest_" + Date.now()

        // 1. Degradation when LocalStorage module is missing or null
        assert(SnapshotStorage.load(null, testDbName).length === 0,
            "load with null localStorage module must return empty array")
        assert(!SnapshotStorage.save(null, [{ provider: "claude" }], testDbName),
            "save with null localStorage module must return false")

        // 2. Initial load from an empty test database
        var initial = SnapshotStorage.load(LocalStorage.LocalStorage, testDbName)
        assert(Array.isArray(initial) && initial.length === 0,
            "load from non-existent snapshot must return empty array")

        // 3. Save invalid inputs
        assert(!SnapshotStorage.save(LocalStorage.LocalStorage, null, testDbName),
            "save with null providers must return false")
        assert(!SnapshotStorage.save(LocalStorage.LocalStorage, [], testDbName),
            "save with empty providers must return false")
        assert(!SnapshotStorage.save(LocalStorage.LocalStorage, "invalid", testDbName),
            "save with non-array providers must return false")

        // 4. Save valid providers
        var sampleProviders = [
            {
                provider: "claude",
                source: "oauth",
                windows: [
                    { key: "primary", label: "Session", usedPercent: 12, resetDescription: "in 2 hours" },
                    { key: "secondary", label: "Weekly", usedPercent: 34, resetDescription: "in 4 days" }
                ],
                raw: { usage: { primary: { usedPercent: 12 } } }
            },
            {
                provider: "codex",
                source: "oauth",
                windows: [
                    { key: "primary", label: "Session", usedPercent: 5 }
                ],
                raw: {}
            }
        ]
        var saved = SnapshotStorage.save(LocalStorage.LocalStorage, sampleProviders, testDbName)
        assert(saved === true, "save with valid providers must return true")

        // 5. Load back saved providers
        var loaded = SnapshotStorage.load(LocalStorage.LocalStorage, testDbName)
        assert(Array.isArray(loaded) && loaded.length === 2,
            "loaded snapshot must contain exactly two providers")
        assert(loaded[0].provider === "claude", "first provider must be claude")
        assert(loaded[0].windows.length === 2, "claude must retain its 2 windows")
        assert(loaded[0].windows[0].usedPercent === 12, "first window usedPercent must be 12")
        assert(loaded[0].windows[1].label === "Weekly", "second window label must be Weekly")
        assert(loaded[1].provider === "codex", "second provider must be codex")

        // 6. Overwrite with new snapshot
        var updatedProviders = [
            {
                provider: "claude",
                source: "oauth",
                windows: [{ key: "primary", label: "Session", usedPercent: 50 }],
                raw: {}
            }
        ]
        assert(SnapshotStorage.save(LocalStorage.LocalStorage, updatedProviders, testDbName),
            "subsequent save must succeed")
        var reloaded = SnapshotStorage.load(LocalStorage.LocalStorage, testDbName)
        assert(reloaded.length === 1 && reloaded[0].windows[0].usedPercent === 50,
            "reloaded snapshot must reflect overwritten data")

        // 7. Clear snapshot
        assert(SnapshotStorage.clear(LocalStorage.LocalStorage, testDbName),
            "clear must return true")
        var afterClear = SnapshotStorage.load(LocalStorage.LocalStorage, testDbName)
        assert(afterClear.length === 0, "load after clear must return empty array")

        // 8. Graceful handling of mock corrupted database
        var corruptMock = {
            openDatabaseSync: function() {
                return {
                    readTransaction: function(callback) {
                        callback({
                            executeSql: function() {
                                return {
                                    rows: {
                                        length: 1,
                                        item: function() { return { payload: "{corrupted json" } }
                                    }
                                }
                            }
                        })
                    }
                }
            }
        }
        var corruptLoaded = SnapshotStorage.load(corruptMock, testDbName)
        assert(Array.isArray(corruptLoaded) && corruptLoaded.length === 0,
            "corrupted payload in database must degrade cleanly to empty array")

        // 9. Cost snapshot storage
        assert(!SnapshotStorage.saveCost(null, "claude", { provider: "claude" }, testDbName),
            "saveCost with null localStorage must return false")
        assert(SnapshotStorage.loadCost(null, "claude", testDbName) === null,
            "loadCost with null localStorage must return null")

        var sampleCost = {
            provider: "claude",
            currencyCode: "USD",
            isLocalEstimate: true,
            sessionCostUSD: 4.13,
            sessionTokens: 519350,
            last30DaysCostUSD: 84.98,
            last30DaysTokens: 140905922,
            daily: [{ date: "2026-11-07", totalCost: 4.13, totalTokens: 519350 }],
            primaryModel: "claude-opus-5-5"
        }
        var sampleCodexCost = {
            provider: "codex",
            currencyCode: "USD",
            isLocalEstimate: true,
            sessionCostUSD: 0.89,
            sessionTokens: 7176207,
            last30DaysCostUSD: 844.22,
            last30DaysTokens: 5986070989,
            daily: [{ date: "2026-11-07", totalCost: 0.89, totalTokens: 7176207 }],
            primaryModel: "gpt-6.1-sol"
        }

        assert(SnapshotStorage.saveCost(LocalStorage.LocalStorage, "claude", sampleCost, testDbName),
            "saveCost with valid claude record must return true")
        assert(SnapshotStorage.saveCost(LocalStorage.LocalStorage, "codex", sampleCodexCost, testDbName),
            "saveCost with valid codex record must return true")

        var loadedCost = SnapshotStorage.loadCost(LocalStorage.LocalStorage, "claude", testDbName)
        assert(loadedCost !== null && loadedCost.provider === "claude" && loadedCost.sessionCostUSD === 4.13,
            "loadCost must return stored cost record for claude")

        var allCosts = SnapshotStorage.loadAllCosts(LocalStorage.LocalStorage, testDbName)
        assert(allCosts["claude"] !== undefined && allCosts["codex"] !== undefined,
            "loadAllCosts must return both claude and codex cost records")
        assert(allCosts["claude"].primaryModel === "claude-opus-5-5",
            "loadAllCosts must preserve model information")

        finish()
    }
}
