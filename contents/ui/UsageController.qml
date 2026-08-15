import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

import "../code/UsageModel.js" as UsageModel
import "../code/CodexBarPathResolver.js" as PathResolver

Item {
    id: root

    property string commandPath: ""
    property int timeoutMs: 15000
    property int activeTimeoutMs: timeoutMs
    property bool testMode: false
    property bool pathExecutableForTest: true
    property string discoveryOutputForTest: ""
    property string discoveredPathForTest: ""
    readonly property string effectiveCommandPath: _effectiveCommandPath
    property string _effectiveCommandPath: ""
    property bool configurationRequired: false

    property string phase: "idle"
    property string errorMessage: ""
    property var committedProviders: []
    property var committedErrors: []
    property int committedGeneration: 0
    property int generation: 0
    property bool refreshQueued: false
    property bool followUpScheduled: false
    property bool requestActive: false
    property string activeStage: ""
    property string activeSource: ""
    property int activeGeneration: 0
    property var activeDataSource: null
    readonly property int activeRequestCount: requestActive ? 1 : 0

    signal pathDiscovered(string path)

    function commandLine() {
        return PathResolver.shellQuote(effectiveCommandPath) + " usage --provider all --format json --json-only"
    }

    function pathCheckCommand() {
        return PathResolver.pathCheckCommand(effectiveCommandPath)
    }

    function validatePath(path) {
        return PathResolver.validateAbsolutePath(path)
    }

    function requestRefresh() {
        if (requestActive) {
            refreshQueued = true
            return
        }

        var validation = validatePath(commandPath)
        if (!validation.valid) {
            startDiscovery()
            return
        }

        configurationRequired = false
        _effectiveCommandPath = validation.path
        startPathCheck()
    }

    function beginGeneration() {
        generation += 1
        requestActive = true
        activeGeneration = generation
        phase = "loading"
        errorMessage = ""
        activeTimeoutMs = timeoutMs
        return generation
    }

    function beginStage(dataSource, stage, source, requestGeneration) {
        activeDataSource = dataSource
        activeStage = stage
        activeSource = source
        activeGeneration = requestGeneration
        dataSource.connectionGeneration = requestGeneration
        watchdogGeneration = requestGeneration
        watchdog.restart()
        if (!testMode) {
            dataSource.connectSource(source)
        }
    }

    function startPathCheck(requestGeneration) {
        if (requestGeneration === undefined) {
            requestGeneration = beginGeneration()
        }
        if (testMode) {
            if (!pathExecutableForTest) {
                startDiscovery(requestGeneration)
                return
            }
            startCommandStage(requestGeneration)
            return
        }
        beginStage(preflightDataSource, "preflight", pathCheckCommand(), requestGeneration)
    }

    function startDiscovery(requestGeneration) {
        if (requestGeneration === undefined) {
            requestGeneration = beginGeneration()
        }
        if (testMode) {
            beginStage(preflightDataSource, "discovery", PathResolver.discoveryCommand(), requestGeneration)
            handleDiscovery(preflightDataSource, requestGeneration, activeSource, {
                stdout: discoveryOutputForTest,
                "exit code": discoveryOutputForTest.length > 0 ? 0 : 1
            })
            return
        }
        beginStage(preflightDataSource, "discovery", PathResolver.discoveryCommand(), requestGeneration)
    }

    function startCommandStage(requestGeneration) {
        if (!requestActive || generation !== requestGeneration || activeGeneration !== requestGeneration) {
            return
        }
        phase = "loading"
        beginStage(commandDataSource, "command", commandLine(), requestGeneration)
    }

    function isCurrentStage(dataSource, stage, requestGeneration, sourceName) {
        return requestActive
            && activeDataSource === dataSource
            && activeStage === stage
            && activeSource === sourceName
            && activeGeneration === requestGeneration
            && generation === requestGeneration
    }

    function releaseStage() {
        var dataSource = activeDataSource
        var source = activeSource
        activeDataSource = null
        activeStage = ""
        activeSource = ""
        watchdog.stop()
        if (dataSource !== null) {
            dataSource.connectionGeneration = 0
        }
        if (!testMode && dataSource !== null && source.length > 0) {
            dataSource.disconnectSource(source)
        }
    }

    function releaseGeneration(scheduleFollowUp) {
        releaseStage()
        requestActive = false
        activeGeneration = 0
        if (scheduleFollowUp && refreshQueued && !followUpScheduled) {
            refreshQueued = false
            requestRefresh()
        }
    }

    function failGeneration(message) {
        phase = "error"
        errorMessage = message
        releaseGeneration(true)
    }

    function handlePreflight(dataSource, requestGeneration, sourceName, data) {
        if (!isCurrentStage(dataSource, "preflight", requestGeneration, sourceName)) {
            return
        }
        if (Number(data["exit code"]) !== 0) {
            releaseStage()
            startDiscovery(requestGeneration)
            return
        }
        releaseStage()
        Qt.callLater(function() {
            if (requestActive && generation === requestGeneration && activeGeneration === requestGeneration
                    && activeStage === "") {
                startCommandStage(requestGeneration)
            }
        })
    }

    function handlePreflightData(dataSource, requestGeneration, sourceName, data) {
        if (activeStage === "discovery") {
            handleDiscovery(dataSource, requestGeneration, sourceName, data)
            return
        }
        handlePreflight(dataSource, requestGeneration, sourceName, data)
    }

    function handleDiscovery(dataSource, requestGeneration, sourceName, data) {
        if (!isCurrentStage(dataSource, "discovery", requestGeneration, sourceName)) {
            return
        }
        var output = String(data.stdout || "").replace(/\r?\n$/, "")
        var validation = Number(data["exit code"]) === 0
            ? validatePath(output)
            : { valid: false }
        if (!validation.valid) {
            configurationRequired = true
            failGeneration("CodexBar CLI was not found in approved locations. Configure an executable absolute path.")
            return
        }
        _effectiveCommandPath = validation.path
        discoveredPathForTest = validation.path
        configurationRequired = false
        pathDiscovered(validation.path)
        releaseStage()
        Qt.callLater(function() {
            if (requestActive && generation === requestGeneration && activeGeneration === requestGeneration
                    && activeStage === "") {
                startPathCheck(requestGeneration)
            }
        })
    }

    function handleCommand(dataSource, requestGeneration, sourceName, data) {
        if (!isCurrentStage(dataSource, "command", requestGeneration, sourceName)) {
            return
        }
        var exitCode = data["exit code"]
        var stdout = data.stdout || ""
        if (exitCode !== undefined && Number(exitCode) !== 0 && stdout.length === 0) {
            failGeneration(data.stderr || "CodexBar CLI exited with code " + exitCode + ".")
            return
        }

        if (stdout.length === 0) {
            failGeneration("CodexBar CLI returned no output.")
            return
        }

        var payload
        try {
            payload = JSON.parse(stdout)
        } catch (error) {
            failGeneration("CodexBar CLI returned invalid JSON: " + String(error))
            return
        }

        var normalized = UsageModel.normalize(payload)
        committedProviders = normalized.providers
        committedErrors = normalized.errors
        committedGeneration = requestGeneration
        phase = normalized.providers.length > 0 ? "ready"
            : (normalized.errors.length > 0 ? "error" : "noData")
        errorMessage = normalized.errors.length > 0 && normalized.providers.length === 0
            ? "CodexBar returned provider errors."
            : ""
        releaseGeneration(true)
    }

    function timeoutRequest(requestGeneration) {
        if (!requestActive || generation !== requestGeneration || activeGeneration !== requestGeneration) {
            return
        }
        failGeneration(activeStage === "preflight" || activeStage === "discovery"
                       ? "CodexBar CLI path validation timed out. Check that the configured path is available."
                       : "CodexBar did not return all-provider usage within " + (activeTimeoutMs / 1000) + " seconds. Check enabled providers in CodexBar, temporarily disable a provider that hangs, then retry.")
    }

    // Fixture-only entry points exercise the same persistent-stage guards without a process.
    function startPreflightForTest() {
        if (requestActive) {
            refreshQueued = true
            return
        }
        var requestGeneration = beginGeneration()
        var validation = validatePath(commandPath)
        _effectiveCommandPath = validation.valid ? validation.path : ""
        beginStage(preflightDataSource, "preflight", pathCheckCommand(), requestGeneration)
    }

    function deliverStageForTest(stage, requestGeneration, sourceName, data) {
        var dataSource = stage === "preflight" ? preflightDataSource : commandDataSource
        if (stage === "preflight") {
            handlePreflight(dataSource, requestGeneration, sourceName, data)
        } else if (stage === "discovery") {
            handleDiscovery(dataSource, requestGeneration, sourceName, data)
        } else {
            handleCommand(dataSource, requestGeneration, sourceName, data)
        }
    }

    function deliverPreflightDataForTest(data) {
        handlePreflightData(preflightDataSource, generation, activeSource, data)
    }

    // This mirrors a DataSource callback whose generation was captured at connection time.
    function deliverLiveStageForTest(stage, capturedGeneration, sourceName, data) {
        deliverStageForTest(stage, capturedGeneration, sourceName, data)
    }

    function completeForTest(requestGeneration, stdout, exitCode) {
        if (!requestActive || activeStage !== "command") {
            return
        }
        handleCommand(commandDataSource, requestGeneration, activeSource, {
            stdout: stdout,
            stderr: "",
            "exit code": exitCode
        })
    }

    function timeoutForTest(requestGeneration) {
        timeoutRequest(requestGeneration)
    }

    function setPathExecutableForTest(executable) {
        pathExecutableForTest = executable
    }

    property int watchdogGeneration: 0

    Timer {
        id: watchdog
        interval: root.activeTimeoutMs
        repeat: false
        onTriggered: root.timeoutRequest(root.watchdogGeneration)
    }

    Plasma5Support.DataSource {
        id: preflightDataSource
        engine: "executable"
        property int connectionGeneration: 0
        onNewData: function(sourceName, data) {
            if (connectionGeneration !== 0) {
                root.handlePreflightData(preflightDataSource, connectionGeneration, sourceName, data)
            }
        }
    }

    Plasma5Support.DataSource {
        id: commandDataSource
        engine: "executable"
        property int connectionGeneration: 0
        onNewData: function(sourceName, data) {
            if (connectionGeneration !== 0) {
                root.handleCommand(commandDataSource, connectionGeneration, sourceName, data)
            }
        }
    }

    Component.onDestruction: releaseGeneration(false)
}
