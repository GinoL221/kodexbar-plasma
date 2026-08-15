import QtQuick
import "../contents/code/CostModel.js" as CostModel

Item {
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("CostModelHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        var validPayload = [{
            provider: "codex",
            source: "local",
            sessionCostUSD: 0,
            sessionTokens: 0,
            last30DaysCostUSD: 10.455212920000001,
            last30DaysTokens: 139810857
        }]

        var normalized = CostModel.normalize(validPayload, "codex")
        assert(normalized !== null, "matching payload must normalize")
        assert(normalized.provider === "codex", "provider must be preserved")
        assert(normalized.source === "local", "source must be preserved")
        assert(normalized.sessionCostUSD === 0, "sessionCostUSD must be preserved")
        assert(normalized.sessionTokens === 0, "sessionTokens must be preserved")
        assert(normalized.last30DaysCostUSD === 10.455212920000001, "last30DaysCostUSD must be preserved")
        assert(normalized.last30DaysTokens === 139810857, "last30DaysTokens must be preserved")

        // Empty payloads must hide the section rather than render placeholder data.
        assert(CostModel.normalize([], "codex") === null, "empty array payload must be hidden")
        assert(CostModel.normalize({}, "codex") === null, "empty object payload must be hidden")
        assert(CostModel.normalize(null, "codex") === null, "null payload must be hidden")
        assert(CostModel.normalize(undefined, "codex") === null, "undefined payload must be hidden")

        // Partial payloads (a required numeric field missing) must hide entirely.
        var partialPayload = [{
            provider: "codex",
            source: "local",
            sessionCostUSD: 0,
            sessionTokens: 0,
            last30DaysTokens: 139810857
            // last30DaysCostUSD intentionally omitted
        }]
        assert(CostModel.normalize(partialPayload, "codex") === null, "payload missing a required field must be hidden")

        // Non-finite numeric fields (Infinity/NaN) must hide entirely.
        var nonFinitePayload = [{
            provider: "codex",
            source: "local",
            sessionCostUSD: Infinity,
            sessionTokens: 0,
            last30DaysCostUSD: 10,
            last30DaysTokens: 139810857
        }]
        assert(CostModel.normalize(nonFinitePayload, "codex") === null, "Infinity field must be hidden")

        var nanPayload = [{
            provider: "codex",
            source: "local",
            sessionCostUSD: 0,
            sessionTokens: NaN,
            last30DaysCostUSD: 10,
            last30DaysTokens: 139810857
        }]
        assert(CostModel.normalize(nanPayload, "codex") === null, "NaN field must be hidden")

        // A payload for a different provider than requested must never be published.
        var wrongProviderPayload = [{
            provider: "claude",
            source: "local",
            sessionCostUSD: 1,
            sessionTokens: 1,
            last30DaysCostUSD: 1,
            last30DaysTokens: 1
        }]
        assert(CostModel.normalize(wrongProviderPayload, "codex") === null, "mismatched provider must be hidden")

        // Unsupported/failed cost results carry an error shape and must be hidden,
        // matching the existing usage-error convention.
        var unsupportedPayload = [{
            provider: "codex",
            error: { kind: "provider", code: 1, message: "cost scan unsupported" }
        }]
        assert(CostModel.normalize(unsupportedPayload, "codex") === null, "error-shaped payload must be hidden")

        // A payload with some valid nonzero fields and one invalid field must be
        // hidden entirely -- never a partial render mixing good and bad data.
        var mixedPayload = [{
            provider: "codex",
            source: "local",
            sessionCostUSD: 5,
            sessionTokens: 12345,
            last30DaysCostUSD: -1,
            last30DaysTokens: 139810857
        }]
        assert(CostModel.normalize(mixedPayload, "codex") === null, "nonzero payload with one invalid field must be hidden, not partially rendered")

        finish()
    }
}
