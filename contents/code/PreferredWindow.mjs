export var DEFAULT_KEY = "automatic"
export var VALID_KEYS = ["automatic", "session", "weekly", "monthly"]

export function parse(value) {
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

export function keyOrDefault(value) {
    var parsed = parse(value)
    return parsed === null ? DEFAULT_KEY : parsed
}
