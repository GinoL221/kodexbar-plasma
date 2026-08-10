import QtTest 1.3
import "../contents/code/UsageModel.js" as UsageModel

TestCase {
    name: "UsageModel"

    function test_normalizesSingletonAndPreservesNullableRawValues() {
        var result = UsageModel.normalize({
            provider: null,
            source: null,
            usage: {
                primary: {
                    usedPercent: 42,
                    resetsAt: "2026-08-09T10:00:00Z",
                    resetDescription: null
                }
            }
        })

        compare(result.providers.length, 1)
        compare(result.providers[0].provider, null)
        compare(result.providers[0].source, null)
        compare(result.providers[0].windows.length, 1)
        compare(result.providers[0].windows[0].label, "Session")
        compare(result.providers[0].windows[0].resetsAt, "2026-08-09T10:00:00Z")
        compare(result.providers[0].windows[0].resetDescription, null)
    }

    function test_normalizesArrayInCliOrderAndOmitsMissingWindows() {
        var result = UsageModel.normalize([
            { provider: "first", source: "literal-source", usage: { tertiary: { usedPercent: 30 } } },
            { provider: "second", usage: { secondary: { usedPercent: 40 } } }
        ])

        compare(result.providers.length, 2)
        compare(result.providers[0].provider, "first")
        compare(result.providers[0].source, "literal-source")
        compare(result.providers[0].windows[0].label, "Monthly")
        compare(result.providers[1].provider, "second")
        compare(result.providers[1].windows[0].label, "Weekly")
    }

    function test_separatesMixedErrorsFromUsableProviders() {
        var result = UsageModel.normalize([
            { provider: "usable", usage: { primary: { usedPercent: 20 } } },
            { provider: "broken", source: "raw-source", error: { kind: "auth", message: "Sign in externally" } }
        ])

        compare(result.providers.length, 1)
        compare(result.providers[0].provider, "usable")
        compare(result.errors.length, 1)
        compare(result.errors[0].provider, "broken")
        compare(result.errors[0].source, "raw-source")
        compare(result.errors[0].error.message, "Sign in externally")
    }

    function test_normalizesEmptyData() {
        var result = UsageModel.normalize([])

        compare(result.providers.length, 0)
        compare(result.errors.length, 0)
        compare(UsageModel.selectCompact(result.providers), null)
    }

    function test_ignoresExtraAndNonFiniteUsageValues() {
        var result = UsageModel.normalize({
            provider: "finite-only",
            usage: {
                primary: { usedPercent: "70" },
                secondary: { usedPercent: Infinity },
                tertiary: { usedPercent: 55 },
                extraRateWindow: { usedPercent: 99 }
            }
        })

        compare(result.providers[0].windows.length, 3)
        compare(result.providers[0].windows[0].usedPercent, null)
        compare(result.providers[0].windows[1].usedPercent, null)
        compare(result.providers[0].windows[2].usedPercent, 55)
        compare(UsageModel.selectCompact(result.providers).usedPercent, 55)
    }

    function test_compactSelectionUsesStrictGreatestAndTieOrder() {
        var result = UsageModel.normalize([
            {
                provider: "first",
                usage: {
                    primary: { usedPercent: 80 },
                    secondary: { usedPercent: 80 },
                    tertiary: { usedPercent: 80 }
                }
            },
            { provider: "second", usage: { primary: { usedPercent: 80 } } }
        ])
        var compact = UsageModel.selectCompact(result.providers)

        compare(compact.provider.provider, "first")
        compare(compact.window.label, "Session")
        compare(compact.usedPercent, 80)
    }
}
