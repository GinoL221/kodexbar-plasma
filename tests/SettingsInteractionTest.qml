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
    property var setupGuidance
    property var preferredWindowControl
    property var preferredWindowGuidance

    Window {
        id: testWindow
        width: 900
        height: 500
        visible: true
        color: "white"

        Component.onCompleted: {
            var component = Qt.createComponent(Qt.resolvedUrl("../contents/ui/config/configGeneral.qml"))
            testCase.verify(component.status === Component.Ready, "the native settings page must load")
            testCase.settings = component.createObject(contentItem, {
                "width": width,
                "height": height,
                "cfg_codexbarCommandDefault": "",
                "cfg_codexbarCommand": "",
                "cfg_refreshInterval": 60,
                "cfg_requestTimeout": 60,
                "cfg_preferredRepresentativeWindow": "automatic"
            })
            testCase.verify(testCase.settings !== null, "the native settings page must instantiate")
            testCase.cliControl = testCase.findByProperty(testCase.settings, "objectName", "codexbarCommand")
            testCase.refreshControl = testCase.findByRange(testCase.settings, 1, 3600)
            testCase.setupGuidance = testCase.findByProperty(testCase.settings, "objectName", "codexbarSetupGuidance")
            testCase.preferredWindowControl = testCase.findByProperty(testCase.settings, "objectName", "preferredRepresentativeWindow")
            testCase.preferredWindowGuidance = testCase.findByProperty(testCase.settings, "objectName", "preferredWindowGuidance")
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
        verify(setupGuidance !== null, "the native setup guidance must be discoverable")
        verify(preferredWindowControl !== null, "the native representative window control must be discoverable")
        verify(preferredWindowGuidance !== null, "the native representative window guidance must be discoverable")
        testWindow.requestActivate()
        tryCompare(testWindow, "active", true)
    }

    function init() {
        settings.cfg_codexbarCommand = ""
        settings.cfg_refreshInterval = 60
        settings.cfg_requestTimeout = 60
        settings.cfg_preferredRepresentativeWindow = "automatic"
        wait(0)
    }

    function typeText(text) {
        for (var index = 0; index < text.length; ++index) {
            keyClick(text.charAt(index))
        }
    }

    function test_cliPathAllowsEmptyAndRejectsRelativePaths() {
        verify(cliControl.placeholderText !== "/home/redacted-user/.local/bin/codexbar",
               "the CLI field must not expose a user-specific placeholder")
        cliControl.text = ""
        cliControl.forceActiveFocus()
        tryVerify(function() { return cliControl.activeFocus }, 1000, "the CLI path field must accept focus")
        cliControl.editingFinished()
        compare(settings.cfg_codexbarCommand, "")

        cliControl.text = "relative/codexbar"
        cliControl.forceActiveFocus()
        cliControl.editingFinished()
        compare(settings.cfg_codexbarCommand, "")
    }

    function test_cliPathProvidesNativeSetupGuidance() {
        verify(setupGuidance.visible, "manual setup guidance must remain visible when no path is configured")
        verify(setupGuidance.Accessible.name.length > 0,
               "manual setup guidance must have an accessible name")
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
        keyClick(Qt.Key_Tab)
        verify(preferredWindowControl.activeFocus, "Tab must move focus to the representative window control")
    }

    function test_preferredWindowControlIsDiscoverableAndDefaulted() {
        compare(preferredWindowControl.currentIndex, 0, "the representative window control must default to index 0")
        compare(settings.cfg_preferredRepresentativeWindow, "automatic", "the default persisted value must be automatic")
        verify(preferredWindowGuidance.visible, "the representative window guidance must be visible")
        verify(preferredWindowGuidance.Accessible.name.length > 0,
               "the representative window guidance must have a non-empty accessible name")
    }

    function test_preferredWindowSelectionPersistsKeys() {
        preferredWindowControl.forceActiveFocus()
        mouseClick(preferredWindowControl)
        tryCompare(preferredWindowControl.popup, "visible", true)
        keyClick(Qt.Key_Down)
        keyClick(Qt.Key_Enter)
        compare(settings.cfg_preferredRepresentativeWindow, "session")
        compare(preferredWindowControl.currentIndex, 1)

        mouseClick(preferredWindowControl)
        tryCompare(preferredWindowControl.popup, "visible", true)
        keyClick(Qt.Key_Down)
        keyClick(Qt.Key_Enter)
        compare(settings.cfg_preferredRepresentativeWindow, "weekly")
        compare(preferredWindowControl.currentIndex, 2)

        mouseClick(preferredWindowControl)
        tryCompare(preferredWindowControl.popup, "visible", true)
        keyClick(Qt.Key_Down)
        keyClick(Qt.Key_Enter)
        compare(settings.cfg_preferredRepresentativeWindow, "monthly")
        compare(preferredWindowControl.currentIndex, 3)
    }

    function test_preferredWindowIsIndependentFromTimeout() {
        settings.cfg_requestTimeout = 180
        settings.cfg_refreshInterval = 75

        mouseClick(preferredWindowControl)
        tryCompare(preferredWindowControl.popup, "visible", true)
        keyClick(Qt.Key_Down)
        keyClick(Qt.Key_Enter)

        compare(settings.cfg_preferredRepresentativeWindow, "session")
        compare(settings.cfg_requestTimeout, 180)
        compare(settings.cfg_refreshInterval, 75)
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
