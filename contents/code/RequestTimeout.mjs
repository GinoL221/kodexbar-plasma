export var DEFAULT_SECONDS = 60
export var MIN_SECONDS = 30
export var MAX_SECONDS = 600

export function parse(value) {
    return typeof value === "number"
        && isFinite(value)
        && Math.floor(value) === value
        && value >= MIN_SECONDS
        && value <= MAX_SECONDS
        ? value
        : null
}

export function secondsOrDefault(value) {
    var parsed = parse(value)
    return parsed === null ? DEFAULT_SECONDS : parsed
}

export function millisecondsOrDefault(value) {
    return secondsOrDefault(value) * 1000
}
