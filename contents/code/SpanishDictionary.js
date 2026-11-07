.pragma library

/**
 * Static Spanish dictionary for KodexBar Plasma localization.
 */

var DICTIONARY = {
    // Windows
    "Session": "Sesión",
    "Weekly": "Semanal",
    "Monthly": "Mensual",
    "Automatic": "Automático",
    "All": "Todos",
    "Overview": "General",
    "Overview of all providers": "Vista general de todos los proveedores",
    "Show compact summary for all providers": "Mostrar resumen compacto de todos los proveedores",

    // Usage & Quota
    "%1% used": "%1% usado",
    "%1% remaining": "%1% restante",
    "Reset: %1": "Reinicio: %1",
    "Resets in %1": "Se reinicia en %1",
    "Quota exhausted": "Cuota agotada",
    "Critical usage": "Uso crítico",
    "Elevated usage": "Uso elevado",
    "No usage data available": "No hay datos de uso disponibles",
    "Loading": "Cargando",
    "Loading usage…": "Cargando uso…",
    "Idle": "Inactivo",
    "Ready": "Listo",
    "Error": "Error",
    "No data": "Sin datos",
    "Provider": "Proveedor",

    // Pace & status
    "runs until reset": "Dura hasta el reinicio",
    "on track": "A buen ritmo",

    // Reset credits
    "Reset credits": "Créditos de reinicio de límite",
    "Reset credits available: %1": "Créditos de reinicio disponibles: %1",
    "Show reset credit expirations": "Mostrar vencimientos de créditos",
    "Hide reset credit expirations": "Ocultar vencimientos de créditos",
    "Collapse reset credit expirations": "Colapsar vencimientos de créditos",
    "Expand reset credit expirations": "Expandir vencimientos de créditos",
    "Expires: %1": "Vence: %1",
    "1 credit available": "1 reinicio disponible",
    "%1 credits available": "%1 reinicios disponibles",
    "Next expires in %1": "El próximo vence en %1",
    "Expires in %1": "Vence en %1",
    "Credits remaining": "Créditos",
    "0 remaining": "0 restantes",
    "%1 remaining": "%1 restantes",

    // Cost & Tokens
    "source: local": "origen: local",
    "Cost": "Costo",
    "Today": "Hoy",
    "Last 30 days": "Últimos 30 días",
    "Local token-cost estimate": "Estimado desde los logs locales",
    "Last 30 days cost": "Costo de los últimos 30 días",
    "Last 30 days tokens": "Tokens de los últimos 30 días",
    "Recent tokens": "Tokens más recientes",
    "Primary model: %1": "Modelo principal: %1",
    "Session cost": "Hoy",
    "Session tokens": "Tokens más recientes",
    "30-day cost": "Costo de los últimos 30 días",
    "30-day tokens": "Tokens de los últimos 30 días",

    // Relative timestamps
    "Updated just now": "Actualizado ahora",
    "Updated 1 minute ago": "Actualizado hace 1 minuto",
    "Updated %1 minutes ago": "Actualizado hace %1 minutos",
    "Updated 1 hour ago": "Actualizado hace 1 hora",
    "Updated %1 hours ago": "Actualizado hace %1 horas",
    "Updated 1 day ago": "Actualizado hace 1 día",
    "Updated %1 days ago": "Actualizado hace %1 días",

    // Chrome & actions
    "Refresh": "Actualizar",
    "Configure...": "Configurar...",
    "Configure": "Configurar",
    "Refresh usage": "Actualizar uso",
    "Open details": "Abrir detalles",
    "Ready": "Listo",
    "Updating...": "Actualizando...",
    "Refreshing...": "Actualizando...",
    "Timed out": "Tiempo agotado",

    // Settings
    "Panel icon:": "Icono del panel:",
    "Colorize panel icon with provider accent": "Colorear icono del panel con el acento del proveedor",
    "Pinned provider:": "Proveedor fijado:",
    "All providers (free cycle)": "Todos los proveedores (ciclo libre)",
    "Panel display:": "Visualización en el panel:",
    "Icon only": "Solo icono",
    "Icon and percentage": "Icono y porcentaje",
    "Icon, name, and percentage": "Icono, nombre y porcentaje",
    "Provider order:": "Orden de proveedores:",
    "Move up": "Subir",
    "Move down": "Bajar"
}

