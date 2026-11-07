.pragma library

var supportedProviders = ["claude", "codex"]

function isSupportedProvider(provider) {
    return supportedProviders.indexOf(provider) !== -1
}

// Providers whose cost an instance should prefetch in the background. A
// pinned instance only ever displays its pinned provider, so it prefetches
// that provider alone (or nothing when the pinned provider has no cost
// support); an unpinned instance prefetches every visible supported provider.
function prefetchTargets(pinnedProvider, visibleProviderIds) {
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
function shouldRequestCost(isAllSelected, provider, usageGeneration, hasSnapshot) {
    if (isAllSelected || typeof provider !== "string" || !isSupportedProvider(provider)) {
        return false
    }
    if (typeof usageGeneration !== "number" || usageGeneration <= 0) {
        return false
    }
    return !hasSnapshot
}
