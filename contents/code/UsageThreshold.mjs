export var WARN_AT = 70            // inclusive lower bound of "warn"
export var CRITICAL_AT = 90        // inclusive lower bound of "critical"
export var EXHAUSTED_AT = 100      // inclusive lower bound of "exhausted"
export var LEVEL_NONE = ""         // non-finite or absent usedPercent
export var LEVEL_OK = "ok"
export var LEVEL_WARN = "warn"
export var LEVEL_CRITICAL = "critical"
export var LEVEL_EXHAUSTED = "exhausted"

export function finiteNumber(value) {
    return typeof value === "number" && isFinite(value)
}

// any -> "" | "ok" | "warn" | "critical" | "exhausted". Bounds are
// inclusive-lower / exclusive-upper; values are classified, never clamped.
export function level(usedPercent) {
    if (!finiteNumber(usedPercent)) {
        return LEVEL_NONE
    }
    if (usedPercent >= EXHAUSTED_AT) {
        return LEVEL_EXHAUSTED
    }
    if (usedPercent >= CRITICAL_AT) {
        return LEVEL_CRITICAL
    }
    if (usedPercent >= WARN_AT) {
        return LEVEL_WARN
    }
    return LEVEL_OK
}

// string -> bool: warn, critical, or exhausted
export function isRisk(levelValue) {
    return levelValue === LEVEL_WARN || levelValue === LEVEL_CRITICAL || levelValue === LEVEL_EXHAUSTED
}
