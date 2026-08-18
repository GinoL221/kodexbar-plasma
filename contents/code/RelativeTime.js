.pragma library

// Formats a CLI ISO-8601 updatedAt for scannable header copy.
// Returns "" when the value is missing or not parseable — never invents a clock.

function parseIsoMs(value) {
    if (typeof value !== "string" || value.length === 0) {
        return NaN
    }
    var normalized = value
    // Accept trailing Z or ±offset; Date.parse handles both in Qt/JS.
    var ms = Date.parse(normalized)
    return typeof ms === "number" && isFinite(ms) ? ms : NaN
}

function formatUpdatedLabel(updatedAt, nowMs, translateFn) {
    var thenMs = parseIsoMs(updatedAt)
    if (!isFinite(thenMs)) {
        return ""
    }
    var now = typeof nowMs === "number" && isFinite(nowMs) ? nowMs : Date.now()
    var deltaSec = Math.max(0, Math.floor((now - thenMs) / 1000))

    function t(template, args) {
        if (typeof translateFn === "function") {
            return translateFn(template, args instanceof Array ? args : [], null)
        }
        var text = String(template)
        var values = args instanceof Array ? args : []
        return text.replace(/%([1-9][0-9]*)/g, function(match, index) {
            var i = Number(index) - 1
            return i >= 0 && i < values.length ? String(values[i]) : match
        })
    }

    if (deltaSec < 45) {
        return t("Updated just now", [])
    }
    var minutes = Math.max(1, Math.floor(deltaSec / 60))
    if (deltaSec < 3600) {
        if (minutes === 1) {
            return t("Updated 1 minute ago", [])
        }
        return t("Updated %1 minutes ago", [minutes])
    }
    var hours = Math.max(1, Math.floor(deltaSec / 3600))
    if (deltaSec < 86400) {
        if (hours === 1) {
            return t("Updated 1 hour ago", [])
        }
        return t("Updated %1 hours ago", [hours])
    }
    var days = Math.max(1, Math.floor(deltaSec / 86400))
    if (days === 1) {
        return t("Updated 1 day ago", [])
    }
    if (days < 14) {
        return t("Updated %1 days ago", [days])
    }
    // Older than two weeks: keep a short absolute-ish fallback from the raw stamp.
    return t("Updated: %1", [updatedAt])
}
