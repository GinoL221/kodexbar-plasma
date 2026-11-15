import QtQuick
import "../contents/code/ProviderIcons.mjs" as ProviderIcons

Item {
    id: root
    width: 1
    height: 1
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("ProviderIconsHarness failure:", message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() {
        Qt.exit(assertionFailed ? 1 : 0)
    }

    Component.onCompleted: {
        // key() allowlist
        assert(ProviderIcons.key("codex") === "codex", "known provider key must normalize")
        assert(ProviderIcons.key("CODEX") === "codex", "key must be case-insensitive")
        assert(ProviderIcons.key("not-a-provider") === "", "unknown provider key must be empty")
        assert(ProviderIcons.key(null) === "", "null key must be empty")
        assert(ProviderIcons.key(undefined) === "", "undefined key must be empty")

        // displayName brand map
        assert(ProviderIcons.displayName("opencodego") === "OpenCode Go",
               "opencodego must render as OpenCode Go")
        assert(ProviderIcons.displayName("OpenCodeGo") === "OpenCode Go",
               "displayName must be case-insensitive on mapped keys")
        assert(ProviderIcons.displayName("openai") === "OpenAI", "openai brand spelling")
        assert(ProviderIcons.displayName("opencode") === "OpenCode", "opencode brand spelling")
        assert(ProviderIcons.displayName("openrouter") === "OpenRouter", "openrouter brand spelling")
        assert(ProviderIcons.displayName("azureopenai") === "Azure OpenAI", "azureopenai brand spelling")
        assert(ProviderIcons.displayName("nan") === "NaN Cloud", "nan brand spelling")
        assert(ProviderIcons.key("nan") === "nan", "nan ships a bundled icon; the masked theme fallback renders a solid square")
        assert(ProviderIcons.displayName("vertexai") === "Vertex AI", "vertexai brand spelling")
        assert(ProviderIcons.displayName("alibabatokenplan") === "Alibaba Token Plan",
               "alibabatokenplan brand spelling")
        assert(ProviderIcons.displayName("kimik2") === "Kimi K2", "kimik2 brand spelling")
        assert(ProviderIcons.displayName("llmproxy") === "LLM Proxy", "llmproxy brand spelling")
        assert(ProviderIcons.displayName("commandcode") === "Command Code", "commandcode brand spelling")
        assert(ProviderIcons.displayName("stepfun") === "StepFun", "stepfun brand spelling")
        assert(ProviderIcons.displayName("t3chat") === "T3 Chat", "t3chat brand spelling")

        // Fallback: single leading capital, preserve the rest of the CLI id
        assert(ProviderIcons.displayName("codex") === "Codex", "unmapped id capitalizes first letter")
        assert(ProviderIcons.displayName("claude") === "Claude", "unmapped id capitalizes first letter")
        assert(ProviderIcons.displayName("summary-provider") === "Summary-provider",
               "hyphenated unmapped ids only capitalize the first character")
        assert(ProviderIcons.displayName("") === "", "empty displayName stays empty")
        assert(ProviderIcons.displayName(null) === "", "null displayName stays empty")
        assert(ProviderIcons.displayName(undefined) === "", "undefined displayName stays empty")

        // Brand accent: limited UI token (tab underline + bar fill only).
        // Empty string means "use Kirigami.Theme.highlightColor" at the call site.
        assert(typeof ProviderIcons.accent === "function", "accent() must exist")
        assert(ProviderIcons.accent("claude").length > 0, "claude must have a brand accent")
        assert(ProviderIcons.accent("codex").length > 0, "codex must have a brand accent")
        assert(ProviderIcons.accent("claude") !== ProviderIcons.accent("codex"),
               "claude and codex accents must differ")
        assert(ProviderIcons.accent("CLAUDE") === ProviderIcons.accent("claude"),
               "accent must be case-insensitive")
        assert(ProviderIcons.accent("not-a-provider") === "",
               "unknown provider accent must be empty for theme fallback")
        assert(ProviderIcons.accent(null) === "" && ProviderIcons.accent(undefined) === "",
               "null/undefined accent must be empty")
        assert(ProviderIcons.accent("claude").charAt(0) === "#",
               "mapped accents must be #rrggbb tokens")
        assert(ProviderIcons.accent("antigravity") === "#3186FF", "antigravity brand accent")
        assert(ProviderIcons.accent("nan") === "#7D39EB", "nan brand accent")

        assert(Array.isArray(ProviderIcons.defaultOrderCandidates)
               && ProviderIcons.defaultOrderCandidates.join(",") === "codex,claude,antigravity,grok,nan",
               "defaultOrderCandidates must list the 5 featured providers in order")
        var pinnedKeys = ProviderIcons.pinnedProviderKeys()
        assert(Array.isArray(pinnedKeys)
               && pinnedKeys.length === ProviderIcons.knownProviders.length + 1,
               "pinnedProviderKeys must include empty key plus every known provider once")
        assert(pinnedKeys.slice(0, 6).join(",") === ",codex,claude,antigravity,grok,nan",
               "pinnedProviderKeys must start with empty key then featured providers")
        var pinnedLabels = ProviderIcons.pinnedProviderLabels("All providers")
        assert(Array.isArray(pinnedLabels) && pinnedLabels.length === pinnedKeys.length,
               "pinnedProviderLabels must align 1:1 with pinnedProviderKeys")
        assert(pinnedLabels.slice(0, 6).join("|") === "All providers|Codex|Claude|Antigravity|Grok|NaN Cloud",
               "pinnedProviderLabels must format featured providers via displayName")

        finish()
    }
}
