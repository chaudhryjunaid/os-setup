#!/bin/bash
# Apps installed by vendor install script, in install order.
# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

log "Claude Code"
if [ -x "$HOME/.local/bin/claude" ]; then
    info "already installed"
else
    curl -fsSL https://claude.ai/install.sh | bash
fi

log "Zed"
if [ -x "$HOME/.local/bin/zed" ]; then
    info "already installed"
else
    curl -fsSL https://zed.dev/install.sh | sh
fi

log "Google Cloud SDK (~/google-cloud-sdk)"
if [ -d "$HOME/google-cloud-sdk" ]; then
    info "already installed"
else
    # --disable-prompts leaves the rc files alone; zshrc already sources it.
    curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME"
fi
