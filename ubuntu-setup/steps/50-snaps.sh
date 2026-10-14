#!/bin/bash
# Snap apps (packages/snap.txt).
# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

log "Installing snaps"
while read -r -u 3 name flags; do
    if snap list "$name" >/dev/null 2>&1; then
        info "already installed: $name"
    else
        # shellcheck disable=SC2086
        $SUDO snap install "$name" $flags
    fi
done 3< <(read_list snap.txt)
