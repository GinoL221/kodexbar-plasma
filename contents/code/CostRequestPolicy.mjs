export var supportedProviders = ["claude", "codex", "antigravity", "nan"]

export function isSupportedProvider(provider) {
    return supportedProviders.indexOf(provider) !== -1
}

// Providers whose cost an instance should prefetch in the background. A
// pinned instance only ever displays its pinned provider, so it prefetches
// that provider alone (or nothing when the pinned provider has no cost
// support); an unpinned instance prefetches every visible supported provider.
export function prefetchTargets(pinnedProvider, visibleProviderIds) {
    if (!Array.isArray(visibleProviderIds)) {
        return []
    }
    var candidates = typeof pinnedProvider === "string" && pinnedProvider.length > 0
        ? [pinnedProvider]
        : supportedProviders
    var targets = []
    for (var i = 0; i < candidates.length; i++) {
        if (isSupportedProvider(candidates[i]) && visibleProviderIds.indexOf(candidates[i]) !== -1) {
            targets.push(candidates[i])
        }
    }
    return targets
}

// Decides whether CostController.request(provider, usageGeneration) should be
// called for the current selection/usage state. Selecting "All" or an
// unsupported provider never starts interactive cost work; a supported provider
// requests when it has no fresh snapshot for the current usage generation yet.
export function shouldRequestCost(isAllSelected, provider, usageGeneration, hasSnapshot) {
    if (isAllSelected || typeof provider !== "string" || !isSupportedProvider(provider)) {
        return false
    }
    if (typeof usageGeneration !== "number" || usageGeneration <= 0) {
        return false
    }
    return !hasSnapshot
}

export function parseRemoteHosts(rawHosts) {
    var tokens
    if (Array.isArray(rawHosts)) {
        tokens = rawHosts
    } else if (typeof rawHosts === "string") {
        tokens = rawHosts.split(",")
    } else {
        return []
    }
    var seen = Object.create(null)
    var hosts = []
    for (var i = 0; i < tokens.length; i++) {
        if (typeof tokens[i] !== "string") {
            continue
        }
        var host = tokens[i].trim()
        if (host.length === 0 || host.toLowerCase() === "local") {
            continue
        }
        if (!/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/.test(host)) {
            continue
        }
        if (!seen[host]) {
            seen[host] = true
            hosts.push(host)
        }
    }
    return hosts
}
