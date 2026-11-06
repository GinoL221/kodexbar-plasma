.pragma library

/**
 * Pure policy for cycling active providers via mouse scroll or keyboard.
 */

function nextIndex(currentIndex, delta, totalCount) {
    if (typeof totalCount !== "number" || totalCount <= 1) {
        return 0
    }
    var cur = typeof currentIndex === "number" && isFinite(currentIndex) ? currentIndex : 0
    if (delta > 0) {
        return (cur + 1) % totalCount
    } else if (delta < 0) {
        return (cur - 1 + totalCount) % totalCount
    }
    return cur
}

function buildCycleTargets(providers, displayNameFn) {
    var targets = [
        {
            id: "all",
            name: "All",
            isAll: true,
            providerData: null
        }
    ]
    var list = Array.isArray(providers) ? providers : []
    var getName = typeof displayNameFn === "function" ? displayNameFn : function(id) { return id || "" }

    for (var i = 0; i < list.length; i++) {
        var p = list[i]
        if (p && typeof p === "object" && typeof p.provider === "string" && p.provider.length > 0) {
            targets.push({
                id: p.provider,
                name: getName(p.provider),
                isAll: false,
                providerData: p
            })
        }
    }
    return targets
}

function buildAllSummaryTooltip(providers, preferredWindowKey, selectRepresentativeFn, displayNameFn) {
    var list = Array.isArray(providers) ? providers : []
    var winFn = typeof selectRepresentativeFn === "function" ? selectRepresentativeFn : null
    var getName = typeof displayNameFn === "function" ? displayNameFn : function(id) { return id || "" }
    var lines = []

    for (var i = 0; i < list.length; i++) {
        var p = list[i]
        if (!p || typeof p !== "object" || !Array.isArray(p.windows) || p.windows.length === 0) {
            continue
        }
        var rep = winFn ? winFn(p.windows, preferredWindowKey) : null
        if (rep && typeof rep.usedPercent === "number" && isFinite(rep.usedPercent)) {
            var name = getName(p.provider)
            var pct = Math.round(rep.usedPercent) + "%"
            var winLabel = rep.label ? " (" + rep.label + ")" : ""
            lines.push(name + ": " + pct + winLabel)
        }
    }
    return lines.join("\n")
}

function resolveCycledUsage(targets, index, preferredWindowKey, selectCompactFn, selectRepresentativeFn, displayNameFn) {
    var list = Array.isArray(targets) && targets.length > 0 ? targets : [{ id: "all", name: "All", isAll: true, providerData: null }]
    var safeIdx = (index >= 0 && index < list.length) ? index : 0
    var target = list[safeIdx]

    if (target.isAll) {
        var allProviders = []
        for (var i = 1; i < list.length; i++) {
            if (list[i].providerData) {
                allProviders.push(list[i].providerData)
            }
        }
        var compact = typeof selectCompactFn === "function" ? selectCompactFn(allProviders) : null
        var summaryText = buildAllSummaryTooltip(allProviders, preferredWindowKey, selectRepresentativeFn, displayNameFn)
        return {
            isAll: true,
            targetId: "all",
            targetName: "All",
            selection: compact,
            usedPercent: compact && compact.usedPercent !== undefined ? compact.usedPercent : null,
            label: compact && compact.window && compact.window.label ? compact.window.label : "",
            providerName: compact && compact.provider && compact.provider.provider ? compact.provider.provider : "",
            allSummaryText: summaryText
        }
    }

    var winFn = typeof selectRepresentativeFn === "function" ? selectRepresentativeFn : null
    var repWindow = null
    if (winFn && target.providerData && Array.isArray(target.providerData.windows)) {
        repWindow = winFn(target.providerData.windows, preferredWindowKey)
    }

    return {
        isAll: false,
        targetId: target.id,
        targetName: target.name,
        selection: repWindow ? { provider: target.providerData, window: repWindow } : null,
        usedPercent: repWindow && repWindow.usedPercent !== undefined ? repWindow.usedPercent : null,
        label: repWindow && repWindow.label ? repWindow.label : "",
        providerName: target.name
    }
}
