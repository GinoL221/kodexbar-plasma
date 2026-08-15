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
        last30DaysTokens: last30DaysTokens
    }
}
