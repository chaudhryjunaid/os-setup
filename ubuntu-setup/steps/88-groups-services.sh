#!/bin/bash
# Group memberships and services for virtualization.
# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

log "User groups"
for group in libvirt kvm; do
    if ! getent group "$group" >/dev/null; then
        warn "group $group does not exist"
    elif id -nG "$(id -un)" | tr ' ' '\n' | grep -qx "$group"; then
        info "already in $group"
    else
        $SUDO usermod -aG "$group" "$(id -un)"
        info "added to $group (takes effect after logging out and back in)"
    fi
done

log "Services"
if systemctl is-enabled --quiet libvirtd 2>/dev/null; then
    info "already enabled: libvirtd"
else
    $SUDO systemctl enable --now libvirtd
fi
