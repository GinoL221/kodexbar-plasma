#!/bin/sh

set -eu

if [ -n "${CODEXBAR_COST_ARGS_FILE:-}" ]; then
    printf '%s\n' "$@" > "$CODEXBAR_COST_ARGS_FILE"
fi

if [ "${CODEXBAR_COST_MODE:-success}" = "block" ]; then
    : "${CODEXBAR_COST_PID_FILE:?}"
    # Only the first invocation blocks (recording its PID once); a later
    # replacement invocation must complete immediately so the harness can
    # verify the ORIGINAL process, not the replacement, was terminated.
    if [ ! -e "$CODEXBAR_COST_PID_FILE" ]; then
        printf '%s\n' "$$" > "$CODEXBAR_COST_PID_FILE"
        sleep 30
    fi
fi

provider="${3:-codex}"
printf '%s\n' "[{\"provider\":\"$provider\",\"source\":\"local\",\"sessionCostUSD\":0,\"sessionTokens\":0,\"last30DaysCostUSD\":1.5,\"last30DaysTokens\":42}]"
