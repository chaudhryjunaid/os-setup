#!/bin/bash

# inventory.sh — report drift between this machine and the package lists.
# Run it on the reference machine after installing or removing something, then
# update packages/*.txt by hand so the install order is kept.
#
#   + <name>   installed here but not in the lists
#   - <name>   in the lists but not installed here

# shellcheck source=../lib/common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/common.sh"
export LC_ALL=C  # sort and comm must agree on ordering

# Base-system packages that ship with (or are pulled in by) the Ubuntu installer.
APT_IGNORE='^(lib.*|linux-.*|grub-.*|shim-signed|efibootmgr|ubuntu-.*|language-pack-.*|ibus-.*|m17n-db|wbritish|papers|init|dash|diffutils|findutils|grep|gzip|hostname|ncurses-.*|util-linux|wpasupplicant|unattended-upgrades)$'
# Snaps preinstalled by Ubuntu or pulled in as runtimes of other snaps.
SNAP_IGNORE='^(bare|core[0-9]*|snapd|snapd-desktop-integration|snap-store|firefox|cups|firmware-updater|desktop-security-center|prompting-client|gtk-common-themes|gnome-[0-9].*|mesa-[0-9].*|webkitgtk-.*)$'

drift() {  # drift <label> <listed-file> <installed-file>
    local out
    out="$(comm -3 "$2" "$3" | sed -e 's/^\t/+ /' -e 't' -e 's/^/- /')"
    printf '\n[%s]\n%s\n' "$1" "${out:-  in sync}"
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# apt: every package named in the lists vs. manually installed packages.
{
    read_list apt.txt; read_list apt-intel.txt
    echo golang-go default-jdk   # installed by steps/80-toolchains.sh
} | tr ' ' '\n' | grep -v '^$' | sort -u >"$tmp/apt.listed"
# Packages explicitly installed after the OS install: the non-automatic
# "Install:" entries of apt transactions not run by the installer (curtin).
for f in /var/log/apt/history.log*; do zcat -f "$f"; done | awk '
    /^Start-Date/  { skip = 0 }
    /^Commandline/ { skip = /force-unsafe-io/ }
    /^Install:/ && !skip {
        sub(/^Install: /, "")
        n = split($0, parts, /\), /)
        for (i = 1; i <= n; i++) if (parts[i] !~ /automatic/) { split(parts[i], p, ":"); print p[1] }
    }' | sort -u >"$tmp/apt.explicit"
# Installed = explicitly installed packages that are still manual, plus any
# listed manual package (some listed ones, like curl, also ship with Ubuntu).
apt-mark showmanual | sort -u >"$tmp/apt.manual"
{
    comm -12 "$tmp/apt.manual" "$tmp/apt.explicit" | grep -Ev "$APT_IGNORE" || true
    comm -12 "$tmp/apt.manual" "$tmp/apt.listed"
} | sort -u >"$tmp/apt.installed"
drift apt "$tmp/apt.listed" "$tmp/apt.installed"

read_list snap.txt | awk '{print $1}' | sort -u >"$tmp/snap.listed"
snap list 2>/dev/null | awk 'NR>1 {print $1}' | grep -Ev "$SNAP_IGNORE" | sort -u >"$tmp/snap.installed" || true
drift snap "$tmp/snap.listed" "$tmp/snap.installed"

read_list flatpak.txt | sort -u >"$tmp/flatpak.listed"
flatpak list --app --columns=application 2>/dev/null | sort -u >"$tmp/flatpak.installed" || true
drift flatpak "$tmp/flatpak.listed" "$tmp/flatpak.installed"

exit 0
