import QtQuick
import "../contents/code/ProviderFilterPolicy.js" as ProviderFilterPolicy

Item {
    id: root
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("ProviderFilterPolicyHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        // 1. Parsing excluded strings
        var emptyParsed = ProviderFilterPolicy.parseExcluded("")
        assert(emptyParsed.length === 0, "empty string yields empty array")
        assert(ProviderFilterPolicy.parseExcluded(null).length === 0, "null yields empty array")

        var parsed = ProviderFilterPolicy.parseExcluded(" Claude , grok,CLAUDE , copilot ")
        assert(parsed.length === 3, "must trim, deduplicate, and lowercase tokens")
        assert(parsed[0] === "claude", "first token is claude")
        assert(parsed[1] === "grok", "second token is grok")
        assert(parsed[2] === "copilot", "third token is copilot")

        // 2. Visibility checks
        assert(ProviderFilterPolicy.isVisible("claude", parsed) === false, "claude in excluded list is not visible")
        assert(ProviderFilterPolicy.isVisible("Claude", parsed) === false, "case-insensitive check hides Claude")
        assert(ProviderFilterPolicy.isVisible("chatgpt", parsed) === true, "chatgpt not in excluded list is visible")
        assert(ProviderFilterPolicy.isVisible("", parsed) === false, "empty id is not visible")

        // 3. Filtering provider lists
        var sample = [
            { provider: "claude", windows: [] },
            { provider: "chatgpt", windows: [] },
            { provider: "grok", windows: [] }
        ]
        var filtered = ProviderFilterPolicy.filterProviders(sample, "grok")
        assert(filtered.length === 2, "excluding grok leaves 2 providers")
        assert(filtered[0].provider === "claude", "first is claude")
        assert(filtered[1].provider === "chatgpt", "second is chatgpt")

        var filteredMultiple = ProviderFilterPolicy.filterProviders(sample, "claude, grok")
        assert(filteredMultiple.length === 1, "excluding claude and grok leaves 1 provider")
        assert(filteredMultiple[0].provider === "chatgpt", "remaining provider is chatgpt")

        var untouched = ProviderFilterPolicy.filterProviders(sample, "")
        assert(untouched.length === 3, "empty filter returns all providers unchanged")

        finish()
    }
}
