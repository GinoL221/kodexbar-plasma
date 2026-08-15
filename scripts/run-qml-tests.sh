#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
runner=$(command -v qmltestrunner 2>/dev/null || true)

if [ -z "$runner" ]; then
    for candidate in /usr/lib/qt6/bin/qmltestrunner /usr/lib64/qt6/bin/qmltestrunner; do
        if [ -x "$candidate" ]; then
            runner=$candidate
            break
        fi
    done
fi

if [ -z "$runner" ]; then
    printf '%s\n' "error: qmltestrunner was not found in PATH, /usr/lib/qt6/bin, or /usr/lib64/qt6/bin" >&2
    exit 1
fi

printf 'Using QtTest runner: %s\n' "$runner"
for test_file in "$repo_root/tests/UsageModelTest.qml" "$repo_root/tests/UsageControllerFixture.qml" "$repo_root/tests/SettingsInteractionTest.qml"; do
    printf 'Running %s\n' "${test_file#"$repo_root/"}"
    QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
        "$runner" -input "$test_file" -import "$repo_root"
done

for color_scheme in BreezeLight.colors BreezeDark.colors; do
    printf 'Running tests/ProviderDetailsIntegrationTest.qml with %s\n' "$color_scheme"
    KDE_COLOR_SCHEME="/usr/share/color-schemes/$color_scheme" \
        QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
        "$runner" -input "$repo_root/tests/ProviderDetailsIntegrationTest.qml" -import "$repo_root"
done

printf 'Running tests/test_cli_contract_fixture.py\n'
python3 "$repo_root/tests/test_cli_contract_fixture.py"

for harness in \
    RequestTimeoutHarness \
    PreferredWindowHarness \
    RequestTimeoutSettingsHarness \
    RefreshIntervalHarness \
    UsageModelHarness \
    UsageControllerHarness \
    UsageControllerFailureHarness \
    UsageControllerLifecycleHarness \
    UsageControllerDataSourceLifecycleHarness \
    UsageControllerPreflightHarness \
    UsageControllerPathCheckHarness \
    CodexBarPathResolverHarness \
    TimeoutFeedbackPopupHarness \
    MainCompactHarness \
    CompactUsageButtonHarness \
    ProviderRowHarness \
    ProviderDetailsHarness \
    ProviderSelectorHarness \
    ErrorSummaryHarness; do
    printf 'Running tests/%s.qml\n' "$harness"
    if [ "$harness" = "UsageControllerDataSourceLifecycleHarness" ]; then
        args_file=$(mktemp)
        pid_file=$(mktemp)
        rm -f "$pid_file"
        trap 'rm -f "$args_file" "$pid_file"' EXIT HUP INT TERM
        CODEXBAR_LIFECYCLE_ARGS_FILE="$args_file" \
            QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
            qml6 --software -f "$repo_root/tests/$harness.qml" -- "$repo_root/tests/fixtures/codexbar-lifecycle-fixture.sh"
        expected_args='usage
--provider
all
--format
json
--json-only'
        if ! printf '%s\n' "$expected_args" | cmp -s - "$args_file"; then
            printf '%s\n' "error: lifecycle fixture received unexpected argv" >&2
            exit 1
        fi
        rm -f "$args_file" "$pid_file"
        trap - EXIT HUP INT TERM
    else
        QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
            qml6 --software -f "$repo_root/tests/$harness.qml"
    fi
done

printf 'Running tests/UsageControllerTerminationHarness.qml\n'
args_file=$(mktemp)
pid_file=$(mktemp)
rm -f "$pid_file"
trap 'rm -f "$args_file" "$pid_file"' EXIT HUP INT TERM
CODEXBAR_LIFECYCLE_MODE=block CODEXBAR_LIFECYCLE_ARGS_FILE="$args_file" CODEXBAR_LIFECYCLE_PID_FILE="$pid_file" \
    QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    qml6 --software -f "$repo_root/tests/UsageControllerTerminationHarness.qml" -- "$repo_root/tests/fixtures/codexbar-lifecycle-fixture.sh"
if [ ! -s "$pid_file" ]; then
    printf '%s\n' "error: lifecycle fixture did not record a PID" >&2
    exit 1
fi
read -r pid < "$pid_file"
if kill -0 "$pid" 2>/dev/null; then
    printf '%s\n' "error: disconnect did not terminate the executable fixture" >&2
    exit 1
fi
