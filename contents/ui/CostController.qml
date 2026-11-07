import QtQuick
import QtQuick.LocalStorage as LocalStorage
import org.kde.plasma.plasma5support as Plasma5Support

import "../code/CostModel.js" as CostModel
import "../code/CodexBarPathResolver.js" as PathResolver
import "../code/SnapshotStorage.js" as SnapshotStorage

// Isolated, optional cost lifecycle. Keyed by provider + committed usage
// generation + an internal request serial so stale, superseded, or timed-out
// callbacks can never mutate a snapshot or reach UsageController.
Item {
    id: root

    readonly property var allowedProviders: ["codex", "claude"]

    property string commandPath: ""
    property int timeoutMs: 60000
    property bool testMode: false
    property bool cacheEnabled: false
    property string storageDbName: ""
    // When > 0 and caching is on, a stored record younger than this is reused
    // instead of spawning a CLI scan, so several widget instances share one
    // scan per refresh cycle. 0 disables sharing.
    property int sharedFreshnessMs: 0

    readonly property string effectiveCommandPath: _effectiveCommandPath
    property string _effectiveCommandPath: ""

    property var snapshots: ({})
    property var cachedSnapshots: ({})
    property var pendingQueue: []

    property bool requestActive: false
    property bool activeIsPrefetch: false
    property string activeProvider: ""
    property int activeGeneration: 0
    property int activeSerial: 0
    property string activeSource: ""
    property var activeDataSource: null
    property int requestSerial: 0
    readonly property int activeRequestCount: requestActive ? 1 : 0

    Component.onCompleted: {
        if (root.cacheEnabled) {
            root.hydrateFromCache()
        }
    }

    function hydrateFromCache() {
        var loaded = SnapshotStorage.loadAllCosts(LocalStorage.LocalStorage, root.storageDbName)
        if (loaded && typeof loaded === "object") {
            root.cachedSnapshots = loaded
        }
    }

    function validatePath(path) {
        return PathResolver.validateAbsolutePath(path)
    }

    function isAllowedProvider(provider) {
        return allowedProviders.indexOf(provider) !== -1
    }

    function keyFor(provider, usageGeneration) {
        return provider + ":" + usageGeneration
    }

    function commandLineFor(provider) {
        return PathResolver.shellQuote(effectiveCommandPath)
            + " cost --provider " + PathResolver.shellQuote(provider)
            + " --format json --json-only"
    }

    // Returns a validated snapshot: exact generation match if present,
    // otherwise stale-while-revalidate fallback from cache for instant display.
    function snapshotFor(provider, usageGeneration) {
        var record = usageGeneration !== undefined && usageGeneration !== null
            ? exactSnapshotFor(provider, usageGeneration) : null
        if (record !== null) {
            return record
        }
        if (cacheEnabled && cachedSnapshots && cachedSnapshots[provider] !== undefined) {
            return cachedSnapshots[provider]
        }
        return null
    }

    function exactSnapshotFor(provider, usageGeneration) {
        var record = snapshots[keyFor(provider, usageGeneration)]
        return record !== undefined ? record : null
    }

    // Requests cost for provider/usageGeneration. An identical active or
    // already-fresh pair coalesces (no duplicate process); queued requests
    // are processed sequentially.
    function request(provider, usageGeneration, isPrefetch) {
        if (!isAllowedProvider(provider) || typeof usageGeneration !== "number") {
            return
        }
        if (exactSnapshotFor(provider, usageGeneration) !== null) {
            return
        }
        if (requestActive && activeProvider === provider && activeGeneration === usageGeneration) {
            return
        }

        var shared = sharedFreshRecord(provider)
        if (shared !== null) {
            // Reuse never re-persists, so the record keeps its original age
            // and a later cycle still triggers a real scan.
            commitSnapshot(provider, usageGeneration, shared, false)
            return
        }

        var validation = validatePath(commandPath)
        if (!validation.valid) {
            return
        }

        if (requestActive) {
            if (isPrefetch) {
                // Background prefetch gets queued rather than disrupting active work
                enqueuePrefetch(provider, usageGeneration)
                return
            }
            // Standard/interactive request replaces in-flight request immediately
            releaseActive()
        }

        _effectiveCommandPath = validation.path
        startRequest(provider, usageGeneration, !!isPrefetch)
    }

    function startRequest(provider, usageGeneration, isPrefetch) {
        requestSerial += 1
        var serial = requestSerial
        requestActive = true
        activeIsPrefetch = !!isPrefetch
        activeProvider = provider
        activeGeneration = usageGeneration
        activeSerial = serial
        activeDataSource = dataSource
        activeSource = commandLineFor(provider)
        dataSource.connectionProvider = provider
        dataSource.connectionGeneration = usageGeneration
        dataSource.connectionSerial = serial
        watchdogSerial = serial
        watchdog.interval = timeoutMs
        watchdog.restart()
        if (!testMode) {
            dataSource.connectSource(activeSource)
        }
    }

    function isCurrentRequest(dataSource, provider, usageGeneration, serial, sourceName) {
        return requestActive
            && activeDataSource === dataSource
            && activeSource === sourceName
            && activeProvider === provider
            && activeGeneration === usageGeneration
            && activeSerial === serial
    }

    function releaseActive() {
        var pendingDataSource = activeDataSource
        var source = activeSource
        activeDataSource = null
        activeSource = ""
        activeProvider = ""
        activeGeneration = 0
        activeSerial = 0
        activeIsPrefetch = false
        requestActive = false
        watchdog.stop()
        if (pendingDataSource !== null) {
            pendingDataSource.connectionSerial = 0
        }
        if (!testMode && pendingDataSource !== null && source.length > 0) {
            pendingDataSource.disconnectSource(source)
        }
    }

    function sharedFreshRecord(provider) {
        if (!cacheEnabled || sharedFreshnessMs <= 0) {
            return null
        }
        var entry = SnapshotStorage.loadCostEntry(LocalStorage.LocalStorage, provider, storageDbName)
        if (entry === null || !isFinite(entry.savedAt)) {
            return null
        }
        var age = Date.now() - entry.savedAt
        return age >= 0 && age < sharedFreshnessMs ? entry.record : null
    }

    // Drains the queue until a real scan starts; items resolved from the
    // shared cache or already fresh must not stall the ones behind them.
    function enqueuePrefetch(provider, usageGeneration) {
        var i
        for (i = 0; i < pendingQueue.length; i++) {
            if (pendingQueue[i].provider === provider && pendingQueue[i].generation === usageGeneration) {
                return
            }
        }
        pendingQueue = pendingQueue.concat([{ provider: provider, generation: usageGeneration, isPrefetch: true }])
    }

    function processNextQueued() {
        var nextItem
        while (pendingQueue.length > 0 && !requestActive) {
            nextItem = pendingQueue[0]
            pendingQueue = pendingQueue.slice(1)
            request(nextItem.provider, nextItem.generation, nextItem.isPrefetch)
        }
    }

    // Keeps only the newest generation per provider so memory stays bounded
    // while prefetch commits a snapshot every refresh cycle.
    function commitSnapshot(provider, usageGeneration, record, persist) {
        var prefix = provider + ":"
        var next = {}
        for (var key in snapshots) {
            if (key.indexOf(prefix) !== 0) {
                next[key] = snapshots[key]
            }
        }
        next[keyFor(provider, usageGeneration)] = record
        snapshots = next

        var nextCached = {}
        for (var p in cachedSnapshots) {
            nextCached[p] = cachedSnapshots[p]
        }
        nextCached[provider] = record
        cachedSnapshots = nextCached

        if (cacheEnabled && persist !== false) {
            SnapshotStorage.saveCost(LocalStorage.LocalStorage, provider, record, storageDbName)
        }
    }

    // Failed, malformed, wrong-provider, or non-finite payloads are
    // discarded entirely: the request is released but nothing publishes,
    // and no diagnostic message is ever recorded or exposed.
    function handleData(dataSource, provider, usageGeneration, serial, sourceName, data) {
        if (!isCurrentRequest(dataSource, provider, usageGeneration, serial, sourceName)) {
            return
        }

        var exitCode = data["exit code"]
        var stdout = data.stdout || ""
        var normalized = null
        var failedExit = exitCode !== undefined && Number(exitCode) !== 0 && stdout.length === 0
        if (!failedExit && stdout.length > 0) {
            try {
                normalized = CostModel.normalize(JSON.parse(stdout), provider)
            } catch (error) {
                normalized = null
            }
        }

        releaseActive()

        if (normalized !== null) {
            commitSnapshot(provider, usageGeneration, normalized)
        }

        processNextQueued()
    }

    function timeoutRequest(serial) {
        if (!requestActive || activeSerial !== serial) {
            return
        }
        releaseActive()
        processNextQueued()
    }

    // Fixture-only entry points mirror UsageController's test seams.
    function completeForTest(serial, stdout, exitCode) {
        handleData(dataSource, activeProvider, activeGeneration, serial, activeSource, {
            stdout: stdout,
            "exit code": exitCode
        })
    }

    function timeoutForTest(serial) {
        timeoutRequest(serial)
    }

    property int watchdogSerial: 0

    Timer {
        id: watchdog
        interval: root.timeoutMs
        repeat: false
        onTriggered: root.timeoutRequest(root.watchdogSerial)
    }

    Plasma5Support.DataSource {
        id: dataSource
        engine: "executable"
        property string connectionProvider: ""
        property int connectionGeneration: 0
        property int connectionSerial: 0
        onNewData: function(sourceName, data) {
            if (connectionSerial !== 0) {
                root.handleData(dataSource, connectionProvider, connectionGeneration,
                                 connectionSerial, sourceName, data)
            }
        }
    }

    Component.onDestruction: releaseActive()
}
