.pragma library

var windowDefinitions = [
    { key: "primary", label: "Session" },
    { key: "secondary", label: "Weekly" },
    { key: "tertiary", label: "Monthly" }
]

function finiteNumber(value) {
    return typeof value === "number" && isFinite(value)
}

function rawValue(object, key) {
    return Object.prototype.hasOwnProperty.call(object, key) ? object[key] : null
}

function normalizeWindow(definition, value) {
    if (!value || typeof value !== "object" || value instanceof Array) {
        return null
    }

    return {
        key: definition.key,
        label: definition.label,
        usedPercent: finiteNumber(value.usedPercent) ? value.usedPercent : null,
        resetsAt: rawValue(value, "resetsAt"),
        resetDescription: rawValue(value, "resetDescription")
    }
}

function normalizeProvider(entry) {
    var usage = entry.usage && typeof entry.usage === "object" && !(entry.usage instanceof Array)
        ? entry.usage
        : {}
    var windows = []

    for (var i = 0; i < windowDefinitions.length; i++) {
        var definition = windowDefinitions[i]
        var window = normalizeWindow(definition, usage[definition.key])
        if (window !== null) {
            windows.push(window)
        }
    }

    return {
        provider: rawValue(entry, "provider"),
        source: rawValue(entry, "source"),
        windows: windows
    }
}

function normalize(payload) {
    var entries = payload instanceof Array ? payload : [payload]
    var providers = []
    var errors = []

    for (var i = 0; i < entries.length; i++) {
        var entry = entries[i]
        if (!entry || typeof entry !== "object" || entry instanceof Array) {
            continue
        }

        if (entry.error !== undefined && entry.error !== null) {
            errors.push({
                provider: rawValue(entry, "provider"),
                source: rawValue(entry, "source"),
                error: entry.error
            })
            continue
        }

        providers.push(normalizeProvider(entry))
    }

    return {
        providers: providers,
        errors: errors
    }
}

function selectCompact(providers) {
    var best = null
    var rows = providers instanceof Array ? providers : []

    for (var providerIndex = 0; providerIndex < rows.length; providerIndex++) {
        var provider = rows[providerIndex]
        if (!provider || !(provider.windows instanceof Array)) {
            continue
        }

        for (var windowIndex = 0; windowIndex < provider.windows.length; windowIndex++) {
            var window = provider.windows[windowIndex]
            if (!window || !finiteNumber(window.usedPercent)) {
                continue
            }

            if (best === null || window.usedPercent > best.usedPercent) {
                best = {
                    provider: provider,
                    window: window,
                    usedPercent: window.usedPercent
                }
            }
        }
    }

    return best
}
