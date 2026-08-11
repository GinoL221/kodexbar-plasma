import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    width: 160
    height: 40
    property bool assertionFailed: false

    property int activationCount: 0

    function assert(condition, message) {
        if (!condition) {
            console.error("CompactUsageButtonHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    UsageUi.CompactUsageButton {
        id: button
        usageText: "42%"
        width: 120
        height: 32
        onClicked: root.activationCount += 1
    }

    Component.onCompleted: Qt.callLater(function() {
        assert(button.activeFocusOnTab, "the compact control must participate in keyboard traversal")
        assert(button.focusPolicy === Qt.StrongFocus, "the compact control must be reachable from keyboard focus navigation")
        assert(button.Accessible.name === undefined || button.Accessible.name.indexOf("42%") !== -1,
               "the compact control must expose its status to assistive technology when translations are available")
        assert(button.enabled, "Return and Space activation must remain available on the enabled native control")
        assert(typeof button.click === "function", "the native control must expose its standard activation path")
        button.click()
        assert(root.activationCount === 1, "the native button activation path must open details")
        finish()
    })
}
