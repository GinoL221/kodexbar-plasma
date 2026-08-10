import QtQuick
import QtQuick.Window
import QtTest

TestCase {
    id: testCase
    name: "SettingsInteraction"
    when: windowShown

    property var settings
    property var cliControl
    property var refreshControl

    Window {
        id: testWindow
        width: 900
        height: 500
        visible: true
        color: "white"

        Component.onCompleted: {
            var component = Qt.createComponent(Qt.resolvedUrl("../contents/ui/config/configGeneral.qml"))
            verify(component.status === Component.Ready, "the native settings page must load")
            testCase.settings = component.createObject(contentItem, {
                "width": width,
                "height": height,
                "cfg_codexbarCommandDefault": "/usr/bin/codexbar",
                "cfg_codexbarCommand": "/usr/bin/codexbar",
                "cfg_refreshInterval": 60,
                "cfg_requestTimeout": 60
            })
            verify(testCase.settings !== null, "the native settings page must instantiate")
            testCase.cliControl = testCase.findByProperty(testCase.settings, "placeholderText", "/home/ginopc/.local/bin/codexbar")
            testCase.refreshControl = testCase.findByRange(testCase.settings, 1, 3600)
        }
    }

    function findByProperty(item, propertyName, expectedValue) {
        if (!item) {
            return null
        }
        if (item[propertyName] === expectedValue) {
            return item
        }
        var children = item.children || []
        for (var index = 0; index < children.length; ++index) {
            var result = findByProperty(children[index], propertyName, expectedValue)
            if (result) {
                return result
            }
        }
        return null
    }

    function findByRange(item, minimum, maximum) {
        if (!item) {
            return null
        }
        if (item.from === minimum && item.to === maximum) {
            return item
        }
        var children = item.children || []
        for (var index = 0; index < children.length; ++index) {
            var result = findByRange(children[index], minimum, maximum)
            if (result) {
                return result
            }
        }
        return null
    }

    function initTestCase() {
        verify(settings !== null, "settings must be ready before interaction tests")
        verify(cliControl !== null, "the native CLI path field must be discoverable")
        verify(refreshControl !== null, "the native refresh control must be discoverable")
        testWindow.requestActivate()
        tryCompare(testWindow, "active", true)
    }

    function init() {
        settings.cfg_codexbarCommand = "/usr/bin/codexbar"
        settings.cfg_refreshInterval = 60
        settings.cfg_requestTimeout = 60
        wait(0)
    }

    function typeText(text) {
        for (var index = 0; index < text.length; ++index) {
            keyClick(text.charAt(index))
        }
    }

    function test_cliPathEditingAndValidation() {
        cliControl.text = ""
        cliControl.forceActiveFocus()
        tryVerify(function() { return cliControl.activeFocus }, 1000, "the CLI path field must accept focus")
        keyClick("/")
        keyClick(Qt.Key_Tab)
        compare(settings.cfg_codexbarCommand, "/")

        cliControl.text = "relative/codexbar"
        cliControl.forceActiveFocus()
        cliControl.editingFinished()
        compare(settings.cfg_codexbarCommand, "/usr/bin/codexbar")
    }

    function test_customTimeoutEditing() {
        var custom = settings.requestTimeoutCustomControl
        custom.forceActiveFocus()
        for (var value = 60; value < 150; ++value) {
            keyClick(Qt.Key_Up)
        }
        compare(settings.cfg_requestTimeout, 150)
        compare(settings.requestTimeoutPresetControl.currentIndex, 3)
    }

    function test_refreshIsIndependentFromTimeout() {
        settings.cfg_refreshInterval = 75
        settings.cfg_requestTimeout = 180
        compare(settings.cfg_refreshInterval, 75)
        compare(settings.cfg_requestTimeout, 180)
        compare(settings.requestTimeoutPresetControl.currentIndex, 2)

        mouseClick(settings.requestTimeoutPresetControl)
        tryCompare(settings.requestTimeoutPresetControl.popup, "visible", true)
        keyClick(Qt.Key_Home)
        keyClick(Qt.Key_Enter)
        compare(settings.cfg_requestTimeout, 60)
        compare(settings.cfg_refreshInterval, 75)
    }

    function test_tabTraversalUsesNativeFocus() {
        cliControl.forceActiveFocus()
        verify(cliControl.activeFocus, "tab traversal must start at the CLI path field")
        keyClick(Qt.Key_Tab)
        verify(refreshControl.activeFocus, "Tab must move focus to refresh interval")
        keyClick(Qt.Key_Tab)
        verify(settings.requestTimeoutPresetControl.activeFocus, "Tab must move focus to timeout preset")
        keyClick(Qt.Key_Tab)
        verify(settings.requestTimeoutCustomControl.activeFocus, "Tab must move focus to custom timeout")
    }

    function test_timeoutPresetMouseSelection() {
        var preset = settings.requestTimeoutPresetControl
        preset.forceActiveFocus()
        mouseClick(preset)
        tryCompare(preset.popup, "visible", true)
        keyClick(Qt.Key_Down)
        keyClick(Qt.Key_Enter)
        compare(settings.cfg_requestTimeout, 120)
        compare(preset.currentIndex, 1)

        mouseClick(preset)
        tryCompare(preset.popup, "visible", true)
        keyClick(Qt.Key_Down)
        keyClick(Qt.Key_Enter)
        compare(settings.cfg_requestTimeout, 180)
        compare(preset.currentIndex, 2)
    }
}
