#!/bin/bash
# Optional SSH key and git identity. Both are skipped when already set up, or
# when there is no terminal to ask on.
# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

log "SSH key"
if ls "$HOME"/.ssh/id_* >/dev/null 2>&1; then
    info "already present"
elif confirm "Generate an ed25519 SSH key?"; then
    [ -d "$HOME/.ssh" ] || mkdir -m 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$(id -un)@$(uname -n)" -f "$HOME/.ssh/id_ed25519" </dev/tty
else
    info "skipped"
fi

log "Git identity"
for key in user.name user.email; do
    if value="$(git config --global "$key")"; then
        info "$key already set: $value"
    else
        value="$(ask "git $key (empty to skip)")"
        if [ -n "$value" ]; then
            git config --global "$key" "$value"
        else
            info "skipped $key"
        fi
    fi
done
