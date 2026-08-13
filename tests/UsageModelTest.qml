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

    function test_selectRepresentativeReturnsSessionWhenAllFinite() {
        var provider = UsageModel.normalize({
            provider: "p",
            usage: {
                primary: { usedPercent: 10 },
                secondary: { usedPercent: 20 },
                tertiary: { usedPercent: 30 }
            }
        }).providers[0]
        var representative = UsageModel.selectRepresentative(provider.windows)

        compare(representative.label, "Session")
        compare(representative.usedPercent, 10)
    }

    function test_selectRepresentativeFallsBackToWeeklyOrMonthly() {
        var weeklyOnly = UsageModel.normalize({
            provider: "p",
            usage: {
                primary: { usedPercent: null },
                secondary: { usedPercent: 40 },
                tertiary: { usedPercent: 50 }
            }
        }).providers[0]
        var weeklyRep = UsageModel.selectRepresentative(weeklyOnly.windows)
        compare(weeklyRep.label, "Weekly")
        compare(weeklyRep.usedPercent, 40)

        var monthlyOnly = UsageModel.normalize({
            provider: "p",
            usage: {
                primary: { usedPercent: Infinity },
                secondary: { usedPercent: "80" },
                tertiary: { usedPercent: 60 }
            }
        }).providers[0]
        var monthlyRep = UsageModel.selectRepresentative(monthlyOnly.windows)
        compare(monthlyRep.label, "Monthly")
        compare(monthlyRep.usedPercent, 60)
    }

    function test_selectRepresentativeReturnsNullForNoFiniteWindow() {
        var provider = UsageModel.normalize({
            provider: "p",
            usage: {
                primary: { usedPercent: NaN },
                secondary: { usedPercent: null },
                tertiary: { usedPercent: "55" }
            }
        }).providers[0]

        compare(UsageModel.selectRepresentative(provider.windows), null)
        compare(UsageModel.selectRepresentative([]), null)
    }

    function test_selectRepresentativeHonoursExplicitPreferredWindow() {
        var provider = UsageModel.normalize({
            provider: "p",
            usage: {
                primary: { usedPercent: 10 },
                secondary: { usedPercent: 20 },
                tertiary: { usedPercent: 30 }
            }
        }).providers[0]

        var representative = UsageModel.selectRepresentative(provider.windows, "weekly")
        compare(representative.label, "Weekly")
        compare(representative.usedPercent, 20)
    }

    function test_selectRepresentativeFallsBackWhenPreferredWindowIsNotFinite() {
        var provider = UsageModel.normalize({
            provider: "p",
            usage: {
                primary: { usedPercent: 10 },
                secondary: { usedPercent: 20 },
                tertiary: { usedPercent: NaN }
            }
        }).providers[0]

        var representative = UsageModel.selectRepresentative(provider.windows, "monthly")
        compare(representative.label, "Session")
        compare(representative.usedPercent, 10)
    }

    function test_selectRepresentativePerProviderFallbackIsIndependent() {
        var fallsBack = UsageModel.normalize({
            provider: "falls-back",
            usage: {
                primary: { usedPercent: 15 },
                secondary: { usedPercent: 25 },
                tertiary: { usedPercent: null }
            }
        }).providers[0]
        var keepsMonthly = UsageModel.normalize({
            provider: "keeps-monthly",
            usage: {
                primary: { usedPercent: 5 },
                secondary: { usedPercent: 6 },
                tertiary: { usedPercent: 45 }
            }
        }).providers[0]

        var fallsBackRepresentative = UsageModel.selectRepresentative(fallsBack.windows, "monthly")
        var keepsMonthlyRepresentative = UsageModel.selectRepresentative(keepsMonthly.windows, "monthly")

        compare(fallsBackRepresentative.label, "Session")
        compare(fallsBackRepresentative.usedPercent, 15)
        compare(keepsMonthlyRepresentative.label, "Monthly")
        compare(keepsMonthlyRepresentative.usedPercent, 45)
    }

    function test_selectRepresentativeAutomaticMatchesLegacySingleArgument() {
        var finiteProvider = UsageModel.normalize({
            provider: "finite",
            usage: {
                primary: { usedPercent: 10 },
                secondary: { usedPercent: 20 },
                tertiary: { usedPercent: 30 }
            }
        }).providers[0]
        var nonFiniteProvider = UsageModel.normalize({
            provider: "non-finite",
            usage: {
                primary: { usedPercent: NaN },
                secondary: { usedPercent: 40 },
                tertiary: { usedPercent: 50 }
            }
        }).providers[0]
        var emptyProvider = UsageModel.normalize({
            provider: "empty",
            usage: {}
        }).providers[0]

        var fixtures = [finiteProvider.windows, nonFiniteProvider.windows, emptyProvider.windows]
        for (var i = 0; i < fixtures.length; i++) {
            var windows = fixtures[i]
            var legacy = UsageModel.selectRepresentative(windows)
            compare(UsageModel.selectRepresentative(windows, "automatic"), legacy)
            compare(UsageModel.selectRepresentative(windows, undefined), legacy)
            compare(UsageModel.selectRepresentative(windows, "yearly"), legacy)
        }
    }

    function test_selectRepresentativeReturnsNullForNoFiniteWindowUnderAnyPreference() {
        var provider = UsageModel.normalize({
            provider: "p",
            usage: {
                primary: { usedPercent: NaN },
                secondary: { usedPercent: null },
                tertiary: { usedPercent: "55" }
            }
        }).providers[0]

        compare(UsageModel.selectRepresentative(provider.windows, "automatic"), null)
        compare(UsageModel.selectRepresentative(provider.windows, "session"), null)
        compare(UsageModel.selectRepresentative(provider.windows, "weekly"), null)
        compare(UsageModel.selectRepresentative(provider.windows, "monthly"), null)
        compare(UsageModel.selectRepresentative(provider.windows, "yearly"), null)
    }

    function test_selectCompactIsUnaffectedByPreferredWindow() {
        compare(UsageModel.selectCompact.length, 1, "selectCompact must not accept a preferred-window parameter")

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

        var withoutPreference = UsageModel.selectCompact(result.providers)
        var withIgnoredPreferenceArgument = UsageModel.selectCompact(result.providers, "weekly")

        compare(withoutPreference.provider.provider, "first")
        compare(withoutPreference.window.label, "Session")
        compare(withoutPreference.usedPercent, 80)
        compare(withIgnoredPreferenceArgument.provider.provider, withoutPreference.provider.provider)
        compare(withIgnoredPreferenceArgument.window.label, withoutPreference.window.label)
        compare(withIgnoredPreferenceArgument.usedPercent, withoutPreference.usedPercent)
    }
}
