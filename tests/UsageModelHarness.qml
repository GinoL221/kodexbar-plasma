import QtQuick
import "../contents/code/UsageModel.js" as UsageModel

Item {
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("UsageModelHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        var normalized = UsageModel.normalize([
            {
                provider: null,
                source: "raw source",
                usage: {
                    primary: { usedPercent: 80, resetsAt: "unchanged", resetDescription: null },
                    tertiary: { usedPercent: Infinity },
                    ignored: { usedPercent: 99 }
                }
            },
            { provider: "failed", error: { message: "external failure" } },
            { provider: "second", usage: { primary: { usedPercent: 80 } } }
        ])
        var compact = UsageModel.selectCompact(normalized.providers)

        assert(normalized.providers.length === 2, "expected usable providers only")
        assert(normalized.errors.length === 1, "expected separated provider error")
        assert(normalized.providers[0].provider === null, "provider must preserve null")
        assert(normalized.providers[0].source === "raw source", "source must remain raw")
        assert(normalized.providers[0].windows.length === 2, "only mapped windows may be retained")
        assert(normalized.providers[0].windows[0].resetsAt === "unchanged", "reset value must remain raw")
        assert(normalized.providers[0].windows[1].usedPercent === null, "non-finite percentage must be ignored")
        assert(compact.provider === normalized.providers[0], "ties must retain first provider")
        assert(compact.window.label === "Session", "ties must retain window priority")

        var invalidOnly = UsageModel.normalize({
            provider: "invalid",
            usage: { primary: { usedPercent: null }, secondary: { usedPercent: "80" } }
        })
        assert(UsageModel.selectCompact(invalidOnly.providers) === null,
               "null and nonnumeric percentages must not produce a compact value")
        finish()
    }
}
