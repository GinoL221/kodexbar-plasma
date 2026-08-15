pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "../code/ProviderDetails.js" as ProviderDetails

ColumnLayout {
    id: root

    property var providerData: ({})
    property bool expanded: false

    readonly property var acceptedDetails: ProviderDetails.acceptedDetails(root.providerData)
    readonly property alias disclosureButton: disclosure

    visible: root.acceptedDetails.length > 0
    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing
    Accessible.name: translatePlural("%1 provider detail", "%1 provider details", root.acceptedDetails.length)

    function translate(text) {
        return typeof i18n === "function" ? i18n(text) : text
    }

    function translatePlural(singular, plural, count) {
        if (typeof i18np === "function") {
            return i18np(singular, plural, count)
        }
        return (count === 1 ? singular : plural).replace("%1", count)
    }

    QQC2.ToolButton {
        id: disclosure

        checkable: true
        checked: root.expanded
        text: checked
            ? root.translatePlural("Hide %1 detail", "Hide %1 details", root.acceptedDetails.length)
            : root.translatePlural("Show %1 detail", "Show %1 details", root.acceptedDetails.length)
        icon.name: checked ? "arrow-down" : "arrow-right"
        display: QQC2.AbstractButton.TextBesideIcon
        focusPolicy: Qt.StrongFocus
        Accessible.name: text
        Accessible.description: checked
            ? root.translate("Collapse provider details")
            : root.translate("Expand provider details")
        onToggled: root.expanded = checked
        Keys.onReturnPressed: function(event) {
            root.expanded = !root.expanded
            event.accepted = true
        }
        Keys.onSpacePressed: function(event) {
            root.expanded = !root.expanded
            event.accepted = true
        }
    }

    ColumnLayout {
        visible: root.expanded
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        Repeater {
            model: root.acceptedDetails

            delegate: ColumnLayout {
                id: detailDelegate
                required property var modelData

                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: detailDelegate.modelData.title
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }

                Repeater {
                    model: detailDelegate.modelData.rows

                    delegate: ColumnLayout {
                        id: rowDelegate
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 0

                        PlasmaComponents.Label {
                            text: rowDelegate.modelData.label
                            wrapMode: Text.WordWrap
                            textFormat: Text.PlainText
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                        }

                        PlasmaComponents.Label {
                            text: rowDelegate.modelData.value
                            wrapMode: Text.WordWrap
                            textFormat: Text.PlainText
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                        }

                        PlasmaComponents.Label {
                            visible: rowDelegate.modelData.secondaryValue !== undefined && rowDelegate.modelData.secondaryValue !== null
                                     && String(rowDelegate.modelData.secondaryValue).length > 0
                            text: rowDelegate.modelData.secondaryValue
                            color: Kirigami.Theme.disabledTextColor
                            wrapMode: Text.WordWrap
                            textFormat: Text.PlainText
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                        }
                    }
                }
            }
        }
    }
}
