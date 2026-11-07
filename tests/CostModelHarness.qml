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

        assert(Array.isArray(normalized.daily) && normalized.daily.length === 0, "omitted daily must default to an empty array")
        assert(normalized.primaryModel === "", "omitted daily must have no primary model")
        for (var optional of [null, {}, "invalid"]) {
            validPayload[0].daily = optional
            normalized = CostModel.normalize(validPayload, "codex")
            assert(normalized !== null && Array.isArray(normalized.daily) && normalized.daily.length === 0
                   && normalized.primaryModel === "", "invalid optional daily must be harmless")
        }

        validPayload[0].projects = [{ path: "/private/project" }]
        validPayload[0].daily = [
            { date: "2026-08-14", totalCost: 3.0041794, totalTokens: 16179755,
              modelBreakdowns: [{ modelName: "terra", cost: 2.7, totalTokens: 10 }, { modelName: "luna", cost: 0.3, totalTokens: 100 }] },
            { date: "2026-07-30", totalCost: 0, modelBreakdowns: [{ modelName: "sol", cost: 0 }] },
            { date: "2026-08-13", totalCost: 7.451, totalTokens: 123631102,
              modelBreakdowns: [{ modelName: "luna", cost: 4.2, totalTokens: 100 }, { modelName: "terra", cost: 3.2, totalTokens: 10 }] },
            null, {}, { date: "bad", totalCost: 1 }, { date: "2026-08-01", totalCost: -1 },
            { date: "2026-08-02", totalCost: NaN }, { date: "2026-08-03", totalCost: 1, totalTokens: -1 },
            { date: "2026-08-04", totalCost: 1, totalTokens: NaN }
        ]
        normalized = CostModel.normalize(validPayload, "codex")
        assert(normalized.daily.length === 3, "malformed days must be skipped")
        assert(normalized.daily[0].date === "2026-07-30" && normalized.daily[0].totalTokens === 0
               && normalized.daily[1].date === "2026-08-13" && normalized.daily[2].date === "2026-08-14", "daily must sort and default missing tokens")
        assert(Object.keys(normalized.daily[0]).length === 3 && !("modelBreakdowns" in normalized.daily[1]), "daily must expose only normalized fields")
        assert(normalized.primaryModel === "terra", "primary model must use cumulative cost")
        assert(!("projects" in normalized), "projects must never be exposed")

        validPayload[0].daily = [{ date: "2026-01-01", totalCost: 0, modelBreakdowns: [
            { modelName: "a", cost: 2, totalTokens: 1 }, { modelName: "b", cost: 2, totalTokens: 5 },
            { modelName: "bad", cost: -1, totalTokens: 999 }, { modelName: "bad", cost: NaN },
            { modelName: "bad", cost: 100, totalTokens: -1 }, { modelName: "", cost: 100 }
        ] }]
        assert(CostModel.normalize(validPayload, "codex").primaryModel === "b", "equal costs must break ties by tokens and ignore malformed breakdowns")
        validPayload[0].daily = []
        for (var day = 35; day >= 1; --day) {
            var date = day <= 31 ? "2026-01-" + (day < 10 ? "0" : "") + day : "2026-02-0" + (day - 31)
            validPayload[0].daily.push({ date: date, totalCost: day, totalTokens: day })
        }
        normalized = CostModel.normalize(validPayload, "codex")
        assert(normalized.daily.length === 30 && normalized.daily[0].date === "2026-01-06"
               && normalized.daily[29].date === "2026-02-04", "daily must retain the latest 30 entries in chronological order")

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
