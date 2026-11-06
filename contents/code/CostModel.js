.pragma library

function isFiniteNonNegative(value) {
    return typeof value === "number" && isFinite(value) && value >= 0
}

function rawValue(object, key) {
    return Object.prototype.hasOwnProperty.call(object, key) ? object[key] : null
}

function singleEntry(payload) {
    if (payload instanceof Array) {
        return payload.length === 1 ? payload[0] : null
    }
    if (payload && typeof payload === "object") {
        return payload
    }
    return null
}

function validDailyEntry(day) {
    return day && typeof day === "object" && !(day instanceof Array)
        && typeof day.date === "string" && /^\d{4}-\d{2}-\d{2}$/.test(day.date)
        && isFiniteNonNegative(day.totalCost)
        && (day.totalTokens === undefined || isFiniteNonNegative(day.totalTokens))
}

function normalizeDaily(daily) {
    if (!(daily instanceof Array)) {
        return []
    }
    var result = []
    for (var i = 0; i < daily.length; ++i) {
        var day = daily[i]
        if (validDailyEntry(day)) {
            result.push({ date: day.date, totalCost: day.totalCost,
                          totalTokens: day.totalTokens === undefined ? 0 : day.totalTokens })
        }
    }
    result.sort(function(a, b) { return a.date < b.date ? -1 : (a.date > b.date ? 1 : 0) })
    return result.slice(-30)
}

function extractPrimaryModel(daily) {
    if (!(daily instanceof Array)) {
        return ""
    }
    var totals = Object.create(null)
    var names = []
    for (var i = 0; i < daily.length; ++i) {
        var day = daily[i]
        if (!validDailyEntry(day) || !(day.modelBreakdowns instanceof Array)) {
            continue
        }
        for (var j = 0; j < day.modelBreakdowns.length; ++j) {
            var model = day.modelBreakdowns[j]
            if (!model || typeof model.modelName !== "string" || model.modelName.length === 0
                || !isFiniteNonNegative(model.cost)
                || (model.totalTokens !== undefined && !isFiniteNonNegative(model.totalTokens))) {
                continue
            }
            var name = model.modelName
            if (!totals[name]) {
                totals[name] = { cost: 0, tokens: 0 }
                names.push(name)
            }
            totals[name].cost += model.cost
            totals[name].tokens += model.totalTokens === undefined ? 0 : model.totalTokens
        }
    }
    var best = ""
    for (var k = 0; k < names.length; ++k) {
        var candidate = names[k]
        if (!best || totals[candidate].cost > totals[best].cost
            || (totals[candidate].cost === totals[best].cost && totals[candidate].tokens > totals[best].tokens)) {
            best = candidate
        }
    }
    return best
}

// Normalizes exactly one `cost --provider {provider} --format json --json-only`
// response for the given expected provider. Returns a copied, validated
// snapshot on success, or null when the payload is empty, malformed,
// unsupported (error-shaped), for a different provider, or carries any
// non-finite/negative numeric field. All four numeric fields must be valid
// or the whole result is discarded — never a partial render.
function normalize(payload, expectedProvider) {
    if (typeof expectedProvider !== "string" || expectedProvider.length === 0) {
        return null
    }

    var entry = singleEntry(payload)
    if (!entry || typeof entry !== "object" || entry instanceof Array) {
        return null
    }
    if (entry.error !== undefined && entry.error !== null) {
        return null
    }
    if (entry.provider !== expectedProvider) {
        return null
    }

    var sessionCostUSD = rawValue(entry, "sessionCostUSD")
    var sessionTokens = rawValue(entry, "sessionTokens")
    var last30DaysCostUSD = rawValue(entry, "last30DaysCostUSD")
    var last30DaysTokens = rawValue(entry, "last30DaysTokens")

    if (!isFiniteNonNegative(sessionCostUSD)
        || !isFiniteNonNegative(sessionTokens)
        || !isFiniteNonNegative(last30DaysCostUSD)
        || !isFiniteNonNegative(last30DaysTokens)) {
        return null
    }

    return {
        provider: entry.provider,
        source: rawValue(entry, "source"),
        sessionCostUSD: sessionCostUSD,
        sessionTokens: sessionTokens,
        last30DaysCostUSD: last30DaysCostUSD,
        last30DaysTokens: last30DaysTokens,
        daily: normalizeDaily(entry.daily),
        primaryModel: extractPrimaryModel(entry.daily)
    }
}
