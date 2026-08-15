import QtTest 1.3
import QtQml
import org.kde.plasma.plasma5support as Plasma5Support

TestCase {
    name: "UsageControllerFixture"

    // These contract tests keep command parsing out of the model and UI layers.
    function controllerComponent() {
        return Qt.createComponent("../contents/ui/UsageController.qml")
    }

    function test_quotesAbsolutePathsWithSpacesQuotesAndMetacharacters() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, { commandPath: "/tmp/cli dir/cli'$(unsafe)" })
        verify(controller.commandLine().indexOf("usage --provider all --format json --json-only") > 0)
        controller.destroy()
    }

    function test_persistentStagesPreserveExactSourcesAndAcceptNumericOrStringZero() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, {
            commandPath: "/tmp/cli dir/codexbar",
            testMode: true
        })

        controller.startPreflightForTest()
        compare(controller.activeStage, "preflight")
        compare(controller.activeSource, "test -x '/tmp/cli dir/codexbar'")
        compare(controller.activeRequestCount, 1)
        controller.deliverStageForTest("preflight", controller.generation,
                                       controller.activeSource, { "exit code": "0" })
        tryVerify(function() { return controller.activeStage === "command" }, 1000)
        compare(controller.activeSource,
                "'/tmp/cli dir/codexbar' usage --provider all --format json --json-only")
        controller.deliverStageForTest("command", controller.generation,
                                       controller.activeSource, {
                                           stdout: JSON.stringify([
                                               { provider: "usable", usage: { primary: { usedPercent: 42 } } }
                                           ]),
                                           stderr: "",
                                           "exit code": 0
                                       })
        compare(controller.phase, "ready")
        compare(controller.committedProviders.length, 1)
        compare(controller.activeRequestCount, 0)
        controller.destroy()
    }

    function test_persistentStageGuardsRejectWrongStageSourceGenerationAndReleasedCallbacks() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, {
            commandPath: "/tmp/codexbar",
            testMode: true
        })

        controller.startPreflightForTest()
        var generation = controller.generation
        var source = controller.activeSource
        controller.deliverStageForTest("command", generation, source, { "exit code": 0 })
        compare(controller.activeStage, "preflight")
        controller.deliverStageForTest("preflight", generation, "wrong-source", { "exit code": 0 })
        compare(controller.activeStage, "preflight")
        controller.deliverStageForTest("preflight", generation - 1, source, { "exit code": 0 })
        compare(controller.activeStage, "preflight")
        controller.deliverStageForTest("preflight", generation, source, { "exit code": 0 })
        tryVerify(function() { return controller.activeStage === "command" }, 1000)
        var commandSource = controller.activeSource
        controller.timeoutForTest(generation)
        compare(controller.phase, "error")
        compare(controller.activeRequestCount, 0)
        controller.deliverStageForTest("command", generation, commandSource, {
                                           stdout: "[]", "exit code": 0
                                       })
        compare(controller.phase, "error")
        controller.destroy()
    }

    function test_liveCallbackDeliveryRejectsCapturedGenerationAfterSameSourceReconnect() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, {
            commandPath: "/tmp/codexbar",
            testMode: true
        })

        controller.requestRefresh()
        var olderGeneration = controller.generation
        var commandSource = controller.activeSource
        controller.timeoutForTest(olderGeneration)
        controller.requestRefresh()
        compare(controller.activeSource, commandSource)
        controller.deliverLiveStageForTest("command", olderGeneration, commandSource, {
                                               stdout: JSON.stringify([
                                                   { provider: "stale", usage: { primary: { usedPercent: 42 } } }
                                               ]),
                                               "exit code": 0
                                           })
        compare(controller.phase, "loading")
        compare(controller.committedProviders.length, 0)
        compare(controller.activeRequestCount, 1)
        controller.destroy()
    }

    function test_nonzeroStringKeepsSnapshotAndValidEmptyCommitsNoData() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, { commandPath: "/tmp/codexbar", testMode: true })
        controller.requestRefresh()
        controller.completeForTest(controller.generation, JSON.stringify([
            { provider: "usable", usage: { primary: { usedPercent: 42 } } }
        ]), "0")
        compare(controller.committedProviders.length, 1)
        controller.requestRefresh()
        controller.completeForTest(controller.generation, "", "7")
        compare(controller.phase, "error")
        compare(controller.committedProviders.length, 1)
        controller.requestRefresh()
        controller.completeForTest(controller.generation, "[]", 0)
        compare(controller.phase, "noData")
        compare(controller.committedProviders.length, 0)
        controller.destroy()
    }

    function test_nonzeroExitWithUsableStdoutCommitsProviders() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, { commandPath: "/tmp/codexbar", testMode: true })
        controller.requestRefresh()
        controller.completeForTest(controller.generation, JSON.stringify([
            { provider: "usable", usage: { primary: { usedPercent: 42 } } },
            { provider: "unavailable", error: { kind: "provider", message: "optional CLI missing" } }
        ]), "1")
        compare(controller.phase, "ready")
        compare(controller.committedProviders.length, 1)
        compare(controller.committedErrors.length, 1)
        controller.destroy()
    }

    function test_blocksMissingRelativeAndNonExecutablePaths() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, {
            testMode: true,
            pathExecutableForTest: false,
            discoveryOutputForTest: ""
        })
        verify(!controller.validatePath("codexbar").valid)
        controller.commandPath = "/definitely/missing/codexbar"
        controller.requestRefresh()
        tryVerify(function() { return controller.phase === "error" }, 10000)
        verify(controller.errorMessage.length > 0)
        controller.commandPath = "/dev/null"
        controller.requestRefresh()
        tryVerify(function() { return controller.phase === "error" }, 10000)
        verify(controller.errorMessage.length > 0)
        controller.destroy()
    }

    function test_validSavedPathSkipsDiscoveryAndPreservesUsageArguments() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, {
            commandPath: "/tmp/codexbar",
            testMode: true,
            pathExecutableForTest: true,
            discoveryOutputForTest: "/should/not/be/used"
        })

        controller.requestRefresh()
        compare(controller.activeStage, "command")
        compare(controller.discoveredPathForTest, "")
        compare(controller.activeSource,
                "'/tmp/codexbar' usage --provider all --format json --json-only")
        controller.destroy()
    }

    function test_emptyAndInvalidPathsDiscoverFirstExecutableCandidate() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var emptyPath = component.createObject(null, {
            commandPath: "",
            testMode: true,
            discoveryOutputForTest: "/opt/codexbar"
        })
        var invalidPath = component.createObject(null, {
            commandPath: "relative-codexbar",
            testMode: true,
            discoveryOutputForTest: "/opt/recovered-codexbar"
        })

        emptyPath.requestRefresh()
        compare(emptyPath.discoveredPathForTest, "/opt/codexbar")
        tryVerify(function() { return emptyPath.activeStage === "command" }, 1000)
        compare(emptyPath.activeSource,
                "'/opt/codexbar' usage --provider all --format json --json-only")
        invalidPath.requestRefresh()
        compare(invalidPath.discoveredPathForTest, "/opt/recovered-codexbar")
        tryVerify(function() { return invalidPath.activeStage === "command" }, 1000)
        compare(invalidPath.activeSource,
                "'/opt/recovered-codexbar' usage --provider all --format json --json-only")
        emptyPath.destroy()
        invalidPath.destroy()
    }

    function test_noDiscoveryMatchBlocksUsageAndRetainsSnapshot() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, {
            commandPath: "",
            testMode: true,
            discoveryOutputForTest: ""
        })
        controller.committedProviders = [{ provider: "retained" }]

        controller.requestRefresh()
        compare(controller.phase, "error")
        compare(controller.configurationRequired, true)
        compare(controller.activeRequestCount, 0)
        compare(controller.committedProviders.length, 1)
        controller.destroy()
    }

    function test_preflightDataCallbackDispatchesDiscoveryResults() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, {
            commandPath: "/tmp/codexbar",
            testMode: false
        })

        controller.startPreflightForTest()
        controller.deliverStageForTest("preflight", controller.generation, controller.activeSource, {
                                           "exit code": 1
                                       })
        compare(controller.activeStage, "discovery")
        controller.deliverPreflightDataForTest({
                                                    stdout: "/opt/codexbar\n",
                                                    "exit code": 0
                                                })
        compare(controller.discoveredPathForTest, "/opt/codexbar")
        tryVerify(function() { return controller.activeStage === "preflight" }, 1000)
        controller.destroy()
    }

    function test_timeoutCoalescingAndStaleCompletionNeverCommit() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null)
        controller.requestRefresh()
        controller.requestRefresh()
        compare(controller.activeRequestCount, 1)
        compare(controller.refreshQueued, true)
        controller.completeForTest(controller.generation - 1, "[]", 0)
        compare(controller.committedProviders.length, 0)
        controller.timeoutForTest(controller.generation)
        compare(controller.phase, "loading")
        compare(controller.activeRequestCount, 1)
        controller.timeoutForTest(controller.generation)
        compare(controller.phase, "error")
        wait(100)
        controller.destroy()
    }

    function test_timeoutUsesActionableProviderNeutralMessageAndRetainsSnapshot() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, {
            commandPath: "/tmp/codexbar",
            testMode: true,
            timeoutMs: 120000
        })
        var timeoutMessage = "CodexBar did not return all-provider usage within 120 seconds. Check enabled providers in CodexBar, temporarily disable a provider that hangs, then retry."

        controller.requestRefresh()
        compare(controller.commandLine(), "'/tmp/codexbar' usage --provider all --format json --json-only")
        controller.completeForTest(controller.generation, JSON.stringify([
            { provider: "usable", usage: { primary: { usedPercent: 42 } } }
        ]), 0)
        compare(controller.committedProviders.length, 1)

        controller.requestRefresh()
        var timedOutGeneration = controller.generation
        controller.timeoutForTest(timedOutGeneration)
        compare(controller.phase, "error")
        compare(controller.errorMessage, timeoutMessage)
        compare(controller.activeRequestCount, 0)
        compare(controller.generation, timedOutGeneration)
        compare(controller.committedProviders.length, 1)
        verify(controller.errorMessage.indexOf("Claude") === -1)
        controller.destroy()
    }

    function test_committedGenerationTracksOnlySuccessfulSnapshotCommits() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, { commandPath: "/tmp/codexbar", testMode: true })

        compare(controller.committedGeneration, 0)

        controller.requestRefresh()
        var readyGeneration = controller.generation
        controller.completeForTest(readyGeneration, JSON.stringify([
            { provider: "usable", usage: { primary: { usedPercent: 42 } } }
        ]), 0)
        compare(controller.phase, "ready")
        compare(controller.committedGeneration, readyGeneration)

        controller.requestRefresh()
        var noDataGeneration = controller.generation
        controller.completeForTest(noDataGeneration, "[]", 0)
        compare(controller.phase, "noData")
        compare(controller.committedGeneration, noDataGeneration)

        controller.requestRefresh()
        var timedOutGeneration = controller.generation
        controller.timeoutForTest(timedOutGeneration)
        compare(controller.phase, "error")
        compare(controller.committedGeneration, noDataGeneration)

        controller.requestRefresh()
        var malformedGeneration = controller.generation
        controller.completeForTest(malformedGeneration, "{malformed", 0)
        compare(controller.phase, "error")
        compare(controller.committedGeneration, noDataGeneration)
        controller.destroy()
    }

    function test_emptyOutputRemainsDistinctAndRefreshStartsOneNewGeneration() {
        var component = controllerComponent()
        verify(component.status === Component.Ready, component.errorString())
        var controller = component.createObject(null, {
            commandPath: "/tmp/codexbar",
            testMode: true,
            timeoutMs: 120000
        })

        controller.requestRefresh()
        controller.completeForTest(controller.generation, JSON.stringify([
            { provider: "usable", usage: { primary: { usedPercent: 42 } } }
        ]), 0)
        controller.requestRefresh()
        var timedOutGeneration = controller.generation
        controller.timeoutForTest(timedOutGeneration)
        controller.requestRefresh()
        compare(controller.phase, "loading")
        compare(controller.generation, timedOutGeneration + 1)
        compare(controller.activeRequestCount, 1)
        compare(controller.committedProviders.length, 1)
        controller.completeForTest(timedOutGeneration, "[]", 0)
        compare(controller.committedProviders.length, 1)
        controller.completeForTest(controller.generation, "", 0)
        compare(controller.phase, "error")
        compare(controller.errorMessage, "CodexBar CLI returned no output.")
        verify(controller.errorMessage.indexOf("15 seconds") === -1)
        compare(controller.committedProviders.length, 1)
        controller.destroy()
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
    }

    // The runtime harness invokes this fixture with a long-running executable source,
    // disconnects it, and checks the recorded PID from the shell.
    function startLongRunningSource(command) {
        executable.connectSource(command)
    }

    function terminateLongRunningSource(command) {
        executable.disconnectSource(command)
    }
}
