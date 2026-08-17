pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "../code/ProviderDetails.js" as ProviderDetailsLogic
import "../code/ProviderIcons.js" as ProviderIcons
import "../code/Translation.js" as Translation

// Detail header hierarchy (reference IA): name + updated left, plan/login
// badge right. Version/email/org stay off the primary chrome (noise/PII);
// objectNames remain for harness discovery with visible:false.
RowLayout {
    id: root

    property var providerData: ({})
    property bool detailed: false
    property var iconResolver: function(value) { return "dialog-information" }

    readonly property string providerValue: providerData && providerData.provider !== null
        && providerData.provider !== undefined ? String(providerData.provider) : ""
    readonly property string sourceValue: providerData && providerData.source !== null
        && providerData.source !== undefined ? String(providerData.source) : ""
    readonly property string providerText: providerValue.length > 0
        ? ProviderIcons.displayName(providerValue)
        : Translation.translate("Provider", [], typeof i18n === "function" ? i18n : null)
    readonly property string headerVersion: ProviderDetailsLogic.validVersion(root.providerData)
    readonly property string headerLogin: ProviderDetailsLogic.validLoginMethod(root.providerData)
    readonly property string headerEmail: root.detailed ? ProviderDetailsLogic.validEmail(root.providerData) : ""
    readonly property string headerOrganization: root.detailed ? ProviderDetailsLogic.validOrganization(root.providerData) : ""
    readonly property string headerUpdatedAt: root.detailed ? ProviderDetailsLogic.validUpdatedAt(root.providerData) : ""

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    Kirigami.Icon {
        // Overview cards keep the mark next to the name. Detail body omits
        // it — the selected tab already shows the provider icon.
        visible: !root.detailed
        source: root.iconResolver(root.providerValue)
        isMask: true
        color: Kirigami.Theme.textColor
        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium
        Layout.alignment: Qt.AlignVCenter
        Accessible.name: Translation.translate("%1 provider icon", [root.providerText],
            typeof i18n === "function" ? i18n : null)
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.max(1, Math.round(Kirigami.Units.smallSpacing / 3))

        PlasmaComponents.Label {
            id: providerLabel
            objectName: "providerLabel"
            text: root.providerText
            font.weight: Font.Bold
            font.pointSize: root.detailed
                ? Kirigami.Theme.defaultFont.pointSize * 1.25
                : Kirigami.Theme.defaultFont.pointSize
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        PlasmaComponents.Label {
            id: sourceLabel
            objectName: "sourceLabel"
            visible: false
            text: root.sourceValue
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // Hidden from primary chrome — keep nodes for harness objectName lookup.
        PlasmaComponents.Label {
            id: versionLabel
            objectName: "versionLabel"
            visible: false
            text: root.headerVersion
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        PlasmaComponents.Label {
            id: emailLabel
            objectName: "emailLabel"
            visible: false
            text: root.headerEmail
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        PlasmaComponents.Label {
            id: organizationLabel
            objectName: "organizationLabel"
            visible: false
            text: root.headerOrganization
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        PlasmaComponents.Label {
            id: updatedAtLabel
            objectName: "updatedAtLabel"
            visible: root.headerUpdatedAt.length > 0
            text: visible ? Translation.translate("Updated: %1", [root.headerUpdatedAt], typeof i18n === "function" ? i18n : null) : ""
            color: Kirigami.Theme.disabledTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignTop | Qt.AlignRight
        visible: root.detailed && root.headerLogin.length > 0
        spacing: 0

        PlasmaComponents.Label {
            id: loginLabel
            objectName: "loginLabel"
            visible: root.detailed && root.headerLogin.length > 0
            text: root.headerLogin
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
        }
    }
}
