pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "../code/ProviderDetails.mjs" as ProviderDetailsLogic
import "../code/ProviderIcons.mjs" as ProviderIcons
import "../code/RelativeTime.mjs" as RelativeTime
import "../code/Translation.mjs" as Translation

// Detail header hierarchy (reference IA): name + updated left, plan/login
// + email right. Version/org stay off the primary chrome (noise/PII);
// objectNames remain for harness discovery with visible:false.
RowLayout {
    id: root

    property var providerData: ({})
    property bool detailed: false
    property bool canSwitchAccount: false
    property bool switchBusy: false
    property string languagePreference: "en"
    property var iconResolver: function(value) { return "dialog-information" }
    property real nowMs: Date.now()

    signal accountSwitchRequested()

    readonly property string providerValue: providerData && providerData.provider !== null
        && providerData.provider !== undefined ? String(providerData.provider) : ""
    readonly property string sourceValue: providerData && providerData.source !== null
        && providerData.source !== undefined ? String(providerData.source) : ""
    readonly property string providerText: providerValue.length > 0
        ? ProviderIcons.displayName(providerValue)
        : Translation.translate("Provider", [], typeof i18n === "function" ? i18n : null, root.languagePreference)
    readonly property string headerVersion: ProviderDetailsLogic.validVersion(root.providerData)
    readonly property string headerLogin: ProviderDetailsLogic.validLoginMethod(root.providerData)
    readonly property string headerEmail: root.detailed ? ProviderDetailsLogic.validEmail(root.providerData) : ""
    readonly property string headerOrganization: root.detailed ? ProviderDetailsLogic.validOrganization(root.providerData) : ""
    readonly property string headerUpdatedAt: root.detailed ? ProviderDetailsLogic.validUpdatedAt(root.providerData) : ""
    readonly property var headerStatus: root.detailed ? ProviderDetailsLogic.validStatus(root.providerData) : null
    readonly property bool headerStatusIsSevere: root.headerStatus !== null
        && (root.headerStatus.indicator === "major" || root.headerStatus.indicator === "critical")
    // A present-but-unparseable updatedAt (validUpdatedAt only checks
    // non-empty, not ISO validity) must stay omitted rather than leak the
    // raw CLI string -- never invent or expose an unformatted timestamp.
    readonly property string headerUpdatedAtDisplay: root.headerUpdatedAt.length > 0
        ? RelativeTime.formatUpdatedLabel(
            root.headerUpdatedAt,
            root.nowMs,
            function(template, args) {
                return Translation.translate(template, args, typeof i18n === "function" ? i18n : null, root.languagePreference)
            })
        : ""

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    ProviderIcon {
        objectName: "providerHeaderIcon"
        // Overview cards keep the mark next to the name. Detail body omits
        // it — the selected tab already shows the provider icon.
        visible: !root.detailed
        source: root.iconResolver(root.providerValue)
        color: Kirigami.Theme.textColor
        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium
        Layout.alignment: Qt.AlignVCenter
        Accessible.name: Translation.translate("%1 provider icon", [root.providerText],
            typeof i18n === "function" ? i18n : null, root.languagePreference)
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.max(1, Math.round(Kirigami.Units.smallSpacing / 3))

        PlasmaComponents.Label {
            id: providerLabel
            objectName: "providerLabel"
            text: root.providerText
            font.weight: root.detailed ? Font.Bold : Font.DemiBold
            font.pointSize: root.detailed
                ? Math.round(Kirigami.Theme.defaultFont.pointSize * 1.3)
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
            visible: root.headerUpdatedAtDisplay.length > 0
            text: visible ? root.headerUpdatedAtDisplay : ""
            color: Kirigami.Theme.disabledTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.weight: Font.Normal
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        PlasmaComponents.Label {
            id: statusIncidentLabel
            objectName: "statusIncidentLabel"
            visible: root.headerStatus !== null
            text: visible
                ? Translation.translate(root.headerStatus.description, [], typeof i18n === "function" ? i18n : null, root.languagePreference)
                : ""
            textFormat: Text.PlainText
            color: root.headerStatusIsSevere ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.neutralTextColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.weight: Font.Medium
            elide: Text.ElideRight
            Layout.fillWidth: true
            Accessible.name: text
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignTop | Qt.AlignRight
        visible: root.detailed && (root.headerLogin.length > 0 || root.headerEmail.length > 0 || root.canSwitchAccount)
        spacing: Math.max(1, Math.round(Kirigami.Units.smallSpacing / 3))

        PlasmaComponents.Label {
            id: loginLabel
            objectName: "loginLabel"
            visible: root.detailed && root.headerLogin.length > 0
            text: root.headerLogin
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignRight
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            visible: root.detailed && (root.headerEmail.length > 0 || root.canSwitchAccount)
            spacing: Math.max(2, Math.round(Kirigami.Units.smallSpacing / 2))

            PlasmaComponents.Label {
                id: emailLabel
                objectName: "emailLabel"
                visible: root.detailed && root.headerEmail.length > 0
                text: root.headerEmail
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            }

            QQC2.ToolButton {
                id: switchAccountButton
                objectName: "switchAccountButton"
                visible: root.detailed && root.canSwitchAccount
                enabled: !root.switchBusy
                icon.name: "system-switch-user"
                display: QQC2.AbstractButton.IconOnly
                flat: true
                implicitWidth: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing
                implicitHeight: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: 250
                QQC2.ToolTip.text: Translation.translate(
                    root.switchBusy ? "Switching Antigravity account…" : "Switch Antigravity account",
                    [],
                    typeof i18n === "function" ? i18n : null,
                    root.languagePreference
                )
                Accessible.name: Translation.translate(
                    "Switch Antigravity account",
                    [],
                    typeof i18n === "function" ? i18n : null,
                    root.languagePreference
                )
                Layout.alignment: Qt.AlignVCenter
                onClicked: root.accountSwitchRequested()
            }
        }
    }

    Timer {
        id: updatedRefreshTimer
        interval: 60000
        repeat: true
        running: root.visible && root.headerUpdatedAt.length > 0
        onTriggered: root.nowMs = Date.now()
    }
}
