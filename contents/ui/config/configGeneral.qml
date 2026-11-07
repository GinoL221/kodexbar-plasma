pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.components as PlasmaComponents

import "../../code/PreferredWindow.js" as PreferredWindow
import "../../code/ProviderFilterPolicy.js" as ProviderFilterPolicy
import "../../code/ProviderIcons.js" as ProviderIcons
import "../../code/Translation.js" as Translation

KCM.SimpleKCM {
    id: page

    property alias cfg_codexbarCommand: codexbarCommand.text
    property string cfg_codexbarCommandDefault
    property alias cfg_refreshInterval: refreshInterval.value
    property int cfg_refreshIntervalDefault
    property alias cfg_requestTimeout: requestTimeout.value
    property int cfg_requestTimeoutDefault
    property alias requestTimeoutPresetControl: requestTimeoutPreset
    property alias requestTimeoutCustomControl: requestTimeout
    property alias requestTimeoutGuidance: requestTimeoutGuidanceLabel
    property alias cfg_preferredRepresentativeWindow: preferredWindow.selectedKey
    property string cfg_preferredRepresentativeWindowDefault
    property alias preferredWindowControl: preferredWindow
    property alias preferredWindowGuidance: preferredWindowGuidanceLabel
    property alias cfg_enableQuotaNotifications: enableQuotaNotifications.checked
    property bool cfg_enableQuotaNotificationsDefault
    property alias cfg_tintPanelIcon: tintPanelIcon.checked
    property bool cfg_tintPanelIconDefault: true
    property alias cfg_pinnedProvider: pinnedProviderControl.selectedKey
    property string cfg_pinnedProviderDefault
    property alias cfg_panelDisplayStyle: panelDisplayStyleControl.selectedKey
    property string cfg_panelDisplayStyleDefault: "iconOnly"
    property alias cfg_excludedProviders: excludedProviders.text
    property string cfg_excludedProvidersDefault
    property alias cfg_providerOrder: providerOrder.text
    property string cfg_providerOrderDefault
    property alias cfg_language: languageControl.selectedKey
    property string cfg_languageDefault

    readonly property var preferredWindowKeys: PreferredWindow.VALID_KEYS
    readonly property var defaultOrderCandidates: ["codex", "claude", "antigravity", "grok", "nan"]
    readonly property var orderedProviderIds: ProviderFilterPolicy.effectiveOrderList(
        page.defaultOrderCandidates,
        providerOrder.text
    )

    function moveProvider(providerId, delta) {
        providerOrder.text = ProviderFilterPolicy.moveProviderInOrder(
            page.defaultOrderCandidates,
            providerOrder.text,
            providerId,
            delta
        )
    }

    function preferredWindowIndex(key) {
        var index = page.preferredWindowKeys.indexOf(key)
        return index < 0 ? 0 : index
    }

    function preferredWindowKeyAt(index) {
        return index >= 0 && index < page.preferredWindowKeys.length
            ? page.preferredWindowKeys[index] : "automatic"
    }

    function timeoutPresetIndex(value) {
        return value === 60 ? 0 : value === 120 ? 1 : value === 180 ? 2 : 3
    }

    Item {
        implicitWidth: content.implicitWidth + Kirigami.Units.largeSpacing * 2
        implicitHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading {
                    text: i18n("CodexBar CLI")
                    level: 3
                    Layout.fillWidth: true
                }

                PlasmaComponents.Label {
                    text: i18n("The widget only runs the configured CodexBar CLI path for all-provider usage data.")
                    color: Kirigami.Theme.disabledTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            Kirigami.FormLayout {
                Layout.fillWidth: true

                QQC2.TextField {
                    id: codexbarCommand
                    objectName: "codexbarCommand"
                    Kirigami.FormData.label: i18n("CLI path:")
                    placeholderText: i18n("Leave empty to try automatic discovery")
                    Accessible.name: i18n("Absolute CodexBar CLI path")
                    Accessible.description: i18n("Leave this empty to try approved locations automatically, or enter an absolute executable path.")
                    validator: RegularExpressionValidator {
                        regularExpression: /\/[^\r\n]*/
                    }
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 24
                    onEditingFinished: {
                        if (text.length > 0 && !acceptableInput) {
                            text = page.cfg_codexbarCommandDefault
                        }
                    }
                }

                QQC2.SpinBox {
                    id: refreshInterval
                    Kirigami.FormData.label: i18n("Refresh interval:")
                    from: 1
                    to: 3600
                    stepSize: 1
                    textFromValue: function(value) {
                        return Translation.plural("%1 second", "%1 seconds", value,
                            typeof i18np === "function" ? i18np : null)
                    }
                    valueFromText: function(text) { return Number(text.replace(/\D/g, "")) }
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                }

                QQC2.ComboBox {
                    id: requestTimeoutPreset
                    Kirigami.FormData.label: i18n("Request timeout:")
                    model: [60, 120, 180, -1]
                    textRole: ""
                    Accessible.name: i18n("Request timeout preset")
                    displayText: currentIndex === 3
                        ? Translation.translate("Custom", [], typeof i18n === "function" ? i18n : null)
                        : Translation.plural("%1 second", "%1 seconds", currentValue,
                            typeof i18np === "function" ? i18np : null)
                    onActivated: {
                        if (currentIndex < 3) {
                            requestTimeout.value = currentValue
                        } else {
                            requestTimeout.forceActiveFocus()
                        }
                    }
                    Component.onCompleted: currentIndex = page.timeoutPresetIndex(requestTimeout.value || 60)
                }

                QQC2.SpinBox {
                    id: requestTimeout
                    from: 30
                    to: 600
                    stepSize: 1
                    value: 60
                    textFromValue: function(value) {
                        return Translation.plural("%1 second", "%1 seconds", value,
                            typeof i18np === "function" ? i18np : null)
                    }
                    valueFromText: function(text) { return Number(text.replace(/\D/g, "")) }
                    Accessible.name: i18n("Custom request timeout in seconds")
                    Accessible.description: i18n("Enter a whole number from 30 to 600 seconds. Invalid values use 60 seconds.")
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    onValueChanged: requestTimeoutPreset.currentIndex = page.timeoutPresetIndex(value)
                }

                QQC2.ComboBox {
                    id: preferredWindow
                    objectName: "preferredRepresentativeWindow"
                    property string selectedKey: "automatic"
                    Kirigami.FormData.label: i18n("Representative window:")
                    model: [
                        Translation.translate("Automatic", [], typeof i18n === "function" ? i18n : null),
                        Translation.translate("Session", [], typeof i18n === "function" ? i18n : null),
                        Translation.translate("Weekly", [], typeof i18n === "function" ? i18n : null),
                        Translation.translate("Monthly", [], typeof i18n === "function" ? i18n : null)
                    ]
                    Accessible.name: i18n("Preferred representative window")
                    Accessible.description: i18n("Choose which usage window every provider summary shows in All. Automatic uses Session, then Weekly, then Monthly.")
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    onActivated: selectedKey = page.preferredWindowKeyAt(currentIndex)
                    onSelectedKeyChanged: currentIndex = page.preferredWindowIndex(selectedKey)
                    Component.onCompleted: currentIndex = page.preferredWindowIndex(selectedKey)
                }

                QQC2.CheckBox {
                    id: enableQuotaNotifications
                    objectName: "enableQuotaNotifications"
                    Kirigami.FormData.label: i18n("Notifications:")
                    text: i18n("Notify when quota reaches 90% or rate limit triggers")
                    Accessible.name: i18n("Enable quota notifications")
                    Accessible.description: i18n("Show native Plasma notifications when provider usage reaches critical (90%) or exhausted (100%) levels, or when rate limits trigger backoff.")
                }

                QQC2.CheckBox {
                    id: tintPanelIcon
                    objectName: "tintPanelIcon"
                    checked: true
                    Kirigami.FormData.label: i18n("Panel icon:")
                    text: i18n("Colorize panel icon with provider accent")
                    Accessible.name: i18n("Colorize panel icon with provider accent")
                    Accessible.description: i18n("When cycling providers from the panel, tint the icon with the provider's brand color instead of monochrome text color.")
                }

                QQC2.ComboBox {
                    id: pinnedProviderControl
                    objectName: "pinnedProviderControl"
                    property string selectedKey: ""
                    Kirigami.FormData.label: Translation.translate("Pinned provider:", [], typeof i18n === "function" ? i18n : null)
                    model: [
                        Translation.translate("All providers (free cycle)", [], typeof i18n === "function" ? i18n : null),
                        "Codex",
                        "Claude",
                        "Antigravity",
                        "Grok",
                        "NaN Cloud"
                    ]
                    readonly property var keyValues: ["", "codex", "claude", "antigravity", "grok", "nan"]
                    Accessible.name: i18n("Pinned provider")
                    Accessible.description: i18n("Pin this widget instance to a single provider, or allow cycling across all providers.")
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                    onActivated: {
                        selectedKey = keyValues[currentIndex] !== undefined ? keyValues[currentIndex] : ""
                    }
                    onSelectedKeyChanged: {
                        var idx = keyValues.indexOf(selectedKey)
                        currentIndex = idx >= 0 ? idx : 0
                    }
                    Component.onCompleted: {
                        var idx = keyValues.indexOf(selectedKey)
                        currentIndex = idx >= 0 ? idx : 0
                    }
                }

                QQC2.ComboBox {
                    id: panelDisplayStyleControl
                    objectName: "panelDisplayStyleControl"
                    property string selectedKey: "iconOnly"
                    Kirigami.FormData.label: Translation.translate("Panel display:", [], typeof i18n === "function" ? i18n : null)
                    model: [
                        Translation.translate("Icon only", [], typeof i18n === "function" ? i18n : null),
                        Translation.translate("Icon and percentage", [], typeof i18n === "function" ? i18n : null),
                        Translation.translate("Icon, name, and percentage", [], typeof i18n === "function" ? i18n : null)
                    ]
                    readonly property var styleKeys: ["iconOnly", "iconAndPercent", "iconNameAndPercent"]
                    Accessible.name: i18n("Panel display style")
                    Accessible.description: i18n("Choose whether the panel button displays only the icon, the icon with percentage, or the icon with provider name and percentage.")
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                    onActivated: {
                        selectedKey = styleKeys[currentIndex] !== undefined ? styleKeys[currentIndex] : "iconOnly"
                    }
                    onSelectedKeyChanged: {
                        var idx = styleKeys.indexOf(selectedKey)
                        currentIndex = idx >= 0 ? idx : 0
                    }
                    Component.onCompleted: {
                        var idx = styleKeys.indexOf(selectedKey)
                        currentIndex = idx >= 0 ? idx : 0
                    }
                }

                QQC2.TextField {
                    id: excludedProviders
                    objectName: "excludedProviders"
                    Kirigami.FormData.label: i18n("Hide providers:")
                    placeholderText: i18n("e.g. grok, synthetic (comma-separated)")
                    Accessible.name: i18n("Excluded provider IDs")
                    Accessible.description: i18n("Comma-separated list of provider IDs to hide from the panel summary and popup list.")
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 24
                }

                ColumnLayout {
                    Kirigami.FormData.label: i18n("Provider order:")
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 24
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: page.orderedProviderIds

                        delegate: RowLayout {
                            id: orderRow
                            required property string modelData
                            required property int index

                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            PlasmaComponents.Label {
                                text: (orderRow.index + 1) + ". " + ProviderIcons.displayName(orderRow.modelData)
                                Layout.fillWidth: true
                            }

                            QQC2.ToolButton {
                                icon.name: "go-up"
                                display: QQC2.AbstractButton.IconOnly
                                enabled: orderRow.index > 0
                                Accessible.name: qsTr("Move up")
                                onClicked: page.moveProvider(orderRow.modelData, -1)
                            }

                            QQC2.ToolButton {
                                icon.name: "go-down"
                                display: QQC2.AbstractButton.IconOnly
                                enabled: orderRow.index < page.orderedProviderIds.length - 1
                                Accessible.name: qsTr("Move down")
                                onClicked: page.moveProvider(orderRow.modelData, 1)
                            }
                        }
                    }

                    QQC2.TextField {
                        id: providerOrder
                        objectName: "providerOrder"
                        placeholderText: i18n("e.g. codex, claude, antigravity, grok, nan")
                        Accessible.name: i18n("Provider order IDs")
                        Accessible.description: i18n("Comma-separated list of provider IDs in your preferred display order, or use the up and down buttons above.")
                        Layout.fillWidth: true
                    }
                }

                QQC2.ComboBox {
                    id: languageControl
                    objectName: "languageControl"
                    property string selectedKey: "auto"
                    Kirigami.FormData.label: i18n("Language / Idioma:")
                    model: [
                        i18n("Automatic (system / sistema)"),
                        "Español",
                        "English"
                    ]
                    Accessible.name: i18n("Interface language")
                    Accessible.description: i18n("Select interface language: Automatic, Español, or English.")
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                    onActivated: {
                        selectedKey = currentIndex === 1 ? "es" : currentIndex === 2 ? "en" : "auto"
                    }
                    onSelectedKeyChanged: {
                        currentIndex = selectedKey === "es" ? 1 : selectedKey === "en" ? 2 : 0
                    }
                    Component.onCompleted: {
                        currentIndex = selectedKey === "es" ? 1 : selectedKey === "en" ? 2 : 0
                    }
                }

                PlasmaComponents.Label {
                    id: codexbarSetupGuidance
                    objectName: "codexbarSetupGuidance"
                    text: i18n("Leave the path empty to try approved locations automatically. To configure manually, install CodexBar, run 'command -v codexbar' in a terminal, and save its absolute executable path here. Credentials and any OpenCode Go prerequisite remain external setup.")
                    color: Kirigami.Theme.disabledTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Accessible.name: qsTr("CodexBar setup guidance")
                    Accessible.description: text
                }

                PlasmaComponents.Label {
                    id: requestTimeoutGuidanceLabel
                    objectName: "requestTimeoutGuidance"
                    text: i18n("Choose 60, 120, or 180 seconds, or Custom from 30 to 600 seconds. Invalid values use 60 seconds. Request timeout does not change refresh interval.")
                    color: Kirigami.Theme.disabledTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Accessible.name: i18n("Request timeout guidance")
                }

                PlasmaComponents.Label {
                    id: preferredWindowGuidanceLabel
                    objectName: "preferredWindowGuidance"
                    text: i18n("Every provider summary in All shows this usage window. Automatic picks the first available of Session, Weekly, then Monthly. A provider without the chosen window falls back to that automatic order. The panel badge is unaffected.")
                    color: Kirigami.Theme.disabledTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Accessible.name: qsTr("Representative window guidance")
                }

                PlasmaComponents.Label {
                    id: notificationsGuidanceLabel
                    objectName: "notificationsGuidance"
                    text: i18n("Dispatches native system notifications when any provider crosses 90% or 100% quota thresholds, or when queries are paused due to rate limits.")
                    color: Kirigami.Theme.disabledTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Accessible.name: i18n("Notifications guidance")
                }

                PlasmaComponents.Label {
                    id: excludedProvidersGuidanceLabel
                    objectName: "excludedProvidersGuidance"
                    text: i18n("Enter provider IDs separated by commas to hide them from the compact panel icon and popup list. Leave empty to show all providers.")
                    color: Kirigami.Theme.disabledTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Accessible.name: i18n("Excluded providers guidance")
                }

                PlasmaComponents.Label {
                    text: i18n("Enter a whole number from 1 to 3600 seconds. Invalid values are restored to the configured default.")
                    color: Kirigami.Theme.disabledTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
