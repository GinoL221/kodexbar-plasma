.pragma library

/**
 * Triggers the Plasma applet configuration dialog across Plasma 6 versions.
 */
function triggerConfigure(plasmoidObj) {
    if (!plasmoidObj) {
        return false
    }
    try {
        if (typeof plasmoidObj.internalAction === "function") {
            var act = plasmoidObj.internalAction("configure")
            if (act && typeof act.trigger === "function") {
                act.trigger()
                return true
            }
        }
    } catch (_e1) {}

    try {
        if (plasmoidObj.containment && typeof plasmoidObj.containment.configureRequested === "function") {
            plasmoidObj.containment.configureRequested(plasmoidObj)
            return true
        }
    } catch (_e2) {}

    return false
}
