.pragma library

var windowDefinitions = [
    { key: "primary", label: "Session" },
    { key: "secondary", label: "Weekly" },
    { key: "tertiary", label: "Monthly" }
]

function finiteNumber(value) {
    return typeof value === "number" && isFinite(value)
}

function isUsableWindow(window) {
    return window && finiteNumber(window.usedPercent)
}

function rawValue(object, key) {
    return Object.prototype.hasOwnProperty.call(object, key) ? object[key] : null
}

function cleanResetDescription(desc) {
    if (typeof desc !== "string") {
        return desc
    }
    var match = desc.match(/refresh in ([^.]+)/i)
    if (match) {
        return "Resets in " + match[1].trim()
    }
    return desc
}

function normalizeWindow(definition, value) {
    if (!value || typeof value !== "object" || value instanceof Array) {
        return null
    }

    var desc = rawValue(value, "resetDescription")
    return {
        key: definition.key,
        label: definition.label,
        usedPercent: finiteNumber(value.usedPercent) ? Math.round(value.usedPercent) : null,
        resetsAt: rawValue(value, "resetsAt"),
        resetDescription: cleanResetDescription(desc)
    }
}

function findExtraWindow(extraRateWindows, idSubstring) {
    if (!(extraRateWindows instanceof Array)) {
        return null
    }
    for (var i = 0; i < extraRateWindows.length; i++) {
        var extra = extraRateWindows[i]
        if (extra && typeof extra.id === "string" && extra.id.indexOf(idSubstring) !== -1 && extra.window) {
            return extra.window
        }
    }
    return null
}

function customWindowLabel(rateWindowLabels, key) {
    if (!rateWindowLabels || typeof rateWindowLabels !== "object" || rateWindowLabels instanceof Array) {
        return null
    }
    var label = rateWindowLabels[key]
    if (typeof label !== "string" || label.trim().length === 0) {
        return null
    }
    return label.trim()
}

function normalizeProvider(entry) {
    var usage = entry.usage && typeof entry.usage === "object" && !(entry.usage instanceof Array)
        ? entry.usage
        : {}
    var windows = []
    var isAntigravity = entry.provider === "antigravity"
    var extras = usage.extraRateWindows instanceof Array ? usage.extraRateWindows : []

    if (isAntigravity && extras.length > 0) {
        var geminiSession = findExtraWindow(extras, "gemini-5h") || usage.primary
        var sessionWin = normalizeWindow({ key: "primary", label: "Session" }, geminiSession)
        if (sessionWin !== null) {
            windows.push(sessionWin)
        }

        var geminiWeekly = findExtraWindow(extras, "gemini-weekly") || usage.secondary
        var weeklyWin = normalizeWindow({ key: "secondary", label: "Weekly" }, geminiWeekly)
        if (weeklyWin !== null) {
            windows.push(weeklyWin)
        }

        var geminiArgon = findExtraWindow(extras, "gemini-argon") || usage.tertiary
        var argonWin = normalizeWindow({ key: "tertiary", label: "Argon" }, geminiArgon)
        if (argonWin !== null) {
            windows.push(argonWin)
        }

        for (var j = 0; j < extras.length; j++) {
            var extra = extras[j]
            if (extra && extra.window && typeof extra.id === "string") {
                if (extra.id.indexOf("gemini-5h") === -1 &&
                    extra.id.indexOf("gemini-weekly") === -1 &&
                    extra.id.indexOf("gemini-argon") === -1) {
                    var extraWin = normalizeWindow({ key: extra.id, label: extra.title || "Claude/GPT" }, extra.window)
                    if (extraWin !== null) {
                        windows.push(extraWin)
                    }
                }
            }
        }
    } else {
        for (var i = 0; i < windowDefinitions.length; i++) {
            var definition = windowDefinitions[i]
            var customLabel = customWindowLabel(entry.rateWindowLabels, definition.key)
            if (customLabel !== null) {
                definition = { key: definition.key, label: customLabel }
            }
            var window = normalizeWindow(definition, usage[definition.key])
            if (window !== null) {
                windows.push(window)
            }
        }

        for (var k = 0; k < extras.length; k++) {
            var extra = extras[k]
            if (extra && extra.window && typeof extra.id === "string") {
                var label = extra.title || extra.id
                if (extra.id === "claude-weekly-scoped-fable"
                    || (typeof extra.title === "string" && extra.title.toLowerCase() === "fable only")) {
                    label = "Fable"
                }
                var customExtraLabel = customWindowLabel(entry.rateWindowLabels, extra.id)
                if (customExtraLabel !== null) {
                    label = customExtraLabel
                }
                var extraWin = normalizeWindow({ key: extra.id, label: label }, extra.window)
                if (extraWin !== null) {
                    windows.push(extraWin)
                }
            }
        }
    }

    // raw is a live reference to the parsed CLI entry, never a copy: normalized
    // snapshots are read-only, and a JSON round-trip would destroy Infinity/NaN.
    return {
        provider: rawValue(entry, "provider"),
        source: rawValue(entry, "source"),
        windows: windows,
        raw: entry
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

function firstFiniteWindow(windows) {
    var rows = windows instanceof Array ? windows : []

    for (var i = 0; i < rows.length; i++) {
        var window = rows[i]
        if (isUsableWindow(window)) {
            return window
        }
    }

    return null
}

var preferredWindowKeys = {
    "session": "primary",
    "weekly": "secondary",
    "monthly": "tertiary"
}

function definitionForPreferred(preferredKey) {
    if (typeof preferredKey !== "string"
        || !Object.prototype.hasOwnProperty.call(preferredWindowKeys, preferredKey)) {
        return null
    }
    var definitionKey = preferredWindowKeys[preferredKey]
    for (var i = 0; i < windowDefinitions.length; i++) {
        if (windowDefinitions[i].key === definitionKey) {
            return windowDefinitions[i]
        }
    }
    return null
}

function matchesDefinition(window, definition) {
    return window.key === definition.key || window.label === definition.label
}

function preferredFiniteWindow(windows, definition) {
    var rows = windows instanceof Array ? windows : []
    for (var i = 0; i < rows.length; i++) {
        if (isUsableWindow(rows[i]) && matchesDefinition(rows[i], definition)) {
            return rows[i]
        }
    }
    return null
}

function selectRepresentative(windows, preferredKey) {
    var definition = definitionForPreferred(preferredKey)
    if (definition !== null) {
        var preferred = preferredFiniteWindow(windows, definition)
        if (preferred !== null) {
            return preferred
        }
    }
    return firstFiniteWindow(windows)
}

// Overview body: every finite Session/Weekly/Monthly window, in that order.
// Providers like opencodego often expose all three; dropping Monthly when
// Session/Weekly exist hid real data. Empty when none are finite.
function selectOverviewWindows(windows) {
    var result = []
    for (var i = 0; i < windowDefinitions.length; i++) {
        var window = preferredFiniteWindow(windows, windowDefinitions[i])
        if (window !== null && result.indexOf(window) === -1) {
            result.push(window)
        }
    }
    return result
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
            if (!isUsableWindow(window)) {
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
