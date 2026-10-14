# shellcheck shell=bash
# Shared helpers, sourced by setup.sh and every steps/*.sh script.

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
export ROOT

# Use sudo only when not already root.
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

log()  { printf '\n==> %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '    WARN: %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

pkg_installed() { rpm -q --quiet --whatprovides "$1"; }

# Print the entries of a packages/*.txt list: strips comments and blank lines.
read_list() {
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$ROOT/packages/$1" | grep -v '^[[:space:]]*$' || true
}

# dnf install only the packages that aren't installed yet, in one transaction.
# Packages dnf doesn't know (renamed or retired in a newer release) are
# skipped with a warning, so one stale name doesn't fail the whole install.
dnf_install() {
    local missing=() p
    for p in "$@"; do
        pkg_installed "$p" || missing+=("$p")
    done
    if [ "${#missing[@]}" -eq 0 ]; then
        info "nothing to install from: $*"
        return
    fi
    info "installing: ${missing[*]}"
    $SUDO dnf install -y --skip-unavailable "${missing[@]}"
}

# Prompts read from the terminal so they work even when stdin is redirected;
# with no terminal they return the default (skip).
ask() {  # ask "Question" [default] -> echoes the answer
    local reply=""
    { printf '    %s%s: ' "$1" "${2:+ [$2]}" >/dev/tty && read -r reply </dev/tty; } 2>/dev/null || reply=""
    printf '%s' "${reply:-${2:-}}"
}

confirm() {  # confirm "Question" -> 0 on yes (default no)
    local reply=""
    { printf '    %s [y/N] ' "$1" >/dev/tty && read -r reply </dev/tty; } 2>/dev/null || reply=""
    case "$reply" in [yY]|[yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}
