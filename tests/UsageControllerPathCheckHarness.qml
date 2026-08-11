import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false
    property bool finished: false
    property bool completionCheckScheduled: false

    function assert(condition, message) {
        if (!condition) {
            console.error("UsageControllerPathCheckHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    function checkCompletion() {
        if (finished || completionCheckScheduled
                || missingPath.phase !== "error" || nonExecutablePath.phase !== "error") {
            return
        }

        completionCheckScheduled = true
        Qt.callLater(function() {
            completionCheckScheduled = false
            if (finished) {
                return
            }

            assert(missingPath.activeRequestCount === 0, "missing path must not start the CLI request")
            assert(nonExecutablePath.activeRequestCount === 0, "non-executable path must not start the CLI request")
            assert(missingPath.configurationRequired,
                   "missing path must require manual configuration after discovery fails")
            assert(nonExecutablePath.configurationRequired,
                   "non-executable path must require manual configuration after discovery fails")
            finished = true
            finish()
        })
    }

    Component.onCompleted: {
        missingPath.requestRefresh()
        nonExecutablePath.requestRefresh()
        timeout.start()
    }

    UsageUi.UsageController {
        id: missingPath
        commandPath: "/definitely/missing/kodexbar"
        timeoutMs: 5000
        testMode: true
        pathExecutableForTest: false
        discoveryOutputForTest: ""
        onPhaseChanged: {
            root.checkCompletion()
        }
    }

    UsageUi.UsageController {
        id: nonExecutablePath
        commandPath: "/dev/null"
        timeoutMs: 5000
        testMode: true
        pathExecutableForTest: false
        discoveryOutputForTest: ""
        onPhaseChanged: {
            root.checkCompletion()
        }
    }

    Timer {
        id: timeout
        interval: 6000
        onTriggered: {
            assert(false, "path preflight did not finish")
            Qt.exit(1)
        }
    }
}
