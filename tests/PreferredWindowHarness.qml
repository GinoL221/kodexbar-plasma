import QtQuick
import "../contents/code/PreferredWindow.js" as PreferredWindow
import "../contents/code/UsageModel.js" as UsageModel

Item {
    property bool assertionFailed: false
    property var configPage: null

    function assert(condition, message) {
        if (!condition) {
            console.error("PreferredWindowHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        assert(PreferredWindow.DEFAULT_KEY === "automatic", "the default key must be automatic")

        assert(PreferredWindow.parse("automatic") === "automatic", "automatic must be a valid key")
        assert(PreferredWindow.parse("session") === "session", "session must be a valid key")
        assert(PreferredWindow.parse("weekly") === "weekly", "weekly must be a valid key")
        assert(PreferredWindow.parse("monthly") === "monthly", "monthly must be a valid key")

        assert(PreferredWindow.parse(undefined) === null, "undefined must be rejected")
        assert(PreferredWindow.parse(null) === null, "null must be rejected")
        assert(PreferredWindow.parse("") === null, "empty string must be rejected")
        assert(PreferredWindow.parse("Weekly") === null, "capitalized keys must be rejected")
        assert(PreferredWindow.parse("WEEKLY") === null, "uppercase keys must be rejected")
        assert(PreferredWindow.parse(" weekly") === null, "keys with leading whitespace must be rejected")
        assert(PreferredWindow.parse("yearly") === null, "unrecognized keys must be rejected")
        assert(PreferredWindow.parse(123) === null, "numbers must be rejected")
        assert(PreferredWindow.parse(NaN) === null, "NaN must be rejected")
        assert(PreferredWindow.parse(["weekly"]) === null, "arrays must be rejected")

        assert(PreferredWindow.keyOrDefault(undefined) === "automatic", "undefined must fall back to automatic")
        assert(PreferredWindow.keyOrDefault(null) === "automatic", "null must fall back to automatic")
        assert(PreferredWindow.keyOrDefault("") === "automatic", "empty string must fall back to automatic")
        assert(PreferredWindow.keyOrDefault("Weekly") === "automatic", "capitalized keys must fall back to automatic")
        assert(PreferredWindow.keyOrDefault("WEEKLY") === "automatic", "uppercase keys must fall back to automatic")
        assert(PreferredWindow.keyOrDefault(" weekly") === "automatic", "whitespace-padded keys must fall back to automatic")
        assert(PreferredWindow.keyOrDefault("yearly") === "automatic", "unrecognized keys must fall back to automatic")
        assert(PreferredWindow.keyOrDefault(123) === "automatic", "numbers must fall back to automatic")
        assert(PreferredWindow.keyOrDefault(NaN) === "automatic", "NaN must fall back to automatic")
        assert(PreferredWindow.keyOrDefault(["weekly"]) === "automatic", "arrays must fall back to automatic")

        assert(PreferredWindow.keyOrDefault("session") === "session", "valid session key must round-trip")
        assert(PreferredWindow.keyOrDefault("weekly") === "weekly", "valid weekly key must round-trip")
        assert(PreferredWindow.keyOrDefault("monthly") === "monthly", "valid monthly key must round-trip")

        var modelExplicitKeys = Object.keys(UsageModel.preferredWindowKeys)
        var modelKeysWithAutomatic = ["automatic"].concat(modelExplicitKeys)
        assert(modelKeysWithAutomatic.length === PreferredWindow.VALID_KEYS.length,
            "UsageModel.preferredWindowKeys plus automatic must have the same key count as PreferredWindow.VALID_KEYS")
        for (var i = 0; i < PreferredWindow.VALID_KEYS.length; i++) {
            assert(modelKeysWithAutomatic.indexOf(PreferredWindow.VALID_KEYS[i]) !== -1,
                "PreferredWindow.VALID_KEYS entry '" + PreferredWindow.VALID_KEYS[i]
                    + "' must exist in UsageModel.preferredWindowKeys or be 'automatic'")
        }

        var configComponent = Qt.createComponent(Qt.resolvedUrl("../contents/ui/config/configGeneral.qml"))
        assert(configComponent.status === Component.Ready, "configGeneral.qml must load to verify key-list consistency")
        configPage = configComponent.createObject(null, {
            "cfg_codexbarCommandDefault": "",
            "cfg_codexbarCommand": "",
            "cfg_refreshInterval": 60,
            "cfg_requestTimeout": 60,
            "cfg_preferredRepresentativeWindow": "automatic"
        })
        assert(configPage !== null, "configGeneral.qml must instantiate to verify key-list consistency")
        assert(configPage.preferredWindowKeys.length === PreferredWindow.VALID_KEYS.length,
            "configGeneral.qml preferredWindowKeys must have the same length as PreferredWindow.VALID_KEYS")
        for (var j = 0; j < PreferredWindow.VALID_KEYS.length; j++) {
            assert(configPage.preferredWindowKeys[j] === PreferredWindow.VALID_KEYS[j],
                "configGeneral.qml preferredWindowKeys must match PreferredWindow.VALID_KEYS at index " + j)
        }
        configPage.destroy()

        finish()
    }
}
