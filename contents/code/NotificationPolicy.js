.pragma library

// Policy for user-facing quota threshold notifications in KDE Plasma.
// Pure helper: decides when quota transitions require an alert (escalation to
// critical/exhausted levels or entering rate-limit backoff) and constructs
// human-scannable notification payloads without spamming across steady polls.

function levelRank(level) {
    if (level === "exhausted") {
        return 4
    }
    if (level === "critical") {
        return 3
    }
    if (level === "warn") {
        return 2
    }
    if (level === "ok") {
        return 1
    }
    return 0
}

function shouldNotifyQuota(previousLevel, currentLevel) {
    var prevRank = levelRank(previousLevel)
    var currRank = levelRank(currentLevel)
    // Only notify on upward escalation into critical (>=90%) or exhausted (>=100%)
    if (currRank < 3) {
        return false
    }
    return currRank > prevRank
}

function shouldNotifyRateLimit(previousConsecutive, currentConsecutive) {
    var prev = typeof previousConsecutive === "number" && isFinite(previousConsecutive) ? previousConsecutive : 0
    var curr = typeof currentConsecutive === "number" && isFinite(currentConsecutive) ? currentConsecutive : 0
    return prev === 0 && curr === 1
}

function buildQuotaNotification(providerDisplayName, windowLabel, usedPercent, resetDescription) {
    var isExhausted, title, text, resetSuffix, percent
    percent = Math.round(usedPercent)
    isExhausted = percent >= 100
    resetSuffix = typeof resetDescription === "string" && resetDescription.length > 0
        ? " (resets " + resetDescription + ")" : ""

    if (isExhausted) {
        title = providerDisplayName + ": Quota exhausted"
        text = windowLabel + " quota reached 100%" + resetSuffix + "."
    } else {
        title = providerDisplayName + ": 90% quota reached"
        text = windowLabel + " quota is at " + percent + "%" + resetSuffix + "."
    }

    return {
        title: title,
        text: text,
        iconName: isExhausted ? "dialog-warning" : "dialog-information",
        urgency: isExhausted ? "critical" : "normal"
    }
}

function buildRateLimitNotification(providerDisplayName, retryMinutes) {
    var minutes = typeof retryMinutes === "number" && isFinite(retryMinutes) && retryMinutes > 0
        ? Math.round(retryMinutes) : 2
    return {
        title: providerDisplayName + ": Rate limit exceeded",
        text: "Requests throttled by the provider. Pausing queries for " + minutes + " minutes.",
        iconName: "dialog-warning",
        urgency: "normal"
    }
}

function evaluateTransitions(previousState, providers, rateLimitedIds, consecutiveRateLimits, retryMinutes, displayNameFn) {
    var prev = previousState && typeof previousState === "object" ? previousState : {}
    var next = {}
    var notifications = []
    var providerList = Array.isArray(providers) ? providers : []
    var throttledIds = Array.isArray(rateLimitedIds) ? rateLimitedIds : []
    var i, j, providerObj, pId, pName, windows, win, key, prevLevel, currLevel, pct
    var prevConsecutive, currConsecutive, stateKey

    // Carry over previous tracking state so transient poll failures or missing windows
    // do not erase baseline levels and trigger duplicate alerts on recovery.
    for (stateKey in prev) {
        if (Object.prototype.hasOwnProperty.call(prev, stateKey)) {
            next[stateKey] = prev[stateKey]
        }
    }

    var getName = typeof displayNameFn === "function" ? displayNameFn : function(id) { return id }

    // 1. Quota window transitions
    for (i = 0; i < providerList.length; i++) {
        providerObj = providerList[i]
        if (!providerObj || typeof providerObj !== "object" || typeof providerObj.provider !== "string") {
            continue
        }
        pId = providerObj.provider
        pName = getName(pId)
        windows = Array.isArray(providerObj.windows) ? providerObj.windows : []

        for (j = 0; j < windows.length; j++) {
            win = windows[j]
            if (!win || typeof win !== "object") {
                continue
            }
            pct = win.usedPercent
            if (typeof pct !== "number" || !isFinite(pct)) {
                continue
            }

            key = pId + ":" + (win.key || win.label || j)
            prevLevel = prev[key] || ""

            if (pct >= 100) {
                currLevel = "exhausted"
            } else if (pct >= 90) {
                currLevel = "critical"
            } else if (pct >= 70) {
                currLevel = "warn"
            } else {
                currLevel = "ok"
            }
            next[key] = currLevel

            if (shouldNotifyQuota(prevLevel, currLevel)) {
                notifications.push(buildQuotaNotification(pName, win.label || "Usage", pct, win.resetDescription))
            }
        }
    }

    // 2. Rate-limit transitions
    prevConsecutive = typeof prev["_consecutiveRateLimits"] === "number" ? prev["_consecutiveRateLimits"] : 0
    currConsecutive = typeof consecutiveRateLimits === "number" ? consecutiveRateLimits : 0
    next["_consecutiveRateLimits"] = currConsecutive

    if (shouldNotifyRateLimit(prevConsecutive, currConsecutive)) {
        for (i = 0; i < throttledIds.length; i++) {
            pId = throttledIds[i]
            if (typeof pId === "string" && pId.length > 0) {
                notifications.push(buildRateLimitNotification(getName(pId), retryMinutes))
            }
        }
    }

    return {
        notifications: notifications,
        nextState: next
    }
}
