import QtQuick
import "../contents/code/Translation.js" as Translation

Item {
    id: root
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("TranslationHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        // 1. English fallback when language is "en"
        assert(Translation.translate("Session", [], null, "en") === "Session", "Session in English is Session")
        assert(Translation.translate("%1% used", [42], null, "en") === "42% used", "percentage in English")
        assert(Translation.translateReset("Resets in 2h 53m", "en") === "Resets in 2h 53m", "reset in English")

        // 2. Spanish translations when language is "es"
        assert(Translation.translate("Session", [], null, "es") === "Sesión", "Session in Spanish is Sesión")
        assert(Translation.translate("Weekly", [], null, "es") === "Semanal", "Weekly in Spanish is Semanal")
        assert(Translation.translate("Monthly", [], null, "es") === "Mensual", "Monthly in Spanish is Mensual")
        assert(Translation.translate("All", [], null, "es") === "Todos", "All in Spanish is Todos")
        assert(Translation.translate("%1% used", [42], null, "es") === "42% usado", "percentage in Spanish is 42% usado")
        assert(Translation.translate("Quota exhausted", [], null, "es") === "Cuota agotada", "Quota exhausted in Spanish")
        assert(Translation.translate("Reset credits", [], null, "es") === "Créditos de reinicio de límite", "Reset credits in Spanish")

        // 3. Dynamic reset duration translations
        assert(Translation.translateReset("Resets in 2h 53m", "es") === "Se reinicia en 2 h 53 min", "Resets in duration to Spanish")
        assert(Translation.translateReset("refresh in 5d 4h", "es") === "Se reinicia en 5 d 4 h", "refresh in duration to Spanish")
        assert(Translation.translateReset("runs until reset", "es") === "Dura hasta el reinicio", "runs until reset in Spanish")
        assert(Translation.translateReset("on track", "es") === "A buen ritmo", "on track in Spanish")

        // 4. Relative time translations
        assert(Translation.translate("Updated just now", [], null, "es") === "Actualizado ahora", "Updated just now in Spanish")
        assert(Translation.translate("Updated 1 hour ago", [], null, "es") === "Actualizado hace 1 hora", "Updated 1 hour ago in Spanish")

        finish()
    }
}
