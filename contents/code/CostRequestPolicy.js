.pragma library

var supportedProviders = ["codex", "claude"]

function isSupportedProvider(provider) {
    return supportedProviders.indexOf(provider) !== -1
}

// Decides whether CostController.request(provider, usageGeneration) should be
// called for the current selection/usage state. Selecting "All" or an
// unsupported provider never starts cost work; a supported provider only
// requests when it has no snapshot for the current usage generation yet.
function shouldRequestCost(isAllSelected, provider, usageGeneration, hasSnapshot) {
    if (isAllSelected || typeof provider !== "string" || !isSupportedProvider(provider)) {
        return false
    }
    if (typeof usageGeneration !== "number" || usageGeneration <= 0) {
        return false
    }
    return !hasSnapshot
}
