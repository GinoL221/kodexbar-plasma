import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support
import "../contents/code/CodexBarPathResolver.js" as Resolver

Item {
    id: root
    property bool assertionFailed: false
    property int runtimeScenarioIndex: 0
    property string runtimeSource: ""

    readonly property var runtimeScenarios: ["multiple", "undefined", "relative", "missing"]

    function assert(condition, message) {
        if (!condition) {
            console.error("CodexBarPathResolverHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    function runtimeCommand(scenario) {
        var setup = "tmp=$(mktemp -d) || exit 125; "
            + "trap 'rm -rf \"$tmp\"' EXIT HUP INT TERM; "
            + "mkdir -p \"$tmp/home/.local/bin\" \"$tmp/brew/bin\"; "
            + "case " + Resolver.shellQuote(scenario) + " in "
            + "multiple) : > \"$tmp/home/.local/bin/codexbar\"; : > \"$tmp/brew/bin/codexbar\"; "
            + "chmod +x \"$tmp/home/.local/bin/codexbar\" \"$tmp/brew/bin/codexbar\"; "
            + "HOME=\"$tmp/home\"; HOMEBREW_PREFIX=\"$tmp/brew\";; "
            + "undefined) HOME=\"$tmp/home\"; unset HOMEBREW_PREFIX;; "
            + "relative) HOME=\"$tmp/home\"; HOMEBREW_PREFIX=relative-prefix;; "
            + "missing) HOME=\"$tmp/home\"; HOMEBREW_PREFIX=\"$tmp/brew\";; esac; "
            + "test() { case \"$2\" in \"$HOME/.local/bin/codexbar\"|\"$HOMEBREW_PREFIX/bin/codexbar\") command test \"$@\";; *) return 1;; esac; }; "
            + Resolver.discoveryCommand()
        return "/bin/sh -c " + Resolver.shellQuote(setup)
    }

    function runNextRuntimeScenario() {
        if (runtimeScenarioIndex >= runtimeScenarios.length) {
            finish()
            return
        }
        runtimeSource = runtimeCommand(runtimeScenarios[runtimeScenarioIndex])
        runtimeProbe.connectSource(runtimeSource)
    }

    Component.onCompleted: {
        var discovery = Resolver.discoveryCommand()
        assert(Resolver.validateAbsolutePath("/opt/Codex Bar/codexbar").valid,
               "absolute paths containing spaces must validate")
        assert(!Resolver.validateAbsolutePath("codexbar").valid,
               "relative paths must fail closed")
        assert(!Resolver.validateAbsolutePath("/tmp/codexbar\nnext").valid,
               "line-break paths must fail closed")
        assert(Resolver.pathCheckCommand("/tmp/cli dir/codexbar'$(unsafe)")
                   === "test -x '/tmp/cli dir/codexbar'\\''$(unsafe)'",
               "path checks must shell-quote spaces and metacharacters")
        assert(Resolver.pathCheckCommand("relative") === "",
               "invalid paths must not construct executable probes")
        assert(discovery.indexOf('"${HOME-}"') !== -1,
               "discovery must use the bounded HOME expansion")
        assert(discovery.indexOf("/usr/local/bin/codexbar") < discovery.indexOf("/usr/bin/codexbar"),
               "system candidates must remain in deterministic order")
        assert(discovery.indexOf("/usr/bin/codexbar") < discovery.indexOf('"${HOMEBREW_PREFIX-}"'),
               "Homebrew must remain the final optional candidate")
        assert(discovery.indexOf("test -x \"$candidate\"") !== -1,
               "every discovery candidate must use the executable preflight")
        assert(discovery.indexOf("PATH") === -1 && discovery.indexOf("command -v") === -1
                    && discovery.indexOf("find ") === -1 && discovery.indexOf("findExecutable") === -1,
                "discovery must not use PATH lookup or filesystem scanning")
        runNextRuntimeScenario()
    }

    Plasma5Support.DataSource {
        id: runtimeProbe
        engine: "executable"

        onNewData: function(sourceName, data) {
            if (sourceName !== root.runtimeSource) {
                return
            }

            runtimeProbe.disconnectSource(sourceName)
            var scenario = root.runtimeScenarios[root.runtimeScenarioIndex]
            var exitCode = Number(data["exit code"])
            var stdout = String(data.stdout || "").replace(/\r?\n$/, "")
            if (scenario === "multiple") {
                assert(exitCode === 0, "multiple executable fixture candidates must resolve")
                assert(/\/home\/\.local\/bin\/codexbar$/.test(stdout),
                       "the earliest executable fixture candidate must win")
            } else {
                assert(exitCode !== 0, scenario + " Homebrew prefix must fail closed")
                assert(stdout === "", scenario + " Homebrew prefix must not emit a candidate")
            }

            root.runtimeScenarioIndex += 1
            Qt.callLater(root.runNextRuntimeScenario)
        }
    }
}
