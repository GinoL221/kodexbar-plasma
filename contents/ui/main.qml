pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents

import "../code/UsageModel.js" as UsageModel
import "../code/RefreshInterval.js" as RefreshInterval
import "../code/RequestTimeout.js" as RequestTimeout
import "../code/PreferredWindow.js" as PreferredWindow
import "../code/CostRequestPolicy.js" as CostRequestPolicy

PlasmoidItem {
    id: root

    property string codexbarCommand: Plasmoid.configuration.codexbarCommand || ""
    property bool suppressNextCommandRefresh: false
    property int refreshSeconds: RefreshInterval.valueOrDefault(Plasmoid.configuration.refreshInterval, 60)
    property int requestTimeoutMs: RequestTimeout.millisecondsOrDefault(Plasmoid.configuration.requestTimeout)
    property string preferredWindowKey: PreferredWindow.keyOrDefault(Plasmoid.configuration.preferredRepresentativeWindow)
    property alias controller: controller
    property alias providerSelector: providerSelector
    readonly property var compactSelection: UsageModel.selectCompact(root.controller.committedProviders)

    preferredRepresentation: compactRepresentation
    toolTipMainText: "KodexBar Plasma"
    toolTipSubText: root.panelText()

    function panelText() {
        if (compactSelection !== null) {
            return Math.round(compactSelection.usedPercent) + "%"
        }
        return root.controller.phase === "loading" || root.controller.phase === "idle"
            ? i18n("Loading") : root.controller.phase === "error" ? i18n("Error") : i18n("No data")
    }

    UsageController {
        id: controller
        commandPath: root.codexbarCommand
        timeoutMs: root.requestTimeoutMs
        onPathDiscovered: function(path) {
            if (root.codexbarCommand === path) {
                return
            }
            root.suppressNextCommandRefresh = true
            Plasmoid.configuration.codexbarCommand = path
        }
    }

    // Isolated, optional cost lifecycle -- never touched while "All" is
    // selected, and never able to affect usage state (see CostController.qml).
    CostController {
        id: costController
        commandPath: root.codexbarCommand
    }

    // Requests cost only for a supported selected provider missing its
    // current-generation snapshot; "All" and unsupported providers never
    // start cost work or read a cost record (CostRequestPolicy.js).
    function maybeRequestCost() {
        var isAllSelected = root.providerSelector.allSelected
        var selected = root.providerSelector.selectedProvider
        var provider = selected ? selected.provider : null
        var usageGeneration = root.controller.committedGeneration
        var hasSnapshot = typeof provider === "string" && costController.snapshotFor(provider, usageGeneration) !== null
        if (CostRequestPolicy.shouldRequestCost(isAllSelected, provider, usageGeneration, hasSnapshot)) {
            costController.request(provider, usageGeneration)
        }
    }

    Plasmoid.configurationRequired: root.controller.configurationRequired

    function refresh() {
        root.controller.requestRefresh()
    }

    compactRepresentation: CompactUsageButton {
        usageText: root.panelText()
        onClicked: root.expanded = !root.expanded
    }

    fullRepresentation: Item {
        id: full
        property alias scrollView: usageScrollView
        readonly property int popupMargin: Kirigami.Units.largeSpacing * 2
        readonly property int maxPopupHeight: Kirigami.Units.gridUnit * 44

        Layout.minimumWidth: Kirigami.Units.gridUnit * 30
        Layout.minimumHeight: Math.min(Layout.preferredHeight, maxPopupHeight)
        Layout.preferredWidth: Kirigami.Units.gridUnit * 34
        Layout.preferredHeight: maxPopupHeight

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: full.popupMargin
            spacing: Kirigami.Units.largeSpacing

            QQC2.ToolButton {
                icon.name: "view-refresh"
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Refresh")
                onClicked: root.controller.requestRefresh()
            }

            QQC2.ScrollView {
                id: usageScrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
                QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AsNeeded

                ColumnLayout {
                    width: full.scrollView.availableWidth
                    spacing: Kirigami.Units.largeSpacing

                     PlasmaComponents.Label {
                        visible: root.controller.phase === "loading" || root.controller.phase === "noData" || root.controller.phase === "error"
                        text: root.controller.phase === "loading" ? i18n("Loading usage…")
                            : root.controller.phase === "noData" ? i18n("No usage data available") : root.controller.errorMessage
                        color: root.controller.phase === "error" ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.disabledTextColor
                        wrapMode: Text.WordWrap
                         Layout.fillWidth: true
                     }

                    ProviderSelector {
                        id: providerSelector
                        providers: root.controller.committedProviders
                        phase: root.controller.phase
                        popupOpen: root.expanded
                        Layout.fillWidth: true
                        onSelectedProviderChanged: root.maybeRequestCost()
                    }

                    Repeater {
                        model: providerSelector.allSelected ? providerSelector.usableProviders : []

                        delegate: ProviderRow {
                            required property var modelData

                            providerData: modelData
                            summary: true
                            preferredWindowKey: root.preferredWindowKey
                            iconResolver: providerSelector.iconResolver
                            Layout.fillWidth: true
                        }
                    }

                    ProviderRow {
                        visible: !providerSelector.allSelected && providerSelector.selectedProvider !== null
                        providerData: providerSelector.selectedProvider || ({})
                        compact: false
                        iconResolver: providerSelector.iconResolver
                        // "All" is never bound here: selectedProvider is null
                        // whenever allSelected, so no cost record is ever read.
                        costSnapshot: providerSelector.selectedProvider
                            ? costController.snapshotFor(providerSelector.selectedProvider.provider, root.controller.committedGeneration)
                            : null
                        Layout.fillWidth: true
                    }

                    ErrorSummary {
                        errors: root.controller.committedErrors
                        Layout.fillWidth: true
                    }
                }
            }
        }

    }

    Connections {
        target: root.controller
        function onCommittedGenerationChanged() { root.maybeRequestCost() }
    }

    Timer {
        id: refreshTimer
        interval: root.refreshSeconds * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    onRefreshSecondsChanged: {
        refreshTimer.restart()
        refresh()
    }

    onCodexbarCommandChanged: {
        if (suppressNextCommandRefresh) {
            suppressNextCommandRefresh = false
            return
        }
        refresh()
    }
}
