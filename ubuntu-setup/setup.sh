#!/bin/bash

# setup.sh — rebuild this dev machine on a fresh Ubuntu install.
# Runs steps/NN-*.sh in numeric order. Every step is safe to re-run.
#
# Usage:
#   ./setup.sh             # run all steps
#   ./setup.sh --from 50   # resume from step 50
#   ./setup.sh --only 70   # run just step 70

# shellcheck source=lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/common.sh"

FROM=0
ONLY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --from|--only)
            [[ "${2:-}" =~ ^[0-9]+$ ]] || { echo "$1 needs a step number, e.g. $1 50" >&2; exit 1; }
            if [ "$1" = --from ]; then FROM="$2"; else ONLY="$2"; fi
            shift 2 ;;
        -h|--help) sed -n '3,10p' "$0"; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

if ! have apt-get; then
    echo "This script targets Ubuntu (apt-get not found)." >&2
    exit 1
fi

# Ask for sudo once up front and keep the timestamp fresh while we run.
if [ -n "$SUDO" ]; then
    sudo -v
    while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
fi

for step in "$ROOT"/steps/[0-9][0-9]-*.sh; do
    name="$(basename "$step")"
    num="${name%%-*}"
    if [ -n "$ONLY" ]; then
        [ "$num" = "$ONLY" ] || continue
    elif [ "$((10#$num))" -lt "$((10#$FROM))" ]; then
        continue
    fi
    printf '\n###### %s ######\n' "$name"
    if ! bash "$step"; then
        echo >&2
        echo "Step $name failed. Fix the problem and resume with: ./setup.sh --from $num" >&2
        exit 1
    fi
done

printf '\nAll steps done.\n'
