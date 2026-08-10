import QtQuick
import "../contents/ui" as UsageUi

Item {
    id: root
    property bool assertionFailed: false
    width: 160
    height: 320

    function assert(condition, message) {
        if (!condition) {
            console.error("ProviderRowHarness failure:", message)
            assertionFailed = true
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    UsageUi.ProviderRow {
        id: row
        width: root.width
        providerData: ({
            provider: "unknown-provider",
            source: "CLI raw source",
            windows: [
                { label: "Session", usedPercent: 72, resetsAt: "2026-08-09T12:00:00Z", resetDescription: "Exact reset note" },
                { label: "Monthly", usedPercent: null, resetsAt: null, resetDescription: null }
            ]
        })
    }

    Component.onCompleted: {
        assert(row.providerValue === "unknown-provider", "provider must remain raw")
        assert(row.sourceValue === "CLI raw source", "source must remain raw")
        assert(row.windows.length === 2, "missing windows must be omitted by the input model")
        assert(row.windows[0].label === "Session" && row.windows[1].label === "Monthly", "window order must be preserved")
        assert(row.windows[0].resetsAt === "2026-08-09T12:00:00Z", "reset values must remain exact")
        assert(row.iconSource("unknown-provider") === "dialog-information", "unknown providers must use the themed fallback icon")
        assert(row.width === root.width, "row must remain usable in narrow geometry")
        finish()
    }
}
