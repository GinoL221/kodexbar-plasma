.pragma library

/**
 * Pure policy for parsing excluded provider IDs, filtering provider lists,
 * and applying custom user-defined provider ordering.
 */

function parseExcluded(rawString) {
    if (typeof rawString !== "string" || rawString.trim().length === 0) {
        return []
    }
    var parts = rawString.split(",")
    var result = []
    for (var i = 0; i < parts.length; i++) {
        var token = parts[i].trim().toLowerCase()
        if (token.length > 0 && result.indexOf(token) === -1) {
            result.push(token)
        }
    }
    return result
}

function parseOrder(rawString) {
    return parseExcluded(rawString)
}

function serializeOrder(orderList) {
    if (!Array.isArray(orderList) || orderList.length === 0) {
        return ""
    }
    var clean = []
    for (var i = 0; i < orderList.length; i++) {
        var item = typeof orderList[i] === "string" ? orderList[i].trim().toLowerCase() : ""
        if (item.length > 0 && clean.indexOf(item) === -1) {
            clean.push(item)
        }
    }
    return clean.join(", ")
}

function isVisible(providerId, excludedList) {
    if (!providerId || typeof providerId !== "string") {
        return false
    }
    var list = Array.isArray(excludedList) ? excludedList : []
    return list.indexOf(providerId.toLowerCase()) === -1
}

function filterProviders(providers, excludedInput) {
    var list = Array.isArray(providers) ? providers : []
    var excluded = Array.isArray(excludedInput) ? excludedInput : parseExcluded(excludedInput)
    if (excluded.length === 0) {
        return list
    }
    var visible = []
    for (var i = 0; i < list.length; i++) {
        var p = list[i]
        if (p && typeof p === "object" && typeof p.provider === "string") {
            if (isVisible(p.provider, excluded)) {
                visible.push(p)
            }
        }
    }
    return visible
}

function sortProviders(providers, orderInput) {
    var list = Array.isArray(providers) ? providers : []
    var order = Array.isArray(orderInput) ? orderInput : parseOrder(orderInput)
    if (order.length === 0 || list.length <= 1) {
        return list
    }
    var byId = {}
    var remaining = []
    for (var i = 0; i < list.length; i++) {
        var p = list[i]
        var id = (p && typeof p === "object" && typeof p.provider === "string")
            ? p.provider.trim().toLowerCase() : ""
        if (id.length > 0 && order.indexOf(id) !== -1 && !Object.prototype.hasOwnProperty.call(byId, id)) {
            byId[id] = p
        } else {
            remaining.push(p)
        }
    }
    var sorted = []
    for (var j = 0; j < order.length; j++) {
        var key = order[j]
        if (Object.prototype.hasOwnProperty.call(byId, key)) {
            sorted.push(byId[key])
        }
    }
    for (var k = 0; k < remaining.length; k++) {
        sorted.push(remaining[k])
    }
    return sorted
}

function filterAndSortProviders(providers, excludedInput, orderInput) {
    return sortProviders(filterProviders(providers, excludedInput), orderInput)
}

function effectiveOrderList(currentIds, orderInput) {
    var order = Array.isArray(orderInput) ? orderInput.slice() : parseOrder(orderInput)
    var current = Array.isArray(currentIds) ? currentIds : []
    var combined = []
    for (var i = 0; i < order.length; i++) {
        var o = typeof order[i] === "string" ? order[i].trim().toLowerCase() : ""
        if (o.length > 0 && combined.indexOf(o) === -1) {
            combined.push(o)
        }
    }
    for (var j = 0; j < current.length; j++) {
        var c = typeof current[j] === "string" ? current[j].trim().toLowerCase() : ""
        if (c.length > 0 && combined.indexOf(c) === -1) {
            combined.push(c)
        }
    }
    return combined
}

function moveProviderInOrder(currentIds, orderInput, providerId, delta) {
    var target = typeof providerId === "string" ? providerId.trim().toLowerCase() : ""
    var step = delta < 0 ? -1 : delta > 0 ? 1 : 0
    var list = effectiveOrderList(currentIds, orderInput)
    if (target.length === 0 || step === 0 || list.length <= 1) {
        return serializeOrder(list)
    }
    var idx = list.indexOf(target)
    if (idx === -1) {
        return serializeOrder(list)
    }
    var nextIdx = idx + step
    if (nextIdx < 0 || nextIdx >= list.length) {
        return serializeOrder(list)
    }
    var temp = list[idx]
    list[idx] = list[nextIdx]
    list[nextIdx] = temp
    return serializeOrder(list)
}
