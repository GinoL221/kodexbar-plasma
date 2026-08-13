.pragma library

function substitute(text, argumentsList) {
    var values = argumentsList instanceof Array ? argumentsList : []
    return String(text).replace(/%([1-9][0-9]*)/g, function(match, index) {
        var valueIndex = Number(index) - 1
        return valueIndex >= 0 && valueIndex < values.length
            ? String(values[valueIndex]) : match
    })
}

function translate(text, argumentsList, translator) {
    var values = argumentsList instanceof Array ? argumentsList : []
    var translated = typeof translator === "function"
        ? translator.apply(null, [text].concat(values)) : text
    return substitute(translated, values)
}

function plural(singular, pluralText, count, pluralizer) {
    var translated = typeof pluralizer === "function"
        ? pluralizer(singular, pluralText, count)
        : (count === 1 ? singular : pluralText)
    return substitute(translated, [count])
}
