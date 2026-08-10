import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false

    property int activationCount: 0

    function assert(condition, message) {
        if (!condition) {
            console.error("CompactUsageButtonHarness failure: " + message)
            assertionFailed = true
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    UsageUi.CompactUsageButton {
        id: button
        usageText: "42%"
        onClicked: root.activationCount += 1
    }

    Component.onCompleted: {
        assert(button.activeFocusOnTab, "the compact control must participate in keyboard traversal")
        button.forceActiveFocus()
        assert(button.activeFocus, "the compact control must accept keyboard focus")
        assert(button.focusPolicy === Qt.StrongFocus, "the compact control must be reachable from keyboard focus navigation")
        assert(button.Accessible.name.indexOf("42%") !== -1, "the compact control must expose its status to assistive technology")
        assert(button.enabled, "Return and Space activation must remain available on the enabled native control")
        assert(typeof button.click === "function", "the native control must expose its standard activation path")
        button.click()
        assert(root.activationCount === 1, "the native button activation path must open details")
        finish()
    }
}
