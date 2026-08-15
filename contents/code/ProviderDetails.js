.pragma library

function isNonEmptyString(value) {
    return typeof value === "string" && value.length > 0
}

function rawValue(object, key) {
    return Object.prototype.hasOwnProperty.call(object, key) ? object[key] : null
}

function normalizeWords(text) {
    if (!isNonEmptyString(text)) {
        return []
    }

    var withSpaces = text
        .replace(/([a-z])([A-Z])/g, "$1 $2")
        .replace(/([A-Z]+)([A-Z][a-z])/g, "$1 $2")
        .toLowerCase()

    var normalized = withSpaces.replace(/[^a-z0-9]+/g, " ").trim()
    if (normalized.length === 0) {
        return []
    }

    var words = normalized.split(/\s+/)
    // Normalize the hyphenated "e mail" bigram to "email" for matching.
    var result = []
    for (var i = 0; i < words.length; i++) {
        if (words[i] === "e" && i + 1 < words.length && words[i + 1] === "mail") {
            result.push("email")
            i++
        } else {
            result.push(words[i])
        }
    }
    return result
}

var emailAddressPattern = /[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+/i

function containsEmailAddress(text) {
    return isNonEmptyString(text) && emailAddressPattern.test(text)
}

var excludedWords = {
    "email": true,
    "organization": true,
    "organisation": true,
    "pace": true,
    "credit": true,
    "credits": true,
    "cost": true,
    "costs": true,
    "token": true,
    "tokens": true
}

function containsExcludedWord(words) {
    for (var i = 0; i < words.length; i++) {
        if (excludedWords[words[i]]) {
            return true
        }
    }
    return false
}

function isRejectedText(text) {
    // Bare email addresses (e.g. "help@example.com") normalize to separate
    // words once "@"/"." are stripped, so they must be matched against the
    // original text before word-normalization discards those characters.
    if (containsEmailAddress(text)) {
        return true
    }
    var words = normalizeWords(text)
    if (words.length === 0) {
        return false
    }
    if (containsExcludedWord(words)) {
        return true
    }
    // Reject the explicit phrase "email signature" even when already covered by "email".
    for (var i = 0; i < words.length - 1; i++) {
        if (words[i] === "email" && words[i + 1] === "signature") {
            return true
        }
    }
    return false
}

function isValidRow(row) {
    if (!row || typeof row !== "object" || row instanceof Array) {
        return false
    }
    if (!isNonEmptyString(rawValue(row, "label")) || !isNonEmptyString(rawValue(row, "value"))) {
        return false
    }
    if (isRejectedText(row.label) || isRejectedText(row.value)) {
        return false
    }
    var secondary = rawValue(row, "secondaryValue")
    if (secondary !== undefined && secondary !== null && typeof secondary !== "string") {
        return false
    }
    if (secondary !== undefined && secondary !== null && isRejectedText(secondary)) {
        return false
    }
    return true
}

function isValidDetail(detail) {
    if (!detail || typeof detail !== "object" || detail instanceof Array) {
        return null
    }
    if (!isNonEmptyString(rawValue(detail, "title"))) {
        return null
    }
    if (isRejectedText(detail.title)) {
        return null
    }
    var rows = rawValue(detail, "rows")
    if (!(rows instanceof Array) || rows.length === 0) {
        return null
    }

    var acceptedRows = []
    for (var i = 0; i < rows.length; i++) {
        if (isValidRow(rows[i])) {
            acceptedRows.push(rows[i])
        }
    }
    if (acceptedRows.length === 0) {
        return null
    }

    return {
        title: detail.title,
        rows: acceptedRows
    }
}

function validVersion(providerData) {
    if (!providerData || typeof providerData !== "object" || providerData instanceof Array) {
        return ""
    }
    var raw = rawValue(providerData, "raw")
    if (!raw || typeof raw !== "object" || raw instanceof Array) {
        return ""
    }
    var version = rawValue(raw, "version")
    return isNonEmptyString(version) ? version : ""
}

function validLoginMethod(providerData) {
    if (!providerData || typeof providerData !== "object" || providerData instanceof Array) {
        return ""
    }
    var raw = rawValue(providerData, "raw")
    if (!raw || typeof raw !== "object" || raw instanceof Array) {
        return ""
    }
    var usage = rawValue(raw, "usage")
    if (!usage || typeof usage !== "object" || usage instanceof Array) {
        return ""
    }
    var login = rawValue(usage, "loginMethod")
    return isNonEmptyString(login) ? login : ""
}

// --- Phase 3: selected-provider enrichment extractors -----------------
// Narrow, validated, read-only display extractors for the selected-provider
// header and detail sections. Every function returns a copied primitive or
// plain object -- never the live raw reference -- and fails closed (empty
// string / null / empty collection) on anything missing or malformed.
// Identity fields prefer `usage.identity`, then the documented `usage`-level
// fallback observed in the real committed CLI fixture.

var uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
var hexLikePattern = /^[0-9a-f]{16,}$/i
var opaqueTokenPattern = /^[A-Za-z0-9_-]{20,}$/
var anchoredEmailPattern = new RegExp("^" + emailAddressPattern.source + "$", "i")

function rawUsage(providerData) {
    if (!providerData || typeof providerData !== "object" || providerData instanceof Array) {
        return null
    }
    var raw = rawValue(providerData, "raw")
    if (!raw || typeof raw !== "object" || raw instanceof Array) {
        return null
    }
    var usage = rawValue(raw, "usage")
    return usage && typeof usage === "object" && !(usage instanceof Array) ? usage : null
}

function rawTopLevel(providerData) {
    if (!providerData || typeof providerData !== "object" || providerData instanceof Array) {
        return null
    }
    var raw = rawValue(providerData, "raw")
    return raw && typeof raw === "object" && !(raw instanceof Array) ? raw : null
}

function identityValue(usage, key) {
    if (!usage) {
        return null
    }
    var identity = rawValue(usage, "identity")
    if (identity && typeof identity === "object" && !(identity instanceof Array)) {
        var fromIdentity = rawValue(identity, key)
        if (isNonEmptyString(fromIdentity)) {
            return fromIdentity
        }
    }
    var fromUsage = rawValue(usage, key)
    return isNonEmptyString(fromUsage) ? fromUsage : null
}

function validEmail(providerData) {
    var email = identityValue(rawUsage(providerData), "accountEmail")
    return email !== null && anchoredEmailPattern.test(email) ? email : ""
}

function looksOpaque(text) {
    return uuidPattern.test(text) || hexLikePattern.test(text) || opaqueTokenPattern.test(text)
}

function validOrganization(providerData) {
    var organization = identityValue(rawUsage(providerData), "accountOrganization")
    if (organization === null || containsEmailAddress(organization) || looksOpaque(organization)) {
        return ""
    }
    return organization
}

function validUpdatedAt(providerData) {
    var usage = rawUsage(providerData)
    var updatedAt = usage ? rawValue(usage, "updatedAt") : null
    return isNonEmptyString(updatedAt) ? updatedAt : ""
}

var paceWindowDefinitions = [
    { key: "primary", label: "Session" },
    { key: "secondary", label: "Weekly" },
    { key: "tertiary", label: "Monthly" }
]

// Maps valid CLI-supplied pace.primary/secondary/tertiary to Session/Weekly/
// Monthly, keyed by label so callers can attach a pace summary onto the
// matching usage window. Entries without a human-readable summary are
// omitted -- never fabricated.
function paceSummaryByLabel(providerData) {
    var raw = rawTopLevel(providerData)
    var pace = raw ? rawValue(raw, "pace") : null
    var result = {}
    if (!pace || typeof pace !== "object" || pace instanceof Array) {
        return result
    }
    for (var i = 0; i < paceWindowDefinitions.length; i++) {
        var definition = paceWindowDefinitions[i]
        var entry = rawValue(pace, definition.key)
        if (entry && typeof entry === "object" && !(entry instanceof Array) && isNonEmptyString(entry.summary)) {
            result[definition.label] = entry.summary
        }
    }
    return result
}

function isFiniteNonNegative(value) {
    return typeof value === "number" && isFinite(value) && value >= 0
}

function validCreditsRemaining(providerData) {
    var raw = rawTopLevel(providerData)
    var credits = raw ? rawValue(raw, "credits") : null
    if (!credits || typeof credits !== "object" || credits instanceof Array) {
        return null
    }
    var remaining = rawValue(credits, "remaining")
    return isFiniteNonNegative(remaining) ? remaining : null
}

function validResetCreditEntry(entry) {
    if (!entry || typeof entry !== "object" || entry instanceof Array) {
        return null
    }
    var amount = rawValue(entry, "amount")
    var expiresAt = rawValue(entry, "expiresAt")
    if (!isFiniteNonNegative(amount) || !isNonEmptyString(expiresAt)) {
        return null
    }
    return { amount: amount, expiresAt: expiresAt }
}

// Returns { availableCount, credits: [{amount, expiresAt}] } only when a
// structurally valid, positive reset-credit inventory exists; otherwise null
// so the whole section is omitted rather than shown with a placeholder.
function validResetCredits(providerData) {
    var usage = rawUsage(providerData)
    var reset = usage ? rawValue(usage, "codexResetCredits") : null
    if (!reset || typeof reset !== "object" || reset instanceof Array) {
        return null
    }
    var availableCount = rawValue(reset, "availableCount")
    if (!isFiniteNonNegative(availableCount) || availableCount <= 0) {
        return null
    }
    var creditsArray = rawValue(reset, "credits")
    var accepted = []
    if (creditsArray instanceof Array) {
        for (var i = 0; i < creditsArray.length; i++) {
            var validated = validResetCreditEntry(creditsArray[i])
            if (validated !== null) {
                accepted.push(validated)
            }
        }
    }
    return { availableCount: availableCount, credits: accepted }
}

function acceptedDetails(providerData) {
    if (!providerData || typeof providerData !== "object" || providerData instanceof Array) {
        return []
    }
    var raw = rawValue(providerData, "raw")
    if (!raw || typeof raw !== "object" || raw instanceof Array) {
        return []
    }
    var usage = rawValue(raw, "usage")
    if (!usage || typeof usage !== "object" || usage instanceof Array) {
        return []
    }
    var details = rawValue(usage, "details")
    if (!(details instanceof Array)) {
        return []
    }

    var accepted = []
    for (var i = 0; i < details.length; i++) {
        var sanitized = isValidDetail(details[i])
        if (sanitized !== null) {
            accepted.push(sanitized)
        }
    }
    return accepted
}
