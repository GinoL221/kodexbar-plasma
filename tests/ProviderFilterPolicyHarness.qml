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

        // 4. Custom provider ordering
        var orderedList = ProviderFilterPolicy.parseOrder(" Claude , codex, nan , CLAUDE ")
        assert(orderedList.length === 3 && orderedList[0] === "claude" && orderedList[1] === "codex" && orderedList[2] === "nan",
               "parseOrder trims, lowercases, and deduplicates provider IDs")

        var unsortedSample = [
            { provider: "codex", windows: [] },
            { provider: "antigravity", windows: [] },
            { provider: "grok", windows: [] },
            { provider: "nan", windows: [] },
            { provider: "claude", windows: [] }
        ]
        var sorted = ProviderFilterPolicy.sortProviders(unsortedSample, "claude, codex, nan")
        assert(sorted.length === 5, "sortProviders preserves all providers")
        assert(sorted[0].provider === "claude", "claude moved to 1st")
        assert(sorted[1].provider === "codex", "codex moved to 2nd")
        assert(sorted[2].provider === "nan", "nan moved to 3rd")
        assert(sorted[3].provider === "antigravity", "unlisted antigravity keeps relative order 4th")
        assert(sorted[4].provider === "grok", "unlisted grok keeps relative order 5th")

        // 5. Combined filter and sort
        var filteredSorted = ProviderFilterPolicy.filterAndSortProviders(unsortedSample, "grok", "claude, nan, codex")
        assert(filteredSorted.length === 4, "filterAndSortProviders hides grok and sorts remaining 4")
        assert(filteredSorted[0].provider === "claude" && filteredSorted[1].provider === "nan"
               && filteredSorted[2].provider === "codex" && filteredSorted[3].provider === "antigravity",
               "filterAndSortProviders order matches claude, nan, codex, antigravity")

        // 6. Moving a provider left/up (-1) or right/down (+1)
        var currentIds = ["codex", "antigravity", "grok", "nan", "claude"]
        var movedLeft = ProviderFilterPolicy.moveProviderInOrder(currentIds, "", "claude", -1)
        assert(movedLeft === "codex, antigravity, grok, claude, nan",
               "moving claude left (-1) swaps it with nan: " + movedLeft)
        var movedAgain = ProviderFilterPolicy.moveProviderInOrder(currentIds, movedLeft, "claude", -1)
        assert(movedAgain === "codex, antigravity, claude, grok, nan",
               "moving claude left (-1) again swaps it with grok: " + movedAgain)
        var boundaryMove = ProviderFilterPolicy.moveProviderInOrder(currentIds, movedAgain, "codex", -1)
        assert(boundaryMove === "codex, antigravity, claude, grok, nan",
               "moving first provider left (-1) is a no-op at boundary")

        finish()
    }
}
