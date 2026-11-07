.pragma library

.import "Translation.js" as Translation

var MONTH_MAP = {
    jan: 0, january: 0,
    feb: 1, february: 1,
    mar: 2, march: 2,
    apr: 3, april: 3,
    may: 4,
    jun: 5, june: 5,
    jul: 6, july: 6,
    aug: 7, august: 7,
    sep: 8, sept: 8, september: 8,
    oct: 9, october: 9,
    nov: 10, november: 10,
    dec: 11, december: 11
}

function parseDuration(text) {
    if (typeof text !== "string") {
        return null
    }
    var s = text.trim()
    s = s.replace(/^(?:resets?\s+in|refresh\s+in)\s+/i, "")
    if (!s) {
        return null
    }

    if (/^<\s*1\s*m(?:in(?:ute)?s?)?$/i.test(s)) {
        return { days: 0, hours: 0, minutes: 0, isLessThanOneMinute: true }
    }

    var dayMatch = s.match(/\b(\d+)\s*(?:d|days?)\b/i)
    var hourMatch = s.match(/\b(\d+)\s*(?:h|hours?)\b/i)
    var minMatch = s.match(/\b(\d+)\s*(?:m|mins?|minutes?)\b/i)

    if (!dayMatch && !hourMatch && !minMatch) {
        return null
    }

    var remainder = s
        .replace(/\b\d+\s*(?:d(?:ays?)?|h(?:ours?)?|m(?:in(?:ute)?s?)?)\b/gi, "")
        .replace(/[\s,]|and/gi, "")
    if (remainder.length > 0) {
        return null
    }

    var days = dayMatch ? parseInt(dayMatch[1], 10) : 0
    var hours = hourMatch ? parseInt(hourMatch[1], 10) : 0
    var minutes = minMatch ? parseInt(minMatch[1], 10) : 0

    return {
        days: days,
        hours: hours,
        minutes: minutes,
        isLessThanOneMinute: false
    }
}

function parseDate(text, nowMs) {
    if (typeof text !== "string") {
        return null
    }
    var s = text.trim()
    var now = new Date(nowMs)

    var tomorrowMatch = s.match(/^tomorrow(?:,\s*|\s+at\s+|\s+)(\d{1,2}):(\d{2})(?::\d{2})?\s*(am|pm)?$/i)
    if (tomorrowMatch) {
        var h = parseInt(tomorrowMatch[1], 10)
        var m = parseInt(tomorrowMatch[2], 10)
        var ampm = tomorrowMatch[3] ? tomorrowMatch[3].toLowerCase() : null
        if (ampm) {
            if (h < 1 || h > 12) {
                return NaN
            }
            if (ampm === "pm" && h < 12) {
                h += 12
            } else if (ampm === "am" && h === 12) {
                h = 0
            }
        } else {
            if (h < 0 || h > 23) {
                return NaN
            }
        }
        if (m < 0 || m > 59) {
            return NaN
        }
        var targetTomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, h, m, 0, 0)
        return targetTomorrow.getTime()
    }

    var dateMatch = s.match(/^([a-z]+)\.?\s+(\d{1,2})(?:st|nd|rd|th)?(?:\s*,?\s*(\d{4}))?(?:(?:,\s*|\s+at\s+|\s+)(\d{1,2}):(\d{2})(?::\d{2})?\s*(am|pm)?)?$/i)
    if (dateMatch) {
        var monthKey = dateMatch[1].toLowerCase()
        if (Object.prototype.hasOwnProperty.call(MONTH_MAP, monthKey)) {
            var month = MONTH_MAP[monthKey]
            var day = parseInt(dateMatch[2], 10)
            if (day < 1 || day > 31) {
                return NaN
            }
            var year = dateMatch[3] ? parseInt(dateMatch[3], 10) : now.getFullYear()
            var hours = 0
            var minutes = 0
            if (dateMatch[4] && dateMatch[5]) {
                hours = parseInt(dateMatch[4], 10)
                minutes = parseInt(dateMatch[5], 10)
                var ampm2 = dateMatch[6] ? dateMatch[6].toLowerCase() : null
                if (ampm2) {
                    if (hours < 1 || hours > 12) {
                        return NaN
                    }
                    if (ampm2 === "pm" && hours < 12) {
                        hours += 12
                    } else if (ampm2 === "am" && hours === 12) {
                        hours = 0
                    }
                } else {
                    if (hours < 0 || hours > 23) {
                        return NaN
                    }
                }
                if (minutes < 0 || minutes > 59) {
                    return NaN
                }
            }
            var target = new Date(year, month, day, hours, minutes, 0, 0)
            if (target.getMonth() !== month || target.getDate() !== day) {
                return NaN
            }
            if (!dateMatch[3] && target.getTime() < nowMs) {
                var nextYearTarget = new Date(year + 1, month, day, hours, minutes, 0, 0)
                if (nextYearTarget.getMonth() !== month || nextYearTarget.getDate() !== day) {
                    return NaN
                }
                var maxRolloverMs = 60 * 24 * 60 * 60 * 1000
                if (nextYearTarget.getTime() - nowMs <= maxRolloverMs) {
                    target = nextYearTarget
                }
            }
            return target.getTime()
        }
    }

    return null
}

