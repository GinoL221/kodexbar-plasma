import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: root

    property var errors: []
    readonly property int maximumRenderedErrors: 20
    readonly property var renderedErrors: errors instanceof Array
        ? errors.slice(0, maximumRenderedErrors)
        : []
    readonly property int omittedErrorCount: errors instanceof Array
        ? Math.max(0, errors.length - renderedErrors.length)
        : 0
    readonly property int errorCount: errors instanceof Array ? errors.length : 0
    property bool expanded: false
    readonly property alias disclosureButton: disclosure

    function valueText(value) {
        return value === null || value === undefined ? "" : String(value)
    }

    function failureText(failure) {
        if (failure === null || failure === undefined) {
            return i18n("Provider returned an unknown error")
        }
        if (typeof failure === "string") {
            return failure
        }
        if (typeof failure.error === "string") {
            return failure.error
        }
        if (failure.error && typeof failure.error.message === "string") {
            return failure.error.message
        }
        if (typeof failure.message === "string") {
            return failure.message
        }
        return String(failure.error || failure)
    }

    visible: errorCount > 0
    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing
    Accessible.name: i18np("%1 provider failure", "%1 provider failures", errorCount)

    QQC2.ToolButton {
        id: disclosure

        checkable: true
        checked: root.expanded
        text: i18np("Show %1 provider failure", "Show %1 provider failures", root.errorCount)
        icon.name: checked ? "arrow-down" : "arrow-right"
        display: QQC2.AbstractButton.TextBesideIcon
        Accessible.name: text
        Accessible.description: checked
            ? i18n("Collapse provider failures")
            : i18n("Expand provider failures")
        onToggled: root.expanded = checked
    }

    ColumnLayout {
        visible: root.expanded
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: root.renderedErrors

            delegate: PlasmaComponents.Label {
                required property var modelData

                text: {
                    var provider = root.valueText(modelData.provider)
                    var source = root.valueText(modelData.source)
                    var identity = [provider, source].filter(function(value) {
                        return value.length > 0
                    }).join(" · ")
                    var detail = root.failureText(modelData)
                    return identity.length > 0 ? identity + ": " + detail : detail
                }
                color: Kirigami.Theme.negativeTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Accessible.name: text
            }
        }

        PlasmaComponents.Label {
            visible: root.omittedErrorCount > 0
            text: i18np("%1 additional failure not shown", "%1 additional failures not shown", root.omittedErrorCount)
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Accessible.name: text
        }
    }
}
