.pragma library

var DEFAULT_KEY = "automatic"
var VALID_KEYS = ["automatic", "session", "weekly", "monthly"]

function parse(value) {
    if (typeof value !== "string") {
        return null
    }
    for (var i = 0; i < VALID_KEYS.length; i++) {
        if (VALID_KEYS[i] === value) {
            return value
        }
    }
    return null
}

function keyOrDefault(value) {
    var parsed = parse(value)
    return parsed === null ? DEFAULT_KEY : parsed
}
