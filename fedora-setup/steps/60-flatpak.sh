#!/bin/bash
# Flathub remote and flatpak apps (packages/flatpak.txt).
# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

log "Installing flatpaks"
$SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# Fedora Workstation can already have the remote, disabled until third-party
# repositories are turned on.
$SUDO flatpak remote-modify --enable flathub
while read -r -u 3 app; do
    if flatpak info "$app" >/dev/null 2>&1; then
        info "already installed: $app"
    else
        $SUDO flatpak install -y --noninteractive --system flathub "$app"
    fi
done 3< <(read_list flatpak.txt)