function formatCountdown(days, hours, minutes, isLessThanOneMinute, isSpanish) {
    if (isLessThanOneMinute) {
        return isSpanish ? "Se reinicia en < 1 min" : "Resets in < 1m"
    }
    if (days > 0) {
        return isSpanish
            ? "Se reinicia en " + days + " d " + hours + " h"
            : "Resets in " + days + "d " + hours + "h"
    }
    if (hours > 0) {
        return isSpanish
            ? "Se reinicia en " + hours + " h " + minutes + " min"
            : "Resets in " + hours + "h " + minutes + "m"
    }
    return isSpanish
        ? "Se reinicia en " + minutes + " min"
        : "Resets in " + minutes + "m"
}

function formatCountdownFromDiff(diffMs, isSpanish) {
    if (diffMs <= 0) {
        return ""
    }
    if (diffMs < 60000) {
        return formatCountdown(0, 0, 0, true, isSpanish)
    }
    var totalMinutes = Math.floor(diffMs / 60000)
    var days = Math.floor(totalMinutes / (24 * 60))
    var remainingMinutes = totalMinutes % (24 * 60)
    var hours = Math.floor(remainingMinutes / 60)
    var minutes = remainingMinutes % 60

    return formatCountdown(days, hours, minutes, false, isSpanish)
}

function formatResetText(resetsAt, resetDescription, nowMs, languagePreference) {
    var effectiveNowMs = (typeof nowMs === "number" && !isNaN(nowMs) && nowMs > 0)
        ? nowMs : Date.now()
    var isSpanish = Translation.isSpanishActive(languagePreference)

    // 1. Check future ISO-8601 resetsAt
    if (resetsAt !== null && resetsAt !== undefined) {
        var targetMs = (typeof resetsAt === "number") ? resetsAt : Date.parse(String(resetsAt))
        if (!isNaN(targetMs) && targetMs > effectiveNowMs) {
            var diffMs = targetMs - effectiveNowMs
            return formatCountdownFromDiff(diffMs, isSpanish)
        }
    }

    // 2. Check resetDescription (takes effect when resetsAt is null, past, or unparseable)
    if (resetDescription !== null && resetDescription !== undefined) {
        var desc = String(resetDescription).trim()
        if (desc.length > 0) {
            var duration = parseDuration(desc)
            if (duration !== null) {
                return formatCountdown(duration.days, duration.hours, duration.minutes, duration.isLessThanOneMinute, isSpanish)
            }

            var dateMs = parseDate(desc, effectiveNowMs)
            if (dateMs !== null && !isNaN(dateMs)) {
                if (dateMs > effectiveNowMs) {
                    return formatCountdownFromDiff(dateMs - effectiveNowMs, isSpanish)
                }
                return formatCountdown(0, 0, 0, true, isSpanish)
            }

            // Fallback: non-temporal note or unparseable description
            return Translation.translateReset(desc, languagePreference)
        }
    }

    // 3. Fallback when resetDescription is absent but resetsAt exists (past or unparseable timestamp)
    if (resetsAt !== null && resetsAt !== undefined) {
        var rawResetsAt = String(resetsAt).trim()
        if (rawResetsAt.length > 0) {
            return Translation.translate("Reset: %1", [rawResetsAt], null, languagePreference)
        }
    }

    return ""
}
