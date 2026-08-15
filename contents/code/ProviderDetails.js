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
