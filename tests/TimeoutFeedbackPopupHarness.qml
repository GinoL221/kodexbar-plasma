import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false
    width: 240
    height: 210

    function assert(condition, message) {
        if (!condition) {
            console.error("TimeoutFeedbackPopupHarness failure:", message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    UsageUi.UsageController {
        id: controller
        commandPath: "/tmp/codexbar"
        testMode: true
        timeoutMs: 180000
    }

    ColumnLayout {
        id: popup
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        QQC2.ToolButton {
            id: refreshButton
            icon.name: "view-refresh"
            text: "Refresh"
            Accessible.name: text
            onClicked: controller.requestRefresh()
        }

        PlasmaComponents.Label {
            id: guidance
            visible: controller.phase === "error"
            text: controller.errorMessage
            color: Kirigami.Theme.negativeTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    Component.onCompleted: Qt.callLater(function() {
        controller.requestRefresh()
        controller.completeForTest(controller.generation, JSON.stringify([
            { provider: "snapshot", usage: { primary: { usedPercent: 75 } } }
        ]), 0)
        controller.requestRefresh()
        controller.timeoutForTest(controller.generation)

        Qt.callLater(function() {
            assert(root.width === 240 && root.height === 210, "the harness must use constrained popup geometry")
            assert(guidance.visible, "timeout guidance must remain visible in the popup")
            assert(guidance.text === "CodexBar did not return all-provider usage within 180 seconds. Check enabled providers in CodexBar, temporarily disable a provider that hangs, then retry.", "timeout guidance must retain the exact readable message")
            assert(guidance.wrapMode === Text.WordWrap && guidance.width <= root.width, "timeout guidance must wrap inside the narrow popup")
            assert(refreshButton.Accessible.name === "Refresh", "Refresh must expose a readable accessible name")
            refreshButton.forceActiveFocus()
            assert(refreshButton.activeFocus, "Refresh must be keyboard reachable")
            refreshButton.click()
            assert(controller.phase === "loading", "Refresh must start a new loading attempt after timeout")
            assert(controller.committedProviders.length === 1, "Refresh must retain the committed snapshot while loading")
            finish()
        })
    })
}
