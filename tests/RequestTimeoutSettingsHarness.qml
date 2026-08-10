import QtQuick

Item {
    id: root
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("RequestTimeoutSettingsHarness failure: " + message)
            assertionFailed = true
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        var component = Qt.createComponent("../contents/ui/config/configGeneral.qml")
        assert(component.status === Component.Ready, "the native settings page must load")
        var settings = component.createObject(root)
        assert(settings !== null, "the native settings page must instantiate")
        assert("cfg_requestTimeout" in settings, "request timeout must persist separately from refresh")
        settings.cfg_requestTimeout = 60
        settings.cfg_refreshInterval = 60
        assert(settings.cfg_requestTimeout === 60, "the default timeout must be 60 seconds")
        settings.cfg_requestTimeout = 180
        assert(settings.cfg_requestTimeout === 180, "a custom timeout must persist through the config property")
        assert(settings.cfg_refreshInterval === 60, "timeout selection must not change refresh")
        assert(settings.requestTimeoutPresetControl !== null, "the preset must be exposed for accessible settings verification")
        assert(settings.requestTimeoutCustomControl !== null, "the custom input must be exposed for accessible settings verification")
        assert(settings.requestTimeoutGuidance !== null
               && settings.requestTimeoutGuidance.objectName === "requestTimeoutGuidance"
               && settings.requestTimeoutGuidance.wrapMode === Text.WordWrap,
               "the correction guidance must be exposed and wrap")
        settings.destroy()
        finish()
    }
}
