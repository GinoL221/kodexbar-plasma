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
    //
    // Selection state is read by the caller and passed in: the
    // ProviderSelector instance lives inside fullRepresentation's implicit
    // Component, a separate QML id scope root cannot alias into.
    function maybeRequestCost(isAllSelected, selected) {
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
        // Outer chrome margin + extra body inset so provider cards sit off the
        // popup edge like the reference (Kirigami.Units only).
        readonly property int popupMargin: Kirigami.Units.largeSpacing * 2
        readonly property int bodyInset: Kirigami.Units.smallSpacing
        // Cap only — preferred height follows content so the popup is not a
        // fixed tall empty slab. Scroll kicks in once content hits the cap.
        readonly property int maxPopupHeight: Kirigami.Units.gridUnit * 44
        readonly property int minPopupHeight: Kirigami.Units.gridUnit * 16
        readonly property int contentPreferredHeight: {
            var body = usageColumn.implicitHeight
            var chrome = refreshButton.implicitHeight + statusFooter.implicitHeight
                + mainColumn.spacing * 2
            return body + chrome + full.popupMargin * 2
        }

        Layout.minimumWidth: Kirigami.Units.gridUnit * 30
        Layout.minimumHeight: full.minPopupHeight
        Layout.preferredWidth: Kirigami.Units.gridUnit * 34
        Layout.preferredHeight: Math.max(full.minPopupHeight,
            Math.min(full.contentPreferredHeight, full.maxPopupHeight))
        Layout.maximumHeight: full.maxPopupHeight

        ColumnLayout {
            id: mainColumn
            anchors.fill: parent
            anchors.margins: full.popupMargin
            spacing: Kirigami.Units.largeSpacing

            QQC2.ScrollView {
                id: usageScrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                // Overlay scrollbar: no reserved grey gutter; fades with AsNeeded.
                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    parent: usageScrollView
                    x: usageScrollView.mirrored ? 0 : usageScrollView.width - width
                    y: usageScrollView.topPadding
                    height: usageScrollView.availableHeight
                    policy: QQC2.ScrollBar.AsNeeded
                }

                ColumnLayout {
                    id: usageColumn
                    width: full.scrollView.availableWidth
                    spacing: Kirigami.Units.largeSpacing

                     // Loading stays in the pinned footer so it never grows the
                     // scroll body. Body only surfaces terminal empty/error copy.
                     PlasmaComponents.Label {
                        visible: root.controller.phase === "noData" || root.controller.phase === "error"
                        text: root.controller.phase === "noData"
                            ? i18n("No usage data available")
                            : root.controller.errorMessage
                        color: root.controller.phase === "error"
                            ? Kirigami.Theme.negativeTextColor
                            : Kirigami.Theme.disabledTextColor
                        wrapMode: Text.WordWrap
                         Layout.fillWidth: true
                         Layout.leftMargin: full.bodyInset
                         Layout.rightMargin: full.bodyInset
                     }

                    ProviderSelector {
                        id: providerSelector
                        providers: root.controller.committedProviders
                        phase: root.controller.phase
                        popupOpen: root.expanded
                        preferredWindowKey: root.preferredWindowKey
                        Layout.fillWidth: true
                        Layout.leftMargin: full.bodyInset
                        Layout.rightMargin: full.bodyInset
                        onSelectedProviderChanged: root.maybeRequestCost(providerSelector.allSelected, providerSelector.selectedProvider)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: full.bodyInset
                        Layout.rightMargin: full.bodyInset
                        spacing: Kirigami.Units.largeSpacing

                        Kirigami.Separator {
                            objectName: "overviewProviderListSeparator"
                            visible: providerSelector.allSelected
                            Layout.fillWidth: true
                        }

                        Repeater {
                            model: providerSelector.allSelected ? providerSelector.usableProviders : []

                            delegate: ProviderRow {
                                required property var modelData

                                providerData: modelData
                                summary: true
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
                    }

                    // Provider failures stay in the controller for tests/debug
                    // but are never shown in the popup (CLI returns dozens of
                    // unsupported providers on Linux — pure noise for users).
                }
            }

            // Chrome below the scroll body: Refresh (text+icon), then status.
            // Settings/About stay deferred — not part of this change.
            QQC2.ToolButton {
                id: refreshButton
                icon.name: "view-refresh"
                display: QQC2.AbstractButton.TextBesideIcon
                text: i18n("Refresh")
                Layout.alignment: Qt.AlignLeft
                onClicked: root.controller.requestRefresh()
            }

            StatusFooter {
                id: statusFooter
                phase: root.controller.phase
                Layout.fillWidth: true
            }
        }

        Connections {
            target: root.controller
            function onCommittedGenerationChanged() {
                root.maybeRequestCost(providerSelector.allSelected, providerSelector.selectedProvider)
            }
        }
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
