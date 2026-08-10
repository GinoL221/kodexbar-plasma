import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents

import "../code/UsageModel.js" as UsageModel
import "../code/RefreshInterval.js" as RefreshInterval
import "../code/RequestTimeout.js" as RequestTimeout

PlasmoidItem {
    id: root

    property string codexbarCommand: Plasmoid.configuration.codexbarCommand || "/home/ginopc/.local/bin/codexbar"
    property int refreshSeconds: RefreshInterval.valueOrDefault(Plasmoid.configuration.refreshInterval, 60)
    property int requestTimeoutMs: RequestTimeout.millisecondsOrDefault(Plasmoid.configuration.requestTimeout)
    readonly property var compactSelection: UsageModel.selectCompact(controller.committedProviders)

    preferredRepresentation: compactRepresentation
    toolTipMainText: "KodexBar Plasma"
    toolTipSubText: panelText()

    function panelText() {
        if (compactSelection !== null) {
            return Math.round(compactSelection.usedPercent) + "%"
        }
        return controller.phase === "loading" || controller.phase === "idle"
            ? i18n("Loading") : controller.phase === "error" ? i18n("Error") : i18n("No data")
    }

    UsageController {
        id: controller
        commandPath: root.codexbarCommand
        timeoutMs: root.requestTimeoutMs
    }

    function refresh() {
        controller.requestRefresh()
    }

    compactRepresentation: CompactUsageButton {
        usageText: root.panelText()
        onClicked: root.expanded = !root.expanded
    }

    fullRepresentation: Item {
        id: full
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
                onClicked: controller.requestRefresh()
            }

            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    width: parent.availableWidth
                    spacing: Kirigami.Units.largeSpacing

                    PlasmaComponents.Label {
                        visible: controller.phase === "loading" || controller.phase === "noData" || controller.phase === "error"
                        text: controller.phase === "loading" ? i18n("Loading usage…")
                            : controller.phase === "noData" ? i18n("No usage data available") : controller.errorMessage
                        color: controller.phase === "error" ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.disabledTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: controller.committedProviders

                        delegate: ProviderRow {
                            required property var modelData

                            providerData: modelData
                            Layout.fillWidth: true
                        }
                    }

                    ErrorSummary {
                        errors: controller.committedErrors
                        Layout.fillWidth: true
                    }
                }
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

    onCodexbarCommandChanged: refresh()
}
