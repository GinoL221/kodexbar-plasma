import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.components as PlasmaComponents

import "../../code/PreferredWindow.js" as PreferredWindow
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

    readonly property var preferredWindowKeys: PreferredWindow.VALID_KEYS

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
                    text: i18n("Enter a whole number from 1 to 3600 seconds. Invalid values are restored to the configured default.")
                    color: Kirigami.Theme.disabledTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
