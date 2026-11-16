pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

import "../code/CodexBarPathResolver.mjs" as PathResolver

Item {
    id: root

    property string commandPath: ""
    property bool testMode: false
    property int timeoutMs: 10000
    property bool available: false
    property bool switching: false
    property string activeSource: ""
    property string _resolvedPath: ""
    property string _probeSource: ""

    signal switchSucceeded()
    signal switchFailed(string message)

    Component.onCompleted: {
        if (testMode) {
            if (commandPath.length > 0) {
                var validation = PathResolver.validateAbsolutePath(commandPath)
                available = validation.valid
                _resolvedPath = validation.valid ? validation.path : ""
            }
            return
        }
        probeAvailability()
    }

    function probeAvailability() {
        if (testMode) {
            return
        }
        if (commandPath.length > 0) {
            var direct = PathResolver.validateAbsolutePath(commandPath)
            if (direct.valid) {
                _probeSource = PathResolver.pathCheckCommand(direct.path)
                _resolvedPath = direct.path
                probeSource.connectSource(_probeSource)
            }
            return
        }
        _probeSource = "/bin/sh -c " + PathResolver.shellQuote(PathResolver.antigravitySwitchDiscoveryCommand())
        probeSource.connectSource(_probeSource)
    }

    function switchNext() {
        if (!available || switching || _resolvedPath.length === 0) {
            return
        }
        switching = true
        activeSource = PathResolver.shellQuote(_resolvedPath)
        watchdog.interval = timeoutMs
        watchdog.restart()
        if (!testMode) {
            execSource.connectSource(activeSource)
        }
    }

    function finishSwitch(exitCode) {
        if (!switching) {
            return
        }
        var source = activeSource
        switching = false
        activeSource = ""
        watchdog.stop()
        if (!testMode && source.length > 0) {
            execSource.disconnectSource(source)
        }
        if (exitCode === 0) {
            switchSucceeded()
        } else {
            switchFailed("Account switch helper failed")
        }
    }

    function timeoutSwitch() {
        if (!switching) {
            return
        }
        var source = activeSource
        switching = false
        activeSource = ""
        if (!testMode && source.length > 0) {
            execSource.disconnectSource(source)
        }
        switchFailed("Account switch timed out")
    }

    function completeSwitchForTest(exitCode) {
        finishSwitch(exitCode)
    }

    function timeoutForTest() {
        timeoutSwitch()
    }

    Timer {
        id: watchdog
        interval: root.timeoutMs
        repeat: false
        onTriggered: root.timeoutSwitch()
    }

    Plasma5Support.DataSource {
        id: probeSource
        engine: "executable"
        onNewData: function(sourceName, data) {
            if (sourceName !== root._probeSource) {
                return
            }
            probeSource.disconnectSource(sourceName)
            root._probeSource = ""
            var exitCode = Number(data["exit code"])
            if (exitCode !== 0) {
                root.available = false
                root._resolvedPath = ""
                return
            }
            var candidate = root._resolvedPath.length > 0
                ? root._resolvedPath
                : String(data.stdout || "").replace(/\r?\n$/, "").trim()
            var checked = PathResolver.validateAbsolutePath(candidate)
            root.available = checked.valid
            root._resolvedPath = checked.valid ? checked.path : ""
        }
    }

    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        onNewData: function(sourceName, data) {
            if (sourceName !== root.activeSource) {
                return
            }
            root.finishSwitch(Number(data["exit code"]))
        }
    }

    Component.onDestruction: {
        watchdog.stop()
        if (!testMode && _probeSource.length > 0) {
            probeSource.disconnectSource(_probeSource)
        }
        if (!testMode && activeSource.length > 0) {
            execSource.disconnectSource(activeSource)
        }
    }
}
