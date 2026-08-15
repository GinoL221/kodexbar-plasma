pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "../code/UsageModel.js" as UsageModel
import "../code/ProviderIcons.js" as ProviderIcons
import "../code/ProviderDetails.js" as ProviderDetailsLogic
import "../code/Translation.js" as Translation

ColumnLayout {
    id: root

    property var providerData: ({})
    property bool compact: false
    property bool summary: false
    property string preferredWindowKey: "automatic"
    property var iconResolver: function(value) { return root.defaultIconSource(value) }
    readonly property alias providerDetails: providerDetails

    readonly property var windows: providerData && providerData.windows instanceof Array
        ? providerData.windows : []
    readonly property var representativeWindow: root.summary
        ? UsageModel.selectRepresentative(root.windows, root.preferredWindowKey) : null
    readonly property var displayedWindows: root.summary && root.representativeWindow !== null
        ? [root.representativeWindow] : root.summary ? [] : root.windows
    readonly property string providerValue: providerData && providerData.provider !== null
        && providerData.provider !== undefined ? String(providerData.provider) : ""
    readonly property string sourceValue: providerData && providerData.source !== null
        && providerData.source !== undefined ? String(providerData.source) : ""
    readonly property string providerText: providerValue.length > 0
        ? providerValue : Translation.translate("Provider", [], typeof i18n === "function" ? i18n : null)
    readonly property string accessibleState: root.displayedWindows.length > 0
        ? Translation.plural("%1 available usage window", "%1 available usage windows", root.displayedWindows.length,
            typeof i18np === "function" ? i18np : null)
        : Translation.translate("No usage windows available", [], typeof i18n === "function" ? i18n : null)
    readonly property bool showHeaderDetails: !root.compact && !root.summary
    readonly property string headerVersion: root.showHeaderDetails
        ? ProviderDetailsLogic.validVersion(root.providerData) : ""
    readonly property string headerLogin: root.showHeaderDetails
        ? ProviderDetailsLogic.validLoginMethod(root.providerData) : ""

    function iconSource(value) {
        return root.iconResolver(value)
    }

    function defaultIconSource(value) {
        var key = ProviderIcons.key(value)
        return key.length > 0
            ? Qt.resolvedUrl("../icons/providers/" + key + ".svg") : "dialog-information"
    }

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing
    Accessible.name: Translation.translate("%1 provider, %2", [providerText, accessibleState],
        typeof i18n === "function" ? i18n : null)
    Accessible.description: sourceValue.length > 0
        ? Translation.translate("Source: %1", [sourceValue], typeof i18n === "function" ? i18n : null) : accessibleState

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: root.iconSource(root.providerValue)
            isMask: true
            color: Kirigami.Theme.textColor
            implicitWidth: Kirigami.Units.iconSizes.smallMedium
            implicitHeight: Kirigami.Units.iconSizes.smallMedium
            Layout.alignment: Qt.AlignTop
            Accessible.name: Translation.translate("%1 provider icon", [root.providerText],
                typeof i18n === "function" ? i18n : null)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                id: providerLabel
                objectName: "providerLabel"
                text: root.providerText
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                id: sourceLabel
                objectName: "sourceLabel"
                visible: root.sourceValue.length > 0
                text: root.sourceValue
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                id: versionLabel
                objectName: "versionLabel"
                visible: root.headerVersion.length > 0
                text: root.headerVersion
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                id: loginLabel
                objectName: "loginLabel"
                visible: root.headerLogin.length > 0
                text: root.headerLogin
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    Repeater {
        model: root.displayedWindows

        delegate: UsageWindowRow {
            required property var modelData
            windowData: modelData
            compact: root.compact
            summary: root.summary
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }
    }

    ProviderDetails {
        id: providerDetails
        visible: root.showHeaderDetails && acceptedDetails.length > 0
        providerData: root.providerData
        Layout.fillWidth: true
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }
}
