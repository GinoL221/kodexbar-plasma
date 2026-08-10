import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: root

    property var providerData: ({})
    property var windows: providerData && providerData.windows instanceof Array
        ? providerData.windows
        : []
    property string providerValue: providerData && providerData.provider !== null
        && providerData.provider !== undefined
        ? String(providerData.provider)
        : ""
    property string sourceValue: providerData && providerData.source !== null
        && providerData.source !== undefined
        ? String(providerData.source)
        : ""
    readonly property string providerText: providerValue.length > 0 ? providerValue : i18n("Provider")
    readonly property string accessibleState: windows.length > 0
        ? i18np("%1 available usage window", "%1 available usage windows", windows.length)
        : i18n("No usage windows available")

    function iconSource(value) {
        var knownProviders = [
            "abacus", "alibaba", "alibabatokenplan", "amp", "antigravity", "augment",
            "azureopenai", "bedrock", "claude", "codebuff", "codex", "commandcode",
            "copilot", "crof", "cursor", "deepgram", "deepseek", "devin", "doubao",
            "elevenlabs", "factory", "gemini", "grok", "groq", "jetbrains", "kilo",
            "kimi", "kimik2", "kiro", "llmproxy", "manus", "mimo", "minimax", "mistral",
            "moonshot", "ollama", "openai", "opencode", "opencodego", "openrouter",
            "perplexity", "stepfun", "synthetic", "t3chat", "venice", "vertexai", "warp",
            "windsurf", "zai"
        ]
        var key = String(value || "").toLowerCase()
        return knownProviders.indexOf(key) !== -1
            ? Qt.resolvedUrl("../icons/providers/" + key + ".svg")
            : "dialog-information"
    }

    function valueText(value) {
        return value === null || value === undefined ? "" : String(value)
    }

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing
    Accessible.name: i18n("%1 provider, %2", providerText, accessibleState)
    Accessible.description: sourceValue.length > 0
        ? i18n("Source: %1", sourceValue)
        : accessibleState

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: root.iconSource(root.providerValue)
            implicitWidth: Kirigami.Units.iconSizes.smallMedium
            implicitHeight: Kirigami.Units.iconSizes.smallMedium
            Layout.alignment: Qt.AlignTop
            Accessible.name: i18n("%1 provider icon", root.providerText)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                text: root.providerText
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                visible: root.sourceValue.length > 0
                text: root.sourceValue
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    Repeater {
        model: root.windows

        delegate: ColumnLayout {
            required property var modelData

            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing / 2
            Accessible.name: i18n("%1 window", modelData.label || "")
            Accessible.description: {
                var details = []
                if (modelData.usedPercent !== null && modelData.usedPercent !== undefined) {
                    details.push(i18n("%1% used", modelData.usedPercent))
                }
                if (root.valueText(modelData.resetsAt).length > 0) {
                    details.push(i18n("Reset: %1", root.valueText(modelData.resetsAt)))
                }
                if (root.valueText(modelData.resetDescription).length > 0) {
                    details.push(root.valueText(modelData.resetDescription))
                }
                return details.join(", ")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: modelData.label || ""
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PlasmaComponents.Label {
                    visible: modelData.usedPercent !== null && modelData.usedPercent !== undefined
                    text: i18n("%1% used", modelData.usedPercent)
                    color: Kirigami.Theme.textColor
                    elide: Text.ElideRight
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 9
                }
            }

            PlasmaComponents.Label {
                visible: root.valueText(modelData.resetsAt).length > 0
                text: i18n("Reset: %1", root.valueText(modelData.resetsAt))
                color: Kirigami.Theme.disabledTextColor
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                visible: root.valueText(modelData.resetDescription).length > 0
                text: root.valueText(modelData.resetDescription)
                color: Kirigami.Theme.disabledTextColor
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }
}
