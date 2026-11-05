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

function save(localStorageModule, providers, dbName) {
    var db, payload, savedAt
    if (!Array.isArray(providers) || providers.length === 0) {
        return false
    }
    db = openDatabase(localStorageModule, dbName)
    if (!db) {
        return false
    }
    payload = JSON.stringify(providers)
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
