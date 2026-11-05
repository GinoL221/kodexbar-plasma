.pragma library

/**
 * Pure policy for parsing excluded provider IDs and filtering provider lists.
 */

function parseExcluded(rawString) {
    if (typeof rawString !== "string" || rawString.trim().length === 0) {
        return []
    }
    var parts = rawString.split(",")
    var result = []
    for (var i = 0; i < parts.length; i++) {
        var token = parts[i].trim().toLowerCase()
        if (token.length > 0 && result.indexOf(token) === -1) {
            result.push(token)
        }
    }
    return result
}

function isVisible(providerId, excludedList) {
    if (!providerId || typeof providerId !== "string") {
        return false
    }
    var list = Array.isArray(excludedList) ? excludedList : []
    return list.indexOf(providerId.toLowerCase()) === -1
}

function filterProviders(providers, excludedInput) {
    var list = Array.isArray(providers) ? providers : []
    var excluded = Array.isArray(excludedInput) ? excludedInput : parseExcluded(excludedInput)
    if (excluded.length === 0) {
        return list
    }
    var visible = []
    for (var i = 0; i < list.length; i++) {
        var p = list[i]
        if (p && typeof p === "object" && typeof p.provider === "string") {
            if (isVisible(p.provider, excluded)) {
                visible.push(p)
            }
        }
    }
    return visible
}
