pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "../code/Translation.js" as Translation

// Read-only, pinned popup footer: the controller's current phase/status
// only. No provider/error count, no last-updated timestamp (that is
// already shown by ProviderHeader.updatedAtLabel whenever a provider is
// selected, and by every Overview card otherwise), and no Settings, About,
// Quit, or Add Account control -- this component never exposes an action,
// matching the "Native and accessible UI" and "Provider-focused
// exclusions" requirements.
ColumnLayout {
    id: root

    property string phase: "idle"

    readonly property string statusText: {
        switch (root.phase) {
        case "loading":
            return Translation.translate("Loading", [], typeof i18n === "function" ? i18n : null)
        case "error":
            return Translation.translate("Error", [], typeof i18n === "function" ? i18n : null)
        case "noData":
            return Translation.translate("No data", [], typeof i18n === "function" ? i18n : null)
        case "ready":
            return Translation.translate("Ready", [], typeof i18n === "function" ? i18n : null)
        default:
            return Translation.translate("Idle", [], typeof i18n === "function" ? i18n : null)
        }
    }

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    PlasmaComponents.Label {
        id: footerStatusLabel
        objectName: "footerStatusLabel"
        text: root.statusText
        color: Kirigami.Theme.disabledTextColor
        elide: Text.ElideRight
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }
}
