import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

import "../code/UsageModel.js" as UsageModel

Item {
    id: root

    property string commandPath: "/home/ginopc/.local/bin/codexbar"
    property int timeoutMs: 15000
    property int activeTimeoutMs: timeoutMs
    property bool testMode: false
    property bool pathExecutableForTest: true

    property string phase: "idle"
    property string errorMessage: ""
    property var committedProviders: []
    property var committedErrors: []
    property int generation: 0
    property bool refreshQueued: false
    property bool followUpScheduled: false
    property bool requestActive: false
    property string activeStage: ""
    property string activeSource: ""
    property int activeGeneration: 0
    property var activeDataSource: null
    readonly property int activeRequestCount: requestActive ? 1 : 0

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function commandLine() {
        return shellQuote(commandPath) + " usage --provider all --format json --json-only"
    }

    function pathCheckCommand() {
        return "test -x " + shellQuote(commandPath)
    }

    function validatePath(path) {
        var value = String(path || "").trim()
        if (value.length === 0) {
            return { valid: false, error: "Configure an absolute CodexBar CLI path." }
        }
        if (value.charAt(0) !== "/") {
            return { valid: false, error: "The CodexBar CLI path must be absolute." }
        }
        if (value.indexOf("\n") !== -1 || value.indexOf("\r") !== -1) {
            return { valid: false, error: "The CodexBar CLI path cannot contain a line break." }
        }
        return { valid: true, error: "" }
    }

    function requestRefresh() {
        if (requestActive) {
            refreshQueued = true
            return
        }

        var validation = validatePath(commandPath)
        if (!validation.valid) {
            phase = "error"
            errorMessage = validation.error
            return
        }

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

    function startPathCheck() {
        var requestGeneration = beginGeneration()
        if (testMode) {
            if (!pathExecutableForTest) {
                failGeneration("Configured CodexBar CLI path is missing or not executable. Choose an executable absolute path.")
                return
            }
            startCommandStage(requestGeneration)
            return
        }
        beginStage(preflightDataSource, "preflight", pathCheckCommand(), requestGeneration)
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
            failGeneration("Configured CodexBar CLI path is missing or not executable. Choose an executable absolute path.")
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
        failGeneration(activeStage === "preflight"
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
        beginStage(preflightDataSource, "preflight", pathCheckCommand(), requestGeneration)
    }

    function deliverStageForTest(stage, requestGeneration, sourceName, data) {
        var dataSource = stage === "preflight" ? preflightDataSource : commandDataSource
        if (stage === "preflight") {
            handlePreflight(dataSource, requestGeneration, sourceName, data)
        } else {
            handleCommand(dataSource, requestGeneration, sourceName, data)
        }
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
                root.handlePreflight(preflightDataSource, connectionGeneration, sourceName, data)
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
