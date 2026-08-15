import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

import "../code/CostModel.js" as CostModel
import "../code/CodexBarPathResolver.js" as PathResolver

// Isolated, optional cost lifecycle. Keyed by provider + committed usage
// generation + an internal request serial so stale, superseded, or timed-out
// callbacks can never mutate a snapshot or reach UsageController.
Item {
    id: root

    readonly property var allowedProviders: ["codex", "claude"]

    property string commandPath: ""
    property int timeoutMs: 60000
    property bool testMode: false

    readonly property string effectiveCommandPath: _effectiveCommandPath
    property string _effectiveCommandPath: ""

    property var snapshots: ({})

    property bool requestActive: false
    property string activeProvider: ""
    property int activeGeneration: 0
    property int activeSerial: 0
    property string activeSource: ""
    property var activeDataSource: null
    property int requestSerial: 0
    readonly property int activeRequestCount: requestActive ? 1 : 0

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

    // Returns a validated, previously committed snapshot for the exact
    // provider/generation pair, or null when none exists yet.
    function snapshotFor(provider, usageGeneration) {
        var record = snapshots[keyFor(provider, usageGeneration)]
        return record !== undefined ? record : null
    }

    // Requests cost for provider/usageGeneration. An identical active or
    // already-fresh pair coalesces (no duplicate process); any other
    // in-flight request is replaced and its process is terminated.
    function request(provider, usageGeneration) {
        if (!isAllowedProvider(provider) || typeof usageGeneration !== "number") {
            return
        }
        if (snapshotFor(provider, usageGeneration) !== null) {
            return
        }
        if (requestActive && activeProvider === provider && activeGeneration === usageGeneration) {
            return
        }

        var validation = validatePath(commandPath)
        if (!validation.valid) {
            return
        }

        if (requestActive) {
            releaseActive()
        }

        _effectiveCommandPath = validation.path
        startRequest(provider, usageGeneration)
    }

    function startRequest(provider, usageGeneration) {
        requestSerial += 1
        var serial = requestSerial
        requestActive = true
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
        requestActive = false
        watchdog.stop()
        if (pendingDataSource !== null) {
            pendingDataSource.connectionSerial = 0
        }
        if (!testMode && pendingDataSource !== null && source.length > 0) {
            pendingDataSource.disconnectSource(source)
        }
    }

    function commitSnapshot(provider, usageGeneration, record) {
        var next = {}
        for (var key in snapshots) {
            next[key] = snapshots[key]
        }
        next[keyFor(provider, usageGeneration)] = record
        snapshots = next
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
    }

    function timeoutRequest(serial) {
        if (!requestActive || activeSerial !== serial) {
            return
        }
        releaseActive()
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
