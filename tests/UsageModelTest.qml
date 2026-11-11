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

    function test_preservesUnmodeledProviderFieldsVerbatimUnderRaw() {
        var provider = UsageModel.normalize({
            provider: "codex",
            source: "oauth",
            version: "0.147.0",
            pace: {
                secondary: {
                    stage: "farAhead",
                    summary: "49% in deficit | Expected 18% used | Runs out in 15h 7m",
                    deltaPercent: 49,
                    expectedUsedPercent: 18,
                    willLastToReset: false,
                    etaSeconds: 54379
                }
            },
            credits: { events: [], updatedAt: "2026-08-14T19:01:20Z", remaining: 0 },
            usage: {
                primary: null,
                tertiary: null,
                loginMethod: "plus",
                dataConfidence: "exact",
                codexResetCredits: { credits: [], updatedAt: "2026-08-14T19:01:20Z", availableCount: 0 },
                identity: { accountEmail: "redacted@example.com", loginMethod: "plus", providerID: "codex" },
                secondary: {
                    windowMinutes: 10080,
                    resetsAt: "2026-08-20T12:21:18Z",
                    resetDescription: "Aug 20 at 9:21 AM",
                    usedPercent: 67
                }
            }
        }).providers[0]

        verify(provider.raw !== undefined, "a normalized provider must expose a raw sibling")
        compare(provider.raw.version, "0.147.0")
        compare(provider.raw.credits.remaining, 0)
        compare(provider.raw.pace.secondary.stage, "farAhead")
        compare(provider.raw.pace.secondary.deltaPercent, 49)
        compare(provider.raw.usage.identity.accountEmail, "redacted@example.com")
        compare(provider.raw.usage.loginMethod, "plus")
        compare(provider.raw.usage.codexResetCredits.availableCount, 0)
        compare(provider.windows.length, 1, "unmodeled fields must not become windows")
        compare(provider.windows[0].label, "Weekly")
    }

    function test_rawIsTheLiveParsedEntryNotACopy() {
        var entry = {
            provider: "claude",
            source: "claude",
            pace: { primary: { stage: "farAhead", deltaPercent: 42, willLastToReset: false } },
            usage: { primary: { windowMinutes: 300, usedPercent: 66 } }
        }

        var provider = UsageModel.normalize([entry]).providers[0]

        verify(provider.raw === entry, "raw must hold the original entry object, not a copy")
        verify(provider.raw.pace === entry.pace, "nested raw values must not be cloned")
    }

    function test_fourKeyContractIsUnregressedByRawAddition() {
        var result = UsageModel.normalize({
            provider: null,
            source: null,
            version: "0.45.2",
            pace: { secondary: { stage: "farBehind", deltaPercent: -43 } },
            usage: {
                identity: { providerID: "gemini" },
                primary: {
                    usedPercent: 42,
                    resetsAt: "2026-08-09T10:00:00Z",
                    resetDescription: null
                }
            }
        })
        var provider = result.providers[0]

        compare(result.providers.length, 1)
        compare(provider.provider, null)
        compare(provider.source, null)
        compare(provider.windows.length, 1)
        compare(provider.windows[0].key, "primary")
        compare(provider.windows[0].label, "Session")
        compare(provider.windows[0].usedPercent, 42)
        compare(provider.windows[0].resetsAt, "2026-08-09T10:00:00Z")
        compare(provider.windows[0].resetDescription, null)
        compare(Object.keys(provider.windows[0]).length, 5,
                "window objects must keep exactly five keys")
        compare(UsageModel.selectRepresentative(provider.windows).usedPercent, 42)
    }

    function test_rawRetainsWindowKeysThatWindowsStillDrop() {
        var provider = UsageModel.normalize({
            provider: "copilot",
            source: "api",
            usage: {
                primary: { usedPercent: "70" },
                secondary: { usedPercent: Infinity },
                tertiary: { usedPercent: 55 },
                extraRateWindow: { usedPercent: 99 },
                details: [
                    {
                        title: "Credits",
                        rows: [
                            { label: "Credits used", value: "3", secondaryValue: "Aug 31 at 9:00 PM" }
                        ]
                    }
                ]
            }
        }).providers[0]

        compare(provider.windows.length, 3, "window-level unknown-key dropping is unchanged")
        compare(provider.windows[0].key, "primary")
        compare(provider.windows[1].key, "secondary")
        compare(provider.windows[2].key, "tertiary")
        compare(provider.windows[1].usedPercent, null)
        compare(provider.raw.usage.extraRateWindow.usedPercent, 99,
                "raw must retain the window key that windows drops")
        compare(provider.raw.usage.details[0].rows[0].secondaryValue, "Aug 31 at 9:00 PM")
        verify(provider.raw.usage.secondary.usedPercent === Infinity,
               "raw must preserve non-finite values that windows normalize to null")
    }

    function test_selectOverviewWindowsReturnsSessionThenWeeklyRegardlessOfPayloadOrder() {
        var payloadOrder = UsageModel.normalize({
            provider: "p",
            usage: {
                primary: { usedPercent: 10 },
                secondary: { usedPercent: 20 }
            }
        }).providers[0]
        var reversedPayloadOrder = UsageModel.normalize({
            provider: "p",
            usage: {
                secondary: { usedPercent: 20 },
                primary: { usedPercent: 10 }
            }
        }).providers[0]

        var result = UsageModel.selectOverviewWindows(payloadOrder.windows)
        compare(result.length, 2)
        compare(result[0].label, "Session")
        compare(result[0].usedPercent, 10)
        compare(result[1].label, "Weekly")
        compare(result[1].usedPercent, 20)

        var reversedResult = UsageModel.selectOverviewWindows(reversedPayloadOrder.windows)
        compare(reversedResult.length, 2)
        compare(reversedResult[0].label, "Session")
        compare(reversedResult[1].label, "Weekly")
    }

    function test_selectOverviewWindowsReturnsSessionOnlyWhenWeeklyIsNotFinite() {
        var provider = UsageModel.normalize({
            provider: "p",
            usage: {
                primary: { usedPercent: 15 },
                secondary: { usedPercent: null }
            }
        }).providers[0]

        var result = UsageModel.selectOverviewWindows(provider.windows)
        compare(result.length, 1)
        compare(result[0].label, "Session")
        compare(result[0].usedPercent, 15)
    }

    function test_selectOverviewWindowsReturnsWeeklyOnlyWhenSessionIsNotFinite() {
        var provider = UsageModel.normalize({
            provider: "p",
            usage: {
                primary: { usedPercent: NaN },
                secondary: { usedPercent: 25 }
            }
        }).providers[0]

        var result = UsageModel.selectOverviewWindows(provider.windows)
        compare(result.length, 1)
        compare(result[0].label, "Weekly")
        compare(result[0].usedPercent, 25)
    }

    function test_selectOverviewWindowsReturnsMonthlyOnlyWhenSessionAndWeeklyAreNotFinite() {
        var provider = UsageModel.normalize({
            provider: "p",
            usage: {
                primary: { usedPercent: null },
                secondary: { usedPercent: Infinity },
                tertiary: { usedPercent: 35 }
            }
        }).providers[0]

        var result = UsageModel.selectOverviewWindows(provider.windows)
        compare(result.length, 1)
        compare(result[0].label, "Monthly")
        compare(result[0].usedPercent, 35)
    }

    function test_selectOverviewWindowsReturnsSessionWeeklyAndMonthlyWhenAllFinite() {
        var provider = UsageModel.normalize({
            provider: "opencodego",
            usage: {
                primary: { usedPercent: 0 },
                secondary: { usedPercent: 73 },
                tertiary: { usedPercent: 40 }
            }
        }).providers[0]

        var result = UsageModel.selectOverviewWindows(provider.windows)
        compare(result.length, 3)
        compare(result[0].label, "Session")
        compare(result[0].usedPercent, 0)
        compare(result[1].label, "Weekly")
        compare(result[1].usedPercent, 73)
        compare(result[2].label, "Monthly")
        compare(result[2].usedPercent, 40)
    }

    function test_selectOverviewWindowsReturnsEmptyArrayWhenNoWindowIsFinite() {
        var provider = UsageModel.normalize({
            provider: "p",
            usage: {
                primary: { usedPercent: NaN },
                secondary: { usedPercent: "20" },
                tertiary: { usedPercent: null }
            }
        }).providers[0]

        compare(UsageModel.selectOverviewWindows(provider.windows), [])
        compare(UsageModel.selectOverviewWindows([]), [])
    }

    function test_selectOverviewWindowsDoesNotDuplicateWhenWindowMatchesKeyAndLabel() {
        var provider = UsageModel.normalize({
            provider: "grok",
            rateWindowLabels: {
                primary: "Weekly"
            },
            usage: {
                primary: { usedPercent: 100 },
                secondary: null,
                tertiary: null
            }
        }).providers[0]

        var result = UsageModel.selectOverviewWindows(provider.windows)
        compare(result.length, 1)
        compare(result[0].label, "Weekly")
        compare(result[0].usedPercent, 100)
    }

    function test_errorEntriesGainNoRawSibling() {
        var result = UsageModel.normalize([
            {
                provider: "openai",
                source: "auto",
                error: { kind: "provider", code: 1, message: "No available fetch strategy for openai." }
            },
            { provider: "grok", source: "web", usage: { primary: { usedPercent: 12 } } }
        ])

        compare(result.errors.length, 1)
        compare(result.errors[0].provider, "openai")
        compare(result.errors[0].source, "auto")
        compare(result.errors[0].error.message, "No available fetch strategy for openai.")
        compare(Object.keys(result.errors[0]).length, 3,
                "error entries must keep exactly provider, source, error")
        verify(result.errors[0].raw === undefined, "error entries must not gain a raw sibling")
        compare(result.providers.length, 1)
        compare(result.providers[0].provider, "grok")
        verify(result.providers[0].raw !== undefined, "usable providers still expose raw")
    }

    function test_normalizesAntigravityExtraRateWindowsToSessionWeeklyArgonAndThirdParty() {
        var result = UsageModel.normalize({
            provider: "antigravity",
            source: "auto",
            usage: {
                primary: { usedPercent: 99 },
                secondary: { usedPercent: 88 },
                extraRateWindows: [
                    { id: "antigravity-quota-summary-3p-5h", title: "Claude/GPT 5-hour", window: { usedPercent: 10 } },
                    { id: "antigravity-quota-summary-gemini-argon-wtu-weekly", title: "Gemini weekly", window: { usedPercent: 25 } },
                    { id: "antigravity-quota-summary-gemini-weekly", title: "Gemini weekly", window: { usedPercent: 45 } },
                    { id: "antigravity-quota-summary-gemini-5h", title: "Gemini 5-hour", window: { usedPercent: 65 } },
                    { id: "antigravity-quota-summary-3p-weekly", title: "Claude/GPT weekly", window: { usedPercent: 50 } }
                ]
            }
        })

        compare(result.providers.length, 1)
        var p = result.providers[0]
        compare(p.windows.length, 5)
        compare(p.windows[0].label, "Session")
        compare(p.windows[0].usedPercent, 65)
        compare(p.windows[1].label, "Weekly")
        compare(p.windows[1].usedPercent, 45)
        compare(p.windows[2].label, "Argon")
        compare(p.windows[2].usedPercent, 25)
        compare(p.windows[3].label, "Claude/GPT 5-hour")
        compare(p.windows[3].usedPercent, 10)
        compare(p.windows[4].label, "Claude/GPT weekly")
        compare(p.windows[4].usedPercent, 50)

        // Overview must select only Session, Weekly, and Argon
        var overview = UsageModel.selectOverviewWindows(p.windows)
        compare(overview.length, 3)
        compare(overview[0].label, "Session")
        compare(overview[1].label, "Weekly")
        compare(overview[2].label, "Argon")
    }

    function test_rateWindowLabelsOverrideDefaultLabels() {
        var result = UsageModel.normalize({
            provider: "custom",
            rateWindowLabels: { primary: "DeepSeek V4 Flash", secondary: "GLM 5.3 Flash" },
            usage: {
                primary: { usedPercent: 27 },
                secondary: { usedPercent: 8 }
            }
        })

        compare(result.providers[0].windows[0].key, "primary")
        compare(result.providers[0].windows[0].label, "DeepSeek V4 Flash")
        compare(result.providers[0].windows[1].key, "secondary")
        compare(result.providers[0].windows[1].label, "GLM 5.3 Flash")
    }

    function test_rateWindowLabelsApplyPerKeyAndFallBackToDefaults() {
        var result = UsageModel.normalize({
            provider: "partial",
            rateWindowLabels: { primary: "  Custom  ", secondary: "", tertiary: 5 },
            usage: {
                primary: { usedPercent: 1 },
                secondary: { usedPercent: 2 },
                tertiary: { usedPercent: 3 }
            }
        })

        compare(result.providers[0].windows[0].label, "Custom")
        compare(result.providers[0].windows[1].label, "Weekly")
        compare(result.providers[0].windows[2].label, "Monthly")
    }

    function test_invalidRateWindowLabelsContainersKeepDefaults() {
        var shapes = [undefined, null, "Session", 7, ["A", "B"]]

        for (var i = 0; i < shapes.length; i++) {
            var result = UsageModel.normalize({
                provider: "shape" + i,
                rateWindowLabels: shapes[i],
                usage: { primary: { usedPercent: 10 } }
            })

            compare(result.providers[0].windows[0].label, "Session")
        }
    }

    function test_normalizesClaudeExtraRateWindowsToFable() {
        var result = UsageModel.normalize({
            provider: "claude",
            source: "oauth",
            usage: {
                primary: { usedPercent: 70, resetsAt: "2026-11-10T09:09:59Z", resetDescription: "Nov 10 at 6:09AM" },
                secondary: { usedPercent: 78, resetsAt: "2026-11-11T03:59:59Z", resetDescription: "Nov 11 at 12:59AM" },
                extraRateWindows: [
                    {
                        id: "claude-weekly-scoped-fable",
                        title: "Fable only",
                        window: {
                            usedPercent: 8,
                            resetsAt: "2026-11-11T03:59:59Z",
                            resetDescription: "Nov 11 at 12:59AM"
                        }
                    }
                ]
            }
        })

        compare(result.providers.length, 1)
        var p = result.providers[0]
        compare(p.windows.length, 3)
        compare(p.windows[0].label, "Session")
        compare(p.windows[0].usedPercent, 70)
        compare(p.windows[1].label, "Weekly")
        compare(p.windows[1].usedPercent, 78)
        compare(p.windows[2].key, "tertiary")
        compare(p.windows[2].label, "Fable")
        compare(p.windows[2].usedPercent, 8)
        compare(p.windows[2].resetsAt, "2026-11-11T03:59:59Z")

        var overview = UsageModel.selectOverviewWindows(p.windows)
        compare(overview.length, 3)
        compare(overview[0].label, "Session")
        compare(overview[1].label, "Weekly")
        compare(overview[2].label, "Fable")
    }
}
