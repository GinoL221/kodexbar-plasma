export function isFiniteNonNegative(value) {
    return typeof value === "number" && isFinite(value) && value >= 0
}

export function rawValue(object, key) {
    return Object.prototype.hasOwnProperty.call(object, key) ? object[key] : null
}

export function singleEntry(payload) {
    if (payload instanceof Array) {
        return payload.length === 1 ? payload[0] : null
    }
    if (payload && typeof payload === "object") {
        return payload
    }
    return null
}

export function validDailyEntry(day) {
    return day && typeof day === "object" && !(day instanceof Array)
        && typeof day.date === "string" && /^\d{4}-\d{2}-\d{2}$/.test(day.date)
        && (day.totalCost !== undefined || day.totalTokens !== undefined)
        && (day.totalCost === undefined || isFiniteNonNegative(day.totalCost))
        && (day.totalTokens === undefined || isFiniteNonNegative(day.totalTokens))
}

export function normalizeDaily(daily) {
    if (!(daily instanceof Array)) {
        return []
    }
    var result = []
    for (var i = 0; i < daily.length; ++i) {
        var day = daily[i]
        if (validDailyEntry(day)) {
            result.push({ date: day.date,
                          totalCost: day.totalCost === undefined ? 0 : day.totalCost,
                          totalTokens: day.totalTokens === undefined ? 0 : day.totalTokens })
        }
    }
    result.sort(function(a, b) { return a.date < b.date ? -1 : (a.date > b.date ? 1 : 0) })
    return result.slice(-30)
}

export function extractPrimaryModel(daily) {
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
                || (model.cost === undefined && model.totalTokens === undefined)
                || (model.cost !== undefined && !isFiniteNonNegative(model.cost))
                || (model.totalTokens !== undefined && !isFiniteNonNegative(model.totalTokens))) {
                continue
            }
            var name = model.modelName
            if (!totals[name]) {
                totals[name] = { cost: 0, tokens: 0 }
                names.push(name)
            }
            totals[name].cost += model.cost === undefined ? 0 : model.cost
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
export function normalize(payload, expectedProvider) {
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

var MONTHS_EN = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
var MONTHS_ES = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]

// Comma-decimal / dot-thousands contract locked by ProviderRowHarness & goldens.
export function formatUsd(value) {
    var rounded = Math.round(value * 100) / 100
    var negative = rounded < 0
    var fixed = Math.abs(rounded).toFixed(2)
    var parts = fixed.split(".")
    var grouped = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ".")
    return (negative ? "-" : "") + grouped + "," + parts[1]
}

export function formatTokensAbbreviated(value) {
    var rounded = Math.round(value)
    var negative = rounded < 0
    var absValue = Math.abs(rounded)

    var suffix = ""
    var divisor = 1
    if (absValue >= 1000000000) {
        suffix = "B"
        divisor = 1000000000
    } else if (absValue >= 1000000) {
        suffix = "M"
        divisor = 1000000
    } else if (absValue >= 1000) {
        suffix = "K"
        divisor = 1000
    }

    if (suffix === "") {
        return (negative ? "-" : "") + String(absValue)
    }

    var fixed = (absValue / divisor).toFixed(1)
    var parts = fixed.split(".")
    return (negative ? "-" : "") + parts[0] + "," + parts[1] + suffix
}

export function formatDailyDate(isoDate, isSpanish) {
    if (typeof isoDate !== "string") {
        return ""
    }
    var match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(isoDate)
    if (!match) {
        return isoDate
    }
    var monthIndex = parseInt(match[2], 10) - 1
    var dayNum = parseInt(match[3], 10)
    var months = isSpanish ? MONTHS_ES : MONTHS_EN
    var monthName = months[monthIndex]
    if (!monthName) {
        return isoDate
    }
    return isSpanish ? (dayNum + " " + monthName) : (monthName + " " + dayNum)
}

export function formatDailyTooltip(entry, isSpanish) {
    if (!entry || typeof entry !== "object") {
        return ""
    }
    var dateLabel = formatDailyDate(entry.date, isSpanish)
    if (dateLabel.length === 0) {
        return ""
    }
    var hasCost = isFiniteNonNegative(entry.totalCost) && entry.totalCost > 0
    var hasTokens = isFiniteNonNegative(entry.totalTokens) && entry.totalTokens > 0
    if (hasCost && hasTokens) {
        return dateLabel + ": $" + formatUsd(entry.totalCost) + " · " + formatTokensAbbreviated(entry.totalTokens) + " tokens"
    }
    if (hasCost) {
        return dateLabel + ": $" + formatUsd(entry.totalCost)
    }
    if (hasTokens) {
        return dateLabel + ": " + formatTokensAbbreviated(entry.totalTokens) + " tokens"
    }
    return dateLabel + ": $0,00"
}

export function summarizeSnapshots(visibleProviders, snapshotLookup) {
    if (!Array.isArray(visibleProviders) || typeof snapshotLookup !== "function") {
        return null
    }
    var seen = Object.create(null)
    var count = 0
    var sessionCostUSD = 0
    var sessionTokens = 0
    var last30DaysCostUSD = 0
    var last30DaysTokens = 0

    for (var i = 0; i < visibleProviders.length; ++i) {
        var entry = visibleProviders[i]
        var provider = entry && typeof entry.provider === "string" ? entry.provider : ""
        if (provider.length === 0 || seen[provider]) {
            continue
        }
        seen[provider] = true
        var snap = snapshotLookup(provider)
        if (!snap || typeof snap !== "object"
            || !isFiniteNonNegative(snap.sessionCostUSD)
            || !isFiniteNonNegative(snap.sessionTokens)
            || !isFiniteNonNegative(snap.last30DaysCostUSD)
            || !isFiniteNonNegative(snap.last30DaysTokens)) {
            continue
        }
        count += 1
        sessionCostUSD += snap.sessionCostUSD
        sessionTokens += snap.sessionTokens
        last30DaysCostUSD += snap.last30DaysCostUSD
        last30DaysTokens += snap.last30DaysTokens
    }

    if (count === 0) {
        return null
    }
    return {
        count: count,
        sessionCostUSD: sessionCostUSD,
        sessionTokens: sessionTokens,
        last30DaysCostUSD: last30DaysCostUSD,
        last30DaysTokens: last30DaysTokens
    }
}
