.pragma library

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

function key(value) {
    var normalized = String(value || "").toLowerCase()
    return knownProviders.indexOf(normalized) !== -1 ? normalized : ""
}

// Known multi-word / brand spellings. Keys are lowercase CLI provider ids.
// Unlisted ids fall back to a single leading capital (codex → Codex).
var displayNames = {
    "alibabatokenplan": "Alibaba Token Plan",
    "azureopenai": "Azure OpenAI",
    "commandcode": "Command Code",
    "kimik2": "Kimi K2",
    "llmproxy": "LLM Proxy",
    "openai": "OpenAI",
    "opencode": "OpenCode",
    "opencodego": "OpenCode Go",
    "openrouter": "OpenRouter",
    "stepfun": "StepFun",
    "t3chat": "T3 Chat",
    "vertexai": "Vertex AI"
}

function displayName(value) {
    if (value === null || value === undefined) {
        return ""
    }
    var text = String(value)
    if (text.length === 0) {
        return ""
    }
    var normalized = text.toLowerCase()
    if (Object.prototype.hasOwnProperty.call(displayNames, normalized)) {
        return displayNames[normalized]
    }
    return text.charAt(0).toUpperCase() + text.slice(1)
}
