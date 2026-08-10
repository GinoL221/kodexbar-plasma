.pragma library

var DEFAULT_SECONDS = 60
var MIN_SECONDS = 30
var MAX_SECONDS = 600

function parse(value) {
    return typeof value === "number"
        && isFinite(value)
        && Math.floor(value) === value
        && value >= MIN_SECONDS
        && value <= MAX_SECONDS
        ? value
        : null
}

function secondsOrDefault(value) {
    var parsed = parse(value)
    return parsed === null ? DEFAULT_SECONDS : parsed
}

function millisecondsOrDefault(value) {
    return secondsOrDefault(value) * 1000
}
