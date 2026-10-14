#!/bin/bash
# Private fonts. Nerd Fonts, antidote and zsh as login shell come from
# rcfiles' install.sh (step 90).
# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"

FONT_DIR="$HOME/.local/share/fonts"

# Commercial/private fonts aren't in this repo; copy them from wherever you keep them.
log "Private fonts (ComicCode, Aglet, Dossier, Mainboard, Inter)"
if ls "$FONT_DIR"/ComicCode* >/dev/null 2>&1; then
    info "already installed"
else
    src="$(ask "Folder with your private font files (empty to skip)")"
    src="${src/#\~/$HOME}"
    if [ -n "$src" ] && [ -d "$src" ]; then
        mkdir -p "$FONT_DIR"
        find "$src" -type f \( -iname '*.otf' -o -iname '*.ttf' \) -exec cp -v {} "$FONT_DIR/" \;
        fc-cache -f "$FONT_DIR" >/dev/null
    else
        info "skipped"
    fi
fi
