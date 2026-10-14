#!/bin/bash
# Personal dotfiles from the rcfiles repo. Only this repo is cloned; work
# repos are deliberately left out of machine setup.
# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

RCFILES="$HOME/rcfiles"
RCFILES_REPO="chaudhryjunaid/rcfiles"

log "rcfiles (~/rcfiles)"
if [ -d "$RCFILES/.git" ]; then
    info "already cloned; pulling"
    git -C "$RCFILES" pull --ff-only || warn "could not fast-forward ~/rcfiles; left as is"
else
    # SSH needs a key registered with GitHub; fall back to HTTPS (95-post can switch it later).
    if github_ssh_ok; then
        git clone "git@github.com:$RCFILES_REPO.git" "$RCFILES"
    else
        git clone "https://github.com/$RCFILES_REPO.git" "$RCFILES"
    fi
fi

# install.sh installs what the dotfiles need (antidote, bob + Neovim,
# tree-sitter, Nerd Fonts, zsh as login shell), links them, and asks for the
# git identity while ~/.gitconfig.local still has the placeholder.
log "rcfiles install.sh"
"$RCFILES/install.sh" </dev/tty
