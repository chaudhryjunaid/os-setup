#!/bin/bash
# Ubuntu-archive packages (packages/apt.txt), plus Intel GPU drivers when present.
# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

log "Updating apt package lists"
$SUDO apt-get update -y

log "Installing Ubuntu packages"
# shellcheck disable=SC2046  # word-splitting the list is intended
apt_install $(read_list apt.txt)

if have lspci && lspci | grep -Ei 'vga|display|3d' | grep -i intel >/dev/null; then
    log "Intel GPU detected: installing media/firmware packages"
    # shellcheck disable=SC2046
    apt_install $(read_list apt-intel.txt)
fi
