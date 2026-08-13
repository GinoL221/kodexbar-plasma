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
