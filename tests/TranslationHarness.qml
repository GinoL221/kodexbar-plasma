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

        // 5. Pace summary translations
        var pace = "43% in reserve | Expected 75% used | Lasts until reset | 1.5x headroom"
        var translatedPace = Translation.translatePace(pace, "es")
        assert(translatedPace.indexOf("en reserva") !== -1, "pace translates in reserve")
        assert(translatedPace.indexOf("Uso esperado 75%") !== -1, "pace translates Expected used")
        assert(translatedPace.indexOf("Dura hasta el reinicio") !== -1, "pace translates Lasts until reset")
        assert(translatedPace.indexOf("margen") !== -1, "pace translates headroom")

        // 5b. Remaining English pace fragments
        var paceProjected = Translation.translatePace("A buen ritmo | Uso esperado 58% | Projected empty in 1h 57m", "es")
        assert(paceProjected.indexOf("Se agota en 1 h 57 min") !== -1, "pace translates Projected empty in")
        assert(paceProjected.indexOf("Projected empty") === -1, "no Projected empty remains in Spanish pace")
        assert(paceProjected.indexOf("Runs out") === -1, "no Runs out remains in Spanish pace")

        var paceRunsOut = Translation.translatePace("A buen ritmo | Uso esperado 41% | Runs out in 3d 22h", "es")
        assert(paceRunsOut.indexOf("Se agota en 3 d 22 h") !== -1, "pace translates Runs out in")
        assert(paceRunsOut.indexOf("Runs out") === -1, "no Runs out remains in Runs out pace")

        var paceTomorrow = Translation.translatePace("Runs out tomorrow", "es")
        assert(paceTomorrow === "Se agota mañana", "pace translates Runs out tomorrow")

        // English mode preserves originals
        var paceEnProjected = Translation.translatePace("A buen ritmo | Uso esperado 58% | Projected empty in 1h 57m", "en")
        assert(paceEnProjected === "A buen ritmo | Uso esperado 58% | Projected empty in 1h 57m", "English pace preserves Projected empty")
        var paceEnRunsOut = Translation.translatePace("A buen ritmo | Uso esperado 41% | Runs out in 3d 22h", "en")
        assert(paceEnRunsOut === "A buen ritmo | Uso esperado 41% | Runs out in 3d 22h", "English pace preserves Runs out")
        var paceEnTomorrow = Translation.translatePace("Runs out tomorrow", "en")
        assert(paceEnTomorrow === "Runs out tomorrow", "English pace preserves Runs out tomorrow")

        // 6. Chrome and footer status
        assert(Translation.translate("Refresh", [], null, "es") === "Actualizar", "Refresh translates to Actualizar")
        assert(Translation.translate("Ready", [], null, "es") === "Listo", "Ready translates to Listo")
        assert(Translation.translate("Loading usage…", [], null, "es") === "Cargando uso…", "Loading usage translates to Cargando uso…")

        finish()
    }
}