function translateTerm(term) {
    if (!term || typeof term !== "string") {
        return term
    }
    return Object.prototype.hasOwnProperty.call(DICTIONARY, term) ? DICTIONARY[term] : term
}

/**
 * Translates dynamic duration strings such as "Resets in 2h 53m", "2 hours, 20 minutes", "tomorrow, 12:45 AM"
 */
function translateDuration(text) {
    if (typeof text !== "string" || text.length === 0) {
        return text
    }
    var result = text
    // Replace "Resets in " or "refresh in "
    result = result.replace(/^(Resets in|refresh in)\s+/i, "Se reinicia en ")
    result = result.replace(/^Reset:\s+/i, "Reinicio: ")
    // Translate "runs until reset"
    result = result.replace(/runs until reset/i, "Dura hasta el reinicio")
    // Translate "on track"
    result = result.replace(/on track/i, "A buen ritmo")
    // Words
    result = result.replace(/\bhours\b/g, "horas")
    result = result.replace(/\bhour\b/g, "hora")
    result = result.replace(/\bminutes\b/g, "minutos")
    result = result.replace(/\bminute\b/g, "minuto")
    result = result.replace(/\bdays\b/g, "días")
    result = result.replace(/\bday\b/g, "día")
    result = result.replace(/\btomorrow\b/gi, "mañana")
    result = result.replace(/\s+at\s+/g, " a las ")
    // Months
    result = result.replace(/\bJan\b/g, "Ene")
    result = result.replace(/\bApr\b/g, "Abr")
    result = result.replace(/\bAug\b/g, "Ago")
    result = result.replace(/\bDec\b/g, "Dic")
    // Format duration units: "2h 53m" -> "2 h 53 min", "5d 4h" -> "5 d 4 h"
    result = result.replace(/(\d+)\s*d\b/g, "$1 d")
    result = result.replace(/(\d+)\s*h\b/g, "$1 h")
    result = result.replace(/(\d+)\s*m\b/g, "$1 min")
    return result
}

/**
 * Normalizes compact CLI duration units: "1h 57m" -> "1 h 57 min", "3d 22h" -> "3 d 22 h"
 */
function formatDurationUnits(duration) {
    var normalized = duration
    normalized = normalized.replace(/(\d+)\s*d\b/g, "$1 d")
    normalized = normalized.replace(/(\d+)\s*h\b/g, "$1 h")
    normalized = normalized.replace(/(\d+)\s*m\b/g, "$1 min")
    return normalized
}

/**
 * Translates pace summary text such as "43% in reserve | Expected 75% used | Lasts until reset"
 */
function translatePace(text) {
    if (typeof text !== "string" || text.length === 0) {
        return text
    }
    var result = text
    result = result.replace(/\bin reserve\b/gi, "en reserva")
    result = result.replace(/\bin deficit\b/gi, "en déficit")
    result = result.replace(/Expected\s+(\d+)%\s+used/gi, "Uso esperado $1%")
    result = result.replace(/\bLasts until reset\b/gi, "Dura hasta el reinicio")
    result = result.replace(/\bOn pace\b/gi, "A buen ritmo")
    result = result.replace(/\bheadroom\b/gi, "margen")
    result = result.replace(/Projected empty in\s+([^|]+)/gi, function (match, duration) {
        return "Se agota en " + formatDurationUnits(duration.replace(/\s+$/, ""))
    })
    result = result.replace(/Runs out in\s+([^|]+)/gi, function (match, duration) {
        return "Se agota en " + formatDurationUnits(duration.replace(/\s+$/, ""))
    })
    result = result.replace(/\bRuns out tomorrow\b/gi, "Se agota mañana")
    return result
}
