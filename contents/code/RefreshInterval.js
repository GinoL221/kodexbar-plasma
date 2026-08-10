.pragma library

function parse(value) {
    return typeof value === "number"
        && isFinite(value)
        && Math.floor(value) === value
        && value >= 1
        && value <= 3600
        ? value
        : null
}

function valueOrDefault(value, fallback) {
    var parsed = parse(value)
    return parsed === null ? fallback : parsed
}

function correctionGuidance(value) {
    return parse(value) === null
        ? "Enter a whole number from 1 to 3600 seconds. Invalid values are restored to the configured default."
        : ""
}
