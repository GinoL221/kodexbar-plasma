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

    function translate(text) {
        return typeof i18n === "function" ? i18n(text) : text
    }

    function translatePlural(singular, plural, count) {
        if (typeof i18np === "function") {
            return i18np(singular, plural, count)
        }
        return (count === 1 ? singular : plural).replace("%1", count)
    }

    function valueText(value) {
        return value === null || value === undefined ? "" : String(value)
    }

    function failureText(failure) {
        var kind = ""
        var message = ""
        var details = failure

        if (details && typeof details === "object" && details.error !== undefined) {
            details = details.error
        }
        if (typeof details === "string") {
            message = details
        } else if (details && typeof details === "object") {
            kind = valueText(details.kind)
            message = valueText(details.message)
        }

        var normalizedKind = kind.toLowerCase()
        var normalizedMessage = message.toLowerCase()
        if (["auth", "authentication", "credential", "credentials"].indexOf(normalizedKind) !== -1
            || /\b(?:authentication|auth)\s+(?:failed|required|missing|expired|invalid|error)\b/.test(normalizedMessage)
            || /\b(?:api key|api_key)\s+(?:missing|required|expired|invalid)\b/.test(normalizedMessage)
            || /\b(?:sign[\s-]?in)\s+(?:failed|required|needed)\b/.test(normalizedMessage)
            || /\b(?:unauthori[sz]ed|forbidden)\b/.test(normalizedMessage)) {
            return translate("Provider authentication is required")
        }
        if (["platform", "unsupported_platform", "unsupported-platform"].indexOf(normalizedKind) !== -1
            || /\bunsupported platform\b/.test(normalizedMessage)
            || /\b(?:enoexec|exec format error|architecture mismatch)\b/.test(normalizedMessage)) {
            return translate("Provider is not supported on this platform")
        }
        if (["config", "configuration", "misconfigured"].indexOf(normalizedKind) !== -1
            || /\bmisconfigured\b/.test(normalizedMessage)
            || /\b(?:configuration|config)\s+(?:required|invalid|missing|error)\b/.test(normalizedMessage)
            || /\binvalid setting\b/.test(normalizedMessage)) {
            return translate("Provider configuration needs attention")
        }
        return translate("Provider is unavailable")
    }

    visible: errorCount > 0
    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing
    Accessible.name: translatePlural("%1 provider failure", "%1 provider failures", errorCount)

    QQC2.ToolButton {
        id: disclosure

        checkable: true
        checked: root.expanded
        text: root.translatePlural("Show %1 provider failure", "Show %1 provider failures", root.errorCount)
        icon.name: checked ? "arrow-down" : "arrow-right"
        display: QQC2.AbstractButton.TextBesideIcon
        Accessible.name: text
        Accessible.description: checked
            ? root.translate("Collapse provider failures")
            : root.translate("Expand provider failures")
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
            text: root.translatePlural("%1 additional failure not shown", "%1 additional failures not shown", root.omittedErrorCount)
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Accessible.name: text
        }
    }
}
