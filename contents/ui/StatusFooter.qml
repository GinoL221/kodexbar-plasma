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
    property bool showSeparator: true
    property string languagePreference: "en"

    readonly property string statusText: {
        switch (root.phase) {
        case "loading":
            return Translation.translate("Loading usage…", [], typeof i18n === "function" ? i18n : null, root.languagePreference)
        case "error":
            return Translation.translate("Error", [], typeof i18n === "function" ? i18n : null, root.languagePreference)
        case "noData":
            return Translation.translate("No data", [], typeof i18n === "function" ? i18n : null, root.languagePreference)
        case "ready":
            return Translation.translate("Ready", [], typeof i18n === "function" ? i18n : null, root.languagePreference)
        default:
            return Translation.translate("Idle", [], typeof i18n === "function" ? i18n : null, root.languagePreference)
        }
    }

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    Kirigami.Separator {
        visible: root.showSeparator
        Layout.fillWidth: true
    }

    PlasmaComponents.Label {
        id: footerStatusLabel
        objectName: "footerStatusLabel"
        text: root.statusText
        color: Kirigami.Theme.disabledTextColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        elide: Text.ElideRight
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }
}
