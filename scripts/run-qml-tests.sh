#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tests_dir="$repo_root/tests"
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

fail() {
    printf '%s\n' "error: $*" >&2
    exit 1
}

run_offscreen_qml6() {
    QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
        qml6 --software -f "$1" ${2+"$2"}
}

# Harnesses that need fixtures/env beyond a plain qml6 invocation.
is_special_harness() {
    case "$1" in
        UsageControllerDataSourceLifecycleHarness|\
        CostControllerDataSourceLifecycleHarness|\
        UsageControllerTerminationHarness|\
        CostControllerTerminationHarness)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

run_usage_lifecycle_harness() {
    args_file=$(mktemp)
    pid_file=$(mktemp)
    rm -f "$pid_file"
    trap 'rm -f "$args_file" "$pid_file"' EXIT HUP INT TERM
    CODEXBAR_LIFECYCLE_ARGS_FILE="$args_file" \
        QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
        qml6 --software -f "$tests_dir/UsageControllerDataSourceLifecycleHarness.qml" -- \
        "$tests_dir/fixtures/codexbar-lifecycle-fixture.sh"
    expected_args='usage
--provider
all
--format
json
--json-only'
    if ! printf '%s\n' "$expected_args" | cmp -s - "$args_file"; then
        fail "lifecycle fixture received unexpected argv"
    fi
    rm -f "$args_file" "$pid_file"
    trap - EXIT HUP INT TERM
}

run_cost_lifecycle_harness() {
    args_file=$(mktemp)
    trap 'rm -f "$args_file"' EXIT HUP INT TERM
    CODEXBAR_COST_ARGS_FILE="$args_file" \
        QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
        qml6 --software -f "$tests_dir/CostControllerDataSourceLifecycleHarness.qml" -- \
        "$tests_dir/fixtures/codexbar-cost-lifecycle-fixture.sh"
    expected_args='cost
--provider
codex
--format
json
--json-only'
    if ! printf '%s\n' "$expected_args" | cmp -s - "$args_file"; then
        fail "cost fixture received unexpected argv"
    fi
    rm -f "$args_file"
    trap - EXIT HUP INT TERM
}

run_usage_termination_harness() {
    args_file=$(mktemp)
    pid_file=$(mktemp)
    rm -f "$pid_file"
    trap 'rm -f "$args_file" "$pid_file"' EXIT HUP INT TERM
    CODEXBAR_LIFECYCLE_MODE=block CODEXBAR_LIFECYCLE_ARGS_FILE="$args_file" CODEXBAR_LIFECYCLE_PID_FILE="$pid_file" \
        QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
        qml6 --software -f "$tests_dir/UsageControllerTerminationHarness.qml" -- \
        "$tests_dir/fixtures/codexbar-lifecycle-fixture.sh"
    if [ ! -s "$pid_file" ]; then
        fail "lifecycle fixture did not record a PID"
    fi
    read -r pid < "$pid_file"
    if kill -0 "$pid" 2>/dev/null; then
        fail "disconnect did not terminate the executable fixture"
    fi
    rm -f "$args_file" "$pid_file"
    trap - EXIT HUP INT TERM
}

run_cost_termination_harness() {
    pid_file=$(mktemp -u)
    rm -f "$pid_file"
    trap 'rm -f "$pid_file"' EXIT HUP INT TERM
    CODEXBAR_COST_MODE=block CODEXBAR_COST_PID_FILE="$pid_file" \
        QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
        qml6 --software -f "$tests_dir/CostControllerTerminationHarness.qml" -- \
        "$tests_dir/fixtures/codexbar-cost-lifecycle-fixture.sh"
    if [ ! -s "$pid_file" ]; then
        fail "cost lifecycle fixture did not record a PID"
    fi
    read -r pid < "$pid_file"
    if kill -0 "$pid" 2>/dev/null; then
        fail "replacing an in-flight cost request did not terminate the superseded process"
    fi
    rm -f "$pid_file"
    trap - EXIT HUP INT TERM
}

printf 'Using QtTest runner: %s\n' "$runner"

for test_file in \
    "$tests_dir/UsageModelTest.qml" \
    "$tests_dir/UsageControllerFixture.qml" \
    "$tests_dir/SettingsInteractionTest.qml"
do
    printf 'Running %s\n' "${test_file#"$repo_root/"}"
    QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
        "$runner" -input "$test_file" -import "$repo_root"
done

for color_scheme in BreezeLight.colors BreezeDark.colors; do
    printf 'Running tests/ProviderDetailsIntegrationTest.qml with %s\n' "$color_scheme"
    KDE_COLOR_SCHEME="/usr/share/color-schemes/$color_scheme" \
        QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
        "$runner" -input "$tests_dir/ProviderDetailsIntegrationTest.qml" -import "$repo_root"
done

printf 'Running tests/test_cli_contract_fixture.py\n'
python3 "$tests_dir/test_cli_contract_fixture.py"

printf 'Running tests/test_run_qml_tests_discovery.py\n'
python3 "$tests_dir/test_run_qml_tests_discovery.py"

# Auto-discover plain *Harness.qml (alphabetical). Special lifecycle harnesses
# are skipped here and run with their fixture/env contracts below.
plain_count=0
for harness_path in "$tests_dir"/*Harness.qml; do
    [ -f "$harness_path" ] || fail "no tests/*Harness.qml files found"
    harness=$(basename "$harness_path" .qml)
    if is_special_harness "$harness"; then
        continue
    fi
    plain_count=$((plain_count + 1))
    printf 'Running tests/%s.qml\n' "$harness"
    run_offscreen_qml6 "$harness_path"
done
[ "$plain_count" -gt 0 ] || fail "auto-discover found zero plain harnesses"

printf 'Running tests/UsageControllerDataSourceLifecycleHarness.qml\n'
run_usage_lifecycle_harness

printf 'Running tests/CostControllerDataSourceLifecycleHarness.qml\n'
run_cost_lifecycle_harness

printf 'Running tests/UsageControllerTerminationHarness.qml\n'
run_usage_termination_harness

printf 'Running tests/CostControllerTerminationHarness.qml\n'
run_cost_termination_harness
