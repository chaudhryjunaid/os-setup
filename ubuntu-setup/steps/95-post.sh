#!/bin/bash
# Optional logins, then the steps that can't be automated.
# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

log "SSH key"
if ls "$HOME"/.ssh/id_* >/dev/null 2>&1; then
    info "already present"
elif confirm "Generate an ed25519 SSH key?"; then
    ssh-keygen -t ed25519 -C "$(id -un)@$(hostname)" -f "$HOME/.ssh/id_ed25519" </dev/tty
fi

if git -C "$HOME/rcfiles" remote get-url origin 2>/dev/null | grep -q '^https://' \
    && github_ssh_ok; then
    git -C "$HOME/rcfiles" remote set-url origin git@github.com:chaudhryjunaid/rcfiles.git
    info "switched ~/rcfiles remote to SSH"
fi

cat <<'NOTE'

Remaining manual steps:
  - Log out and back in so zsh, the new fonts and the libvirt group take effect.
  - Sign in to Zed.
  - gcloud auth login   (Google Cloud SDK)
  - Set the terminal font in kitty if it isn't picked up (e.g. "JetBrainsMono Nerd Font").
NOTE
