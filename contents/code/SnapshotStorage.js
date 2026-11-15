.pragma library

// Persistent storage for the latest committed usage snapshot.
// Uses QtQuick.LocalStorage (SQLite) in the user's local XDG data path.
// Pure helper: takes the LocalStorage module reference from callers and
// degrades cleanly if the database is inaccessible, empty, or unparseable.

var DEFAULT_DB_NAME = "KodexBar"
var DB_VERSION = "1.0"
var DB_DESCRIPTION = "KodexBar Plasma Snapshot Storage"
var DB_ESTIMATED_SIZE = 1000000

function openDatabase(localStorageModule, dbName) {
    var name
    if (!localStorageModule || typeof localStorageModule.openDatabaseSync !== "function") {
        return null
    }
    name = typeof dbName === "string" && dbName.length > 0 ? dbName : DEFAULT_DB_NAME
    try {
        return localStorageModule.openDatabaseSync(name, DB_VERSION, DB_DESCRIPTION, DB_ESTIMATED_SIZE)
    } catch (openError) {
        if (openError) {
            return null
        }
        return null
    }
}

function cloneWithoutIdentityPii(obj) {
    if (!obj || typeof obj !== "object" || Array.isArray(obj)) {
        return obj
    }
    var copy = {}
    for (var key in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, key)) {
            if (key === "accountEmail" || key === "accountOrganization") {
                continue
            }
            copy[key] = obj[key]
        }
    }
    return copy
}

function sanitizeProviderForStorage(provider) {
    if (!provider || typeof provider !== "object") {
        return provider
    }
    var sanitized = {}
    for (var k in provider) {
        if (Object.prototype.hasOwnProperty.call(provider, k)) {
            sanitized[k] = provider[k]
        }
    }
    if (provider.raw && typeof provider.raw === "object" && !Array.isArray(provider.raw)) {
        var rawCopy = cloneWithoutIdentityPii(provider.raw)
        if (rawCopy.identity && typeof rawCopy.identity === "object" && !Array.isArray(rawCopy.identity)) {
            rawCopy.identity = cloneWithoutIdentityPii(rawCopy.identity)
        }
        if (rawCopy.usage && typeof rawCopy.usage === "object" && !Array.isArray(rawCopy.usage)) {
            var usageCopy = cloneWithoutIdentityPii(rawCopy.usage)
            if (usageCopy.identity && typeof usageCopy.identity === "object" && !Array.isArray(usageCopy.identity)) {
                usageCopy.identity = cloneWithoutIdentityPii(usageCopy.identity)
            }
            rawCopy.usage = usageCopy
        }
        sanitized.raw = rawCopy
    }
    return sanitized
}

function save(localStorageModule, providers, dbName) {
    var db, payload, savedAt, sanitizedProviders, i
    if (!Array.isArray(providers) || providers.length === 0) {
        return false
    }
    db = openDatabase(localStorageModule, dbName)
    if (!db) {
        return false
    }
    sanitizedProviders = []
    for (i = 0; i < providers.length; i++) {
        sanitizedProviders.push(sanitizeProviderForStorage(providers[i]))
    }
    payload = JSON.stringify(sanitizedProviders)
    savedAt = Date.now()
    try {
        db.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS snapshots (id TEXT PRIMARY KEY, payload TEXT, saved_at INTEGER)")
            tx.executeSql("INSERT OR REPLACE INTO snapshots (id, payload, saved_at) VALUES (?, ?, ?)",
                ["latest", payload, savedAt])
        })
        return true
    } catch (saveError) {
        if (saveError) {
            return false
        }
        return false
    }
}

function isValidProvider(provider) {
    return provider !== null
        && typeof provider === "object"
        && typeof provider.provider === "string"
        && Array.isArray(provider.windows)
}

function load(localStorageModule, dbName) {
    var db, providers, readFn
    db = openDatabase(localStorageModule, dbName)
    if (!db) {
        return []
    }
    providers = []
    readFn = typeof db.readTransaction === "function" ? db.readTransaction : db.transaction
    try {
        readFn.call(db, function(tx) {
            var rs, rawPayload, parsed, i
            rs = tx.executeSql("SELECT payload FROM snapshots WHERE id = ?", ["latest"])
            if (rs && rs.rows && rs.rows.length > 0) {
                rawPayload = rs.rows.item(0).payload
                if (typeof rawPayload === "string" && rawPayload.length > 0) {
                    parsed = JSON.parse(rawPayload)
                    if (Array.isArray(parsed)) {
                        for (i = 0; i < parsed.length; i++) {
                            if (isValidProvider(parsed[i])) {
                                providers.push(parsed[i])
                            }
                        }
                    }
                }
            }
        })
    } catch (loadError) {
        if (loadError) {
            return []
        }
        return []
    }
    return providers
}

