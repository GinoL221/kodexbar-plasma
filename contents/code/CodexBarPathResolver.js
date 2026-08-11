.pragma library

function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
}

function validateAbsolutePath(path) {
    var value = String(path || "")
    if (value.indexOf("\n") !== -1 || value.indexOf("\r") !== -1) {
        return { valid: false, error: "The CodexBar CLI path cannot contain a line break." }
    }
    value = value.trim()
    if (value.length === 0) {
        return { valid: false, error: "Configure an absolute CodexBar CLI path." }
    }
    if (value.charAt(0) !== "/") {
        return { valid: false, error: "The CodexBar CLI path must be absolute." }
    }
    return { valid: true, error: "", path: value }
}

function pathCheckCommand(path) {
    var validation = validateAbsolutePath(path)
    return validation.valid ? "test -x " + shellQuote(validation.path) : ""
}

function discoveryCommand() {
    return "if [ -n \"${HOME-}\" ] && [ \"${HOME#/}\" != \"$HOME\" ]; then "
        + "candidate=\"$HOME/.local/bin/codexbar\"; if test -x \"$candidate\"; then printf '%s\\n' \"$candidate\"; exit 0; fi; fi; "
        + "for candidate in /usr/local/bin/codexbar /usr/bin/codexbar; do "
        + "if test -x \"$candidate\"; then printf '%s\\n' \"$candidate\"; exit 0; fi; done; "
        + "if [ -n \"${HOMEBREW_PREFIX-}\" ] && [ \"${HOMEBREW_PREFIX#/}\" != \"$HOMEBREW_PREFIX\" ]; then "
        + "candidate=\"$HOMEBREW_PREFIX/bin/codexbar\"; if test -x \"$candidate\"; then printf '%s\\n' \"$candidate\"; exit 0; fi; fi; exit 1"
}
