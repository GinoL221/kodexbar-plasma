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

// Limited brand accents for tab underline + usage bar fill only.
// Empty string → call site uses Kirigami.Theme.highlightColor.
// Tokens are #rrggbb chosen for legibility on both Breeze Light and Dark tracks.
var accents = {
    "claude": "#D97757",
    "codex": "#2AA8A0",
    "openai": "#10A37F",
    "opencode": "#3B82F6",
    "opencodego": "#3B82F6",
    "gemini": "#4285F4",
    "grok": "#A78BFA",
    "copilot": "#7C3AED",
    "cursor": "#F59E0B",
    "mistral": "#F97316",
    "kiro": "#8B5CF6",
    "perplexity": "#22D3EE",
    "deepseek": "#0EA5E9",
    "ollama": "#94A3B8",
    "openrouter": "#6366F1",
    "azureopenai": "#0078D4",
    "vertexai": "#34A853"
}

function accent(value) {
    var k = key(value)
    if (k.length === 0) {
        return ""
    }
    if (Object.prototype.hasOwnProperty.call(accents, k)) {
        return accents[k]
    }
    return ""
}