function clear(localStorageModule, dbName) {
    var db
    db = openDatabase(localStorageModule, dbName)
    if (!db) {
        return false
    }
    try {
        db.transaction(function(tx) {
            tx.executeSql("DELETE FROM snapshots WHERE id = ?", ["latest"])
        })
        return true
    } catch (clearError) {
        if (clearError) {
            return false
        }
        return false
    }
}

function saveCost(localStorageModule, provider, costRecord, dbName) {
    if (!costRecord || typeof costRecord !== "object" || typeof provider !== "string" || provider.length === 0) {
        return false
    }
    var db = openDatabase(localStorageModule, dbName)
    if (!db) {
        return false
    }
    var payload = JSON.stringify(costRecord)
    var savedAt = Date.now()
    var id = "cost:" + provider
    try {
        db.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS snapshots (id TEXT PRIMARY KEY, payload TEXT, saved_at INTEGER)")
            tx.executeSql("INSERT OR REPLACE INTO snapshots (id, payload, saved_at) VALUES (?, ?, ?)",
                [id, payload, savedAt])
        })
        return true
    } catch (saveError) {
        return false
    }
}

function isFiniteNonNegative(value) {
    return typeof value === "number" && isFinite(value) && value >= 0
}

function isValidCostRecord(record, expectedProvider) {
    return record !== null
        && typeof record === "object"
        && !Array.isArray(record)
        && record.provider === expectedProvider
        && isFiniteNonNegative(record.sessionCostUSD)
        && isFiniteNonNegative(record.sessionTokens)
        && isFiniteNonNegative(record.last30DaysCostUSD)
        && isFiniteNonNegative(record.last30DaysTokens)
}

// Returns { record, savedAt } for the provider's stored cost, or null. The
// save time lets several widget instances share one CLI scan.
function loadCostEntry(localStorageModule, provider, dbName) {
    if (typeof provider !== "string" || provider.length === 0) {
        return null
    }
    var db = openDatabase(localStorageModule, dbName)
    if (!db) {
        return null
    }
    var id = "cost:" + provider
    var result = null
    var readFn = typeof db.readTransaction === "function" ? db.readTransaction : db.transaction
    try {
        readFn.call(db, function(tx) {
            var rs = tx.executeSql("SELECT payload, saved_at FROM snapshots WHERE id = ?", [id])
            if (rs && rs.rows && rs.rows.length > 0) {
                var row = rs.rows.item(0)
                if (typeof row.payload === "string" && row.payload.length > 0) {
                    var parsed = JSON.parse(row.payload)
                    if (isValidCostRecord(parsed, provider)) {
                        result = { record: parsed, savedAt: Number(row.saved_at) }
                    }
                }
            }
        })
    } catch (loadError) {
        return null
    }
    return result
}

function loadCost(localStorageModule, provider, dbName) {
    var entry = loadCostEntry(localStorageModule, provider, dbName)
    return entry !== null ? entry.record : null
}

function loadAllCosts(localStorageModule, dbName) {
    var db = openDatabase(localStorageModule, dbName)
    if (!db) {
        return {}
    }
    var costs = {}
    var readFn = typeof db.readTransaction === "function" ? db.readTransaction : db.transaction
    try {
        readFn.call(db, function(tx) {
            var rs = tx.executeSql("SELECT id, payload FROM snapshots WHERE id LIKE 'cost:%'")
            if (rs && rs.rows) {
                for (var i = 0; i < rs.rows.length; i++) {
                    var item = rs.rows.item(i)
                    if (item && typeof item.id === "string" && typeof item.payload === "string") {
                        var prov = item.id.substring(5)
                        try {
                            var parsed = JSON.parse(item.payload)
                            if (isValidCostRecord(parsed, prov)) {
                                costs[prov] = parsed
                            }
                        } catch (e) {}
                    }
                }
            }
        })
    } catch (loadError) {
        return {}
    }
    return costs
}
