.pragma library

// Backoff policy for provider endpoints that throttle polling, most notably
// the Anthropic Claude usage endpoint (HTTP 429 `rate_limit_error` with an
// unactionable `retry-after: 0`). Pure data only: the controller counts
// consecutive rate-limited responses and stretches its next poll.

var INITIAL_DELAY_MS = 120000
var MAX_DELAY_MS = 1800000

function isRateLimitError(errorEntry) {
    if (!errorEntry || typeof errorEntry !== "object") {
        return false
    }
    var error = errorEntry.error
    if (!error || typeof error !== "object") {
        return false
    }
    if (Number(error.code) === 3) {
        return true
    }
    var message = typeof error.message === "string" ? error.message : ""
    return /rate[ _-]?limit/i.test(message) || /429/.test(message)
}

function hasRateLimitError(errors) {
    if (!Array.isArray(errors)) {
        return false
    }
    var i
    for (i = 0; i < errors.length; i++) {
        if (isRateLimitError(errors[i])) {
            return true
        }
    }
    return false
}

// Unique, first-seen provider ids whose entry is a rate limit. The real CLI
// payload mixes one throttled provider into dozens of unrelated provider
// errors, so the caller cannot require an all-rate-limit response.
function rateLimitedProviderIds(errors) {
    var ids = []
    if (!Array.isArray(errors)) {
        return ids
    }
    var i, entry, provider
    for (i = 0; i < errors.length; i++) {
        entry = errors[i]
        if (!isRateLimitError(entry)) {
            continue
        }
        provider = entry !== null && typeof entry === "object" && typeof entry.provider === "string"
            ? entry.provider : ""
        if (provider.length > 0 && ids.indexOf(provider) === -1) {
            ids.push(provider)
        }
    }
    return ids
}

// Fresh providers always win. A rate-limited provider that did not answer
// keeps its previous entry so the popup does not blank out mid-session, and
// a provider that never had an entry is never fabricated.
function mergeRateLimitedProviders(freshProviders, previousProviders, errors) {
    var merged = Array.isArray(freshProviders) ? freshProviders.slice(0) : []
    var previous = Array.isArray(previousProviders) ? previousProviders : []
    var ids = rateLimitedProviderIds(errors)
    var i, j, id, found, previousEntry
    for (i = 0; i < ids.length; i++) {
        id = ids[i]
        found = false
        for (j = 0; j < merged.length; j++) {
            if (merged[j] !== null && merged[j].provider === id) {
                found = true
                break
            }
        }
        if (found) {
            continue
        }
        previousEntry = null
        for (j = 0; j < previous.length; j++) {
            if (previous[j] !== null && previous[j].provider === id) {
                previousEntry = previous[j]
                break
            }
        }
        if (previousEntry !== null) {
            merged.push(previousEntry)
        }
    }
    return merged
}

function backoffDelayMs(consecutive) {
    if (typeof consecutive !== "number" || !isFinite(consecutive) || consecutive <= 0) {
        return 0
    }
    var delay = INITIAL_DELAY_MS * Math.pow(2, consecutive - 1)
    return Math.min(delay, MAX_DELAY_MS)
}

function parseRetryAfterMs(value) {
    var trimmed, seconds, date, remainingMs
    if (typeof value === "number") {
        if (!isFinite(value) || value <= 0) {
            return null
        }
        return Math.round(value * 1000)
    }
    if (typeof value !== "string") {
        return null
    }
    trimmed = value.replace(/^\s+|\s+$/g, "")
    if (trimmed.length === 0) {
        return null
    }
    if (/^[0-9]+(\.[0-9]+)?$/.test(trimmed)) {
        seconds = Number(trimmed)
        return seconds > 0 ? Math.round(seconds * 1000) : null
    }
    date = Date.parse(trimmed)
    if (isNaN(date)) {
        return null
    }
    remainingMs = date - Date.now()
    return remainingMs > 0 ? remainingMs : null
}

function nextDelayMs(baseMs, consecutive, retryAfterValue) {
    var base = typeof baseMs === "number" && isFinite(baseMs) && baseMs > 0 ? baseMs : 0
    var retryAfter = parseRetryAfterMs(retryAfterValue)
    return Math.max(base, backoffDelayMs(consecutive), retryAfter === null ? 0 : retryAfter)
}

function retryMinutes(delayMs) {
    return Math.max(1, Math.ceil(delayMs / 60000))
}
