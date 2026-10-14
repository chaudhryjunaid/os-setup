#!/bin/bash
# System upgrade, then Fedora packages (packages/dnf.txt).
# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

log "Upgrading installed packages"
$SUDO dnf upgrade -y --refresh

log "Installing Fedora packages"
# shellcheck disable=SC2046  # word-splitting the list is intended
dnf_install $(read_list dnf.txt)
