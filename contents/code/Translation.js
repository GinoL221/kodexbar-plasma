.pragma library

.import "SpanishDictionary.js" as SpanishDictionary

function isSpanishActive(languagePreference) {
    if (languagePreference === "es") {
        return true
    }
    if (languagePreference === "en") {
        return false
    }
    if (languagePreference === "auto") {
        try {
            if (typeof Qt !== "undefined" && typeof Qt.locale === "function") {
                var loc = Qt.locale()
                if (loc && typeof loc.name === "string" && loc.name.toLowerCase().indexOf("es") === 0) {
                    return true
                }
            }
        } catch (_ignored) {}
    }
    return false
}

function substitute(text, argumentsList) {
    var values = argumentsList instanceof Array ? argumentsList : []
    return String(text).replace(/%([1-9][0-9]*)/g, function(match, index) {
        var valueIndex = Number(index) - 1
        return valueIndex >= 0 && valueIndex < values.length
            ? String(values[valueIndex]) : match
    })
}

function translate(text, argumentsList, translator, languagePreference) {
    var values = argumentsList instanceof Array ? argumentsList : []
    if (isSpanishActive(languagePreference)) {
        var esText = SpanishDictionary.translateTerm(text)
        return substitute(esText, values)
    }
    var translated = typeof translator === "function"
        ? translator.apply(null, [text].concat(values)) : text
    return substitute(translated, values)
}

function translateReset(text, languagePreference) {
    if (isSpanishActive(languagePreference)) {
        return SpanishDictionary.translateDuration(text)
    }
    return text
}

function translatePace(text, languagePreference) {
    if (isSpanishActive(languagePreference)) {
        return SpanishDictionary.translatePace(text)
    }
    return text
}

function plural(singular, pluralText, count, pluralizer, languagePreference) {
    if (isSpanishActive(languagePreference)) {
        var template = count === 1 ? singular : pluralText
        var esTemplate = SpanishDictionary.translateTerm(template)
        return substitute(esTemplate, [count])
    }
    var translated = typeof pluralizer === "function"
        ? pluralizer(singular, pluralText, count)
        : (count === 1 ? singular : pluralText)
    return substitute(translated, [count])
}
