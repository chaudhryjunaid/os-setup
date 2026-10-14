#!/bin/bash
# Language toolchains. Installers are told not to touch rc files: PATH setup
# lives in the rcfiles dotfiles (fnm env, ~/.cargo/bin, ~/.local/bin).
# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

NODE_VERSION="26"   # matches the reference machine's fnm default

# The fnm installer uses ~/.fnm if it exists, else $XDG_DATA_HOME/fnm, else
# ~/.local/share/fnm. Check the same places, plus PATH.
find_fnm() {
    local f
    for f in "$(command -v fnm || true)" "$HOME/.fnm/fnm" \
        "${XDG_DATA_HOME:+$XDG_DATA_HOME/fnm/fnm}" "$HOME/.local/share/fnm/fnm"; do
        [ -n "$f" ] && [ -x "$f" ] && { printf '%s' "$f"; return; }
    done
}

log "fnm + Node $NODE_VERSION"
FNM="$(find_fnm)"
if [ -n "$FNM" ]; then
    info "fnm already installed: $FNM"
else
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
    FNM="$(find_fnm)"
    [ -n "$FNM" ] || { warn "fnm installed but not found in any known location"; exit 1; }
fi
if [[ "$("$FNM" list)" == *"v$NODE_VERSION."* ]]; then
    info "Node $NODE_VERSION already installed"
else
    "$FNM" install "$NODE_VERSION"
fi
"$FNM" default "$NODE_VERSION"

log "Python: uv"
if [ -x "$HOME/.local/bin/uv" ]; then
    info "already installed"
else
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
fi

log "Rust: rustup"
if [ -x "$HOME/.cargo/bin/rustup" ]; then
    info "already installed"
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi

log "Go and Java"
apt_install golang-go default-jdk
