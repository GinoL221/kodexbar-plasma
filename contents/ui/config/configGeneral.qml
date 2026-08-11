import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.components as PlasmaComponents

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
                    textFromValue: function(value) { return i18np("%1 second", "%1 seconds", value) }
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
                        ? i18n("Custom")
                        : i18np("%1 second", "%1 seconds", currentValue)
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
                    textFromValue: function(value) { return i18np("%1 second", "%1 seconds", value) }
                    valueFromText: function(text) { return Number(text.replace(/\D/g, "")) }
                    Accessible.name: i18n("Custom request timeout in seconds")
                    Accessible.description: i18n("Enter a whole number from 30 to 600 seconds. Invalid values use 60 seconds.")
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    onValueChanged: requestTimeoutPreset.currentIndex = page.timeoutPresetIndex(value)
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
                    text: i18n("Enter a whole number from 1 to 3600 seconds. Invalid values are restored to the configured default.")
                    color: Kirigami.Theme.disabledTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
