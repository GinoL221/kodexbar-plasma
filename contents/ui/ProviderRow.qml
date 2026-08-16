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
    property var iconResolver: function(value) { return root.defaultIconSource(value) }
    // Validated CostModel snapshot for the selected provider, or null. Only
    // ever bound for the single selected-detail row; summary/All rows never
    // receive one, so CostSection never renders for them.
    property var costSnapshot: null
    readonly property alias providerDetails: providerDetails
    readonly property alias resetCreditsSection: resetCreditsSection

    readonly property var windows: providerData && providerData.windows instanceof Array
        ? providerData.windows : []
    readonly property var displayedWindows: root.summary
        ? UsageModel.selectOverviewWindows(root.windows) : root.windows
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
    // Selected-provider-only enrichment: pace (attached per matching window
    // label), remaining credit, and the ResetCreditsSection/CostSection data
    // objects are all gated on showHeaderDetails, matching ProviderHeader.
    readonly property var paceByLabel: root.showHeaderDetails
        ? ProviderDetailsLogic.paceSummaryByLabel(root.providerData) : ({})
    readonly property var creditsRemaining: root.showHeaderDetails
        ? ProviderDetailsLogic.validCreditsRemaining(root.providerData) : null

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

    ProviderHeader {
        providerData: root.providerData
        detailed: root.showHeaderDetails
        iconResolver: root.iconResolver
        Layout.fillWidth: true
    }

    PlasmaComponents.Label {
        id: creditsRemainingLabel
        objectName: "creditsRemainingLabel"
        visible: root.creditsRemaining !== null
        text: root.creditsRemaining !== null
            ? Translation.translate("Credits remaining: %1", [root.creditsRemaining], typeof i18n === "function" ? i18n : null)
            : ""
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }

    Repeater {
        model: root.displayedWindows

        delegate: UsageWindowRow {
            required property var modelData
            windowData: modelData
            compact: root.compact
            summary: root.summary
            paceSummary: root.paceByLabel[modelData.label] || ""
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }
    }

    ResetCreditsSection {
        id: resetCreditsSection
        providerData: root.showHeaderDetails ? root.providerData : ({})
        Layout.fillWidth: true
    }

    CostSection {
        snapshot: root.showHeaderDetails ? root.costSnapshot : null
        Layout.fillWidth: true
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
