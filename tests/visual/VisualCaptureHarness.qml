import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../../contents/ui" as UsageUi

QQC2.ApplicationWindow {
    id: root
    width: 450
    height: 400
    visible: true
    title: "KodexBar visual fixture"
    font.family: "Noto Sans"
    font.pixelSize: 14

    property string scenarioName: scenarioArgument()
    property string outputPath: argumentValue("--output")
    property int captureTimeoutMs: Number(argumentValue("--capture-timeout-ms") || 5000)
    property string expectedTheme: scenarioName.indexOf("breeze-light-") === 0 ? "light"
        : scenarioName.indexOf("breeze-dark-") === 0 ? "dark" : ""
    property bool costPresent: scenarioName.indexOf("-cost-present") !== -1
    property bool assertionFailed: false
    property string captureState: "precondition"
    property bool simulateGrabFalse: hasArgument("--simulate-grab-false")
    property bool simulateAbsentCallback: hasArgument("--simulate-absent-callback")
    property bool simulateSaveFailure: hasArgument("--simulate-save-failure")
    property bool simulateWrongSize: hasArgument("--simulate-wrong-size")

    function scenarioArgument() {
        return argumentValue("--scenario")
    }

    function argumentValue(name) {
        var arguments = Qt.application.arguments
        for (var index = 0; index < arguments.length; ++index) {
            if (arguments[index] === name && index + 1 < arguments.length)
                return arguments[index + 1]
        }
        return ""
    }

    function hasArgument(name) {
        return Qt.application.arguments.indexOf(name) !== -1
    }

    function assert(condition, message) {
        if (!condition) {
            console.error("VisualCaptureHarness " + scenarioName + ": " + message)
            assertionFailed = true
        }
    }

    function luminance(color) {
        return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
    }

    function findObject(item, name) {
        if (item.objectName === name)
            return item
        for (var index = 0; index < item.children.length; ++index) {
            var result = findObject(item.children[index], name)
            if (result !== null)
                return result
        }
        return null
    }

    function failCapture(message) {
        console.error("VisualCaptureHarness " + scenarioName + ": " + message)
        captureTimeout.stop()
        Qt.exit(1)
    }

    function saveCapture(result) {
        if (simulateAbsentCallback)
            return
        if (result === null || result === undefined) {
            failCapture("capture callback returned no image")
            return
        }
        if (simulateSaveFailure || !result.saveToFile(outputPath)) {
            failCapture("capture save failed: " + outputPath)
            return
        }
        captureTimeout.stop()
        captureState = "saved"
        captureState = "complete"
        Qt.exit(0)
    }

    function requestCapture() {
        captureState = "capturing"
        captureTimeout.start()
        if (simulateGrabFalse) {
            failCapture("grabToImage request failed")
            return
        }
        if (simulateWrongSize) {
            failCapture("capture image dimensions must remain 450x400")
            return
        }
        var requested = fixtureViewport.grabToImage(saveCapture, Qt.size(width, height))
        if (!requested)
            failCapture("grabToImage request failed")
    }

    QQC2.ScrollView {
        id: fixtureViewport
        anchors.fill: parent
        contentWidth: availableWidth
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
        QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AsNeeded

        ColumnLayout {
            id: fixtureColumn
            width: fixtureViewport.availableWidth
            spacing: Kirigami.Units.smallSpacing

            UsageUi.ProviderRow {
                id: providerRow
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                providerData: ({
                    provider: "fixture-provider",
                    source: "fixture-source",
                    windows: [
                        { label: "Session", usedPercent: 42, resetDescription: "Resets tomorrow" },
                        { label: "Weekly", usedPercent: 13 }
                    ],
                    raw: {
                        version: "fixture-version",
                        pace: { primary: { summary: "On pace" } },
                        credits: { remaining: 12 },
                        usage: {
                            loginMethod: "fixture-login",
                            updatedAt: "2026-08-15T12:00:00Z",
                            identity: {
                                accountEmail: "fixture@example.invalid",
                                accountOrganization: "Fixture Labs"
                            }
                        }
                    }
                })
                costSnapshot: root.costPresent ? ({
                    provider: "fixture-provider",
                    source: "local",
                    sessionCostUSD: 1.5,
                    sessionTokens: 1000,
                    last30DaysCostUSD: 12,
                    last30DaysTokens: 50000
                }) : null
            }
        }
    }

    Timer {
        id: captureTimeout
        interval: root.captureTimeoutMs
        repeat: false
        onTriggered: root.failCapture("capture timed out after " + root.captureTimeoutMs + "ms")
    }

    Timer {
        interval: 250
        running: true
        repeat: false
        onTriggered: {
            var backgroundIsDark = root.luminance(Kirigami.Theme.backgroundColor)
                < root.luminance(Kirigami.Theme.textColor)
            var providerLabel = root.findObject(providerRow, "providerLabel")
            var sourceLabel = root.findObject(providerRow, "sourceLabel")
            var costLabel = root.findObject(providerRow, "costLabel")

            root.assert(root.expectedTheme.length > 0,
                "unknown scenario must name a Breeze Light or Dark scenario")
            root.assert(root.expectedTheme === "dark" ? backgroundIsDark : !backgroundIsDark,
                "theme mismatch for " + root.expectedTheme + " scenario; capture skipped")
            root.assert(root.width === 450 && root.height === 400,
                "fixture dimensions must remain 450x400")
            root.assert(root.font.family === "Noto Sans", "fixture font must remain Noto Sans")
            root.assert(fixtureViewport.contentWidth === fixtureViewport.availableWidth,
                "fixture must not create horizontal overflow")
            root.assert(providerRow.width === fixtureColumn.width && providerRow.width > 0,
                "selected-provider row must use the fixture viewport width")
            root.assert(providerRow.Accessible.name.indexOf("fixture-provider") !== -1,
                "selected-provider row must expose its accessible provider name")
            root.assert(providerLabel !== null && sourceLabel !== null
                && providerLabel.x >= 0 && providerLabel.x + providerLabel.width <= providerRow.width
                && sourceLabel.x >= 0 && sourceLabel.x + sourceLabel.width <= providerRow.width,
                "header labels must remain within selected-provider bounds")
            root.assert(root.costPresent ? costLabel !== null && costLabel.visible
                : costLabel === null || !costLabel.visible,
                "cost visibility must match the scenario state")

            if (root.assertionFailed) {
                Qt.exit(1)
                return
            }
            if (root.outputPath.length === 0) {
                Qt.exit(0)
                return
            }
            root.requestCapture()
        }
    }
}
