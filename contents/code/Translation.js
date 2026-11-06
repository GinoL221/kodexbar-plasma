.pragma library

.import "SpanishDictionary.js" as SpanishDictionary

function isSpanishActive(languagePreference) {
    return languagePreference === "es"
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
