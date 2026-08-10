#!/bin/sh

set -eu

if [ -n "${CODEXBAR_LIFECYCLE_ARGS_FILE:-}" ]; then
    printf '%s\n' "$@" > "$CODEXBAR_LIFECYCLE_ARGS_FILE"
fi

if [ "${CODEXBAR_LIFECYCLE_MODE:-success}" = "block" ]; then
    : "${CODEXBAR_LIFECYCLE_PID_FILE:?}"
    printf '%s\n' "$$" > "$CODEXBAR_LIFECYCLE_PID_FILE"
    sleep 30
fi

printf '%s\n' '[{"provider":"fixture","usage":{"primary":{"usedPercent":42}}}]'
