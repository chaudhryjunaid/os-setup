#!/bin/bash

# setup.sh — configure a pristine Fedora 44 Workstation like this one.
#
# Adapted from the RHEL 10 setup (../rhel-setup) for Fedora: RPM Fusion
# replaces EPEL/CRB, there is no subscription to register, and most of the
# modern CLI tools RHEL needed from cargo/curl are packaged natively here
# (eza, dust, zoxide, git-delta, k9s, ffmpeg, ...), so they come from dnf.
#
# Reconstructed from this machine's state (dnf history, /etc/yum.repos.d,
# flatpak list, ~/.bash_history / ~/.zsh_history) plus the RHEL script.
# Safe to re-run: every step skips what is already present, and optional
# packages are best-effort.
#
# Prerequisites:
#   - Fedora 44 Workstation (dnf5)
#   - Run as your normal user (uses sudo where needed), from a terminal
#
# After this, from ~/setup/rcfiles:
#   ./configure.sh && ./setup-git-identity.sh
# then log out/in to pick up zsh, docker/libvirt groups, and fonts.

set -euo pipefail

SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

FEDORA_VER="$(rpm -E %fedora)"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m    WARN: %s\033[0m\n' "$*" >&2; }

# Install packages best-effort, one at a time, so a missing package
# (repo drift, arch, retired) doesn't abort the run.
dnf_opt() {
    local pkg
    for pkg in "$@"; do
        if rpm -q "$pkg" >/dev/null 2>&1; then
            continue
        fi
        if $SUDO dnf install -y "$pkg" >/dev/null 2>&1; then
            echo "    installed: $pkg"
        else
            warn "'$pkg' unavailable — install manually if you want it"
        fi
    done
}

add_repo() {  # add_repo <name> <heredoc on stdin>
    local file="/etc/yum.repos.d/$1.repo"
    if [ -f "$file" ]; then
        echo "    repo exists: $1"
    else
        $SUDO tee "$file" >/dev/null
        echo "    repo added: $1"
    fi
}

# ---------------------------------------------------------------------------
log "Enabling RPM Fusion (free + nonfree)"
rpm -q rpmfusion-free-release >/dev/null 2>&1 \
    || $SUDO dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
    || warn "RPM Fusion free install failed"
rpm -q rpmfusion-nonfree-release >/dev/null 2>&1 \
    || $SUDO dnf install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm" \
    || warn "RPM Fusion nonfree install failed"

# ---------------------------------------------------------------------------
log "Adding third-party repos"

add_repo gh-cli <<'EOF'
[gh-cli]
name=packages for the GitHub CLI
baseurl=https://cli.github.com/packages/rpm
enabled=1
gpgcheck=1
gpgkey=https://cli.github.com/packages/githubcli-archive-keyring.asc
EOF

# repo_gpgcheck=0 matches Google's documented config (their repo metadata
# signing is unreliable with dnf); package signatures are still verified.
# The el* baseurl is distro-agnostic and works fine on Fedora.
add_repo google-cloud-sdk <<'EOF'
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el10-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key-v10.gpg
EOF

add_repo google-chrome <<'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

# Official Docker CE repo for Fedora ($releasever/$basearch expand at runtime).
add_repo docker-ce <<'EOF'
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://download.docker.com/linux/fedora/$releasever/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOF

# NOTE: MongoDB does not publish Fedora packages; the redhat/9 repo works here.
add_repo mongodb-org-8.0 <<'EOF'
[mongodb-org-8.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/8.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-8.0.asc
EOF

add_repo vscode <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

add_repo sublime-text <<'EOF'
[sublime-text]
name=Sublime Text - x86_64 - stable
baseurl=https://download.sublimetext.com/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://download.sublimetext.com/sublimehq-rpm-pub.gpg
EOF

add_repo tableplus <<'EOF'
[tableplus]
name=TablePlus - x86_64 - Stable
baseurl=https://yum.tableplus.com/rpm/x86_64
enabled=1
gpgcheck=1
gpgkey=https://yum.tableplus.com/apt.tableplus.com.gpg.key
EOF

add_repo scootersoftware <<'EOF'
[scootersoftware]
name=Scooter Software
baseurl=https://www.scootersoftware.com/rpm/bcompare5
enabled=1
gpgcheck=1
gpgkey=https://www.scootersoftware.com/RPM-GPG-KEY-scootersoftware
EOF

$SUDO dnf makecache >/dev/null

# ---------------------------------------------------------------------------
log "Replacing podman stack with Docker CE"
if ! command -v docker >/dev/null 2>&1; then
    systemctl --user stop podman.socket podman.service 2>/dev/null || true
    $SUDO systemctl stop podman.socket podman.service 2>/dev/null || true
    $SUDO dnf remove -y podman podman-docker podman-plugins podman-compose buildah skopeo >/dev/null 2>&1 || true
    $SUDO dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
$SUDO systemctl enable --now docker
$SUDO groupadd -f docker
$SUDO usermod -aG docker "$USER"

# ---------------------------------------------------------------------------
log "Installing CLI tooling (dnf)"

# Shell, editors, VCS
dnf_opt zsh git gh tig vim-enhanced neovim emacs tmux screen

# Build toolchain
dnf_opt gcc gcc-c++ make cmake ninja-build pkgconf-pkg-config autoconf automake \
    libtool patch diffutils elfutils binutils perf ShellCheck shfmt editorconfig

# Languages & package managers
dnf_opt python3 python3-pip pipx uv golang rust cargo

# Modern CLI replacements & utilities (mostly packaged natively on Fedora)
dnf_opt fzf ripgrep bat fd-find eza du-dust zoxide git-delta tealdeer \
    duf htop btop ncdu cloc just yq jq aria2 cheat hyperfine \
    socat mtr nethogs iftop iotop-c

# Archive / transfer
dnf_opt rsync tar zip unzip xz zstd curl wget openssh-clients rclone restic borgbackup

# Databases (clients only — servers run in containers)
dnf_opt sqlite mongodb-mongosh mongodb-database-tools

# Cloud & k8s
dnf_opt google-cloud-cli kubectl helm opentofu k9s

# Docs & media (ffmpeg from RPM Fusion)
dnf_opt pandoc texlive poppler-utils ImageMagick ffmpeg asciinema qrencode

# Hardware / monitoring / power
dnf_opt sysstat smartmontools nvme-cli lm_sensors powertop tuned kernel-tools \
    ethtool pciutils usbutils dmidecode lshw wireshark-cli nmap audit

# ---------------------------------------------------------------------------
log "Installing desktop apps (dnf)"
dnf_opt kitty code sublime-text sublime-merge bcompare tableplus \
    google-chrome-stable google-chrome-beta \
    gnome-tweaks gnome-extensions-app gnome-shell-extension-appindicator \
    gnome-shell-extension-dash-to-dock gnome-shell-extension-system-monitor-applet \
    gnome-browser-connector gnome-disk-utility gnome-system-monitor \
    gnome-text-editor dconf-editor seahorse firewall-config evince
dnf_opt libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-draw

# ---------------------------------------------------------------------------
log "Installing fonts"
dnf_opt google-noto-fonts-common google-noto-sans-fonts google-noto-serif-fonts \
    google-noto-emoji-fonts liberation-fonts dejavu-sans-fonts dejavu-serif-fonts \
    jetbrains-mono-fonts rsms-inter-fonts

FONT_DIR="$HOME/.local/share/fonts"
NERD_BASE="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
fonts_changed=0
for font in CascadiaCode JetBrainsMono; do
    dest="$FONT_DIR/${font}Nerd"
    if [ -d "$dest" ] && [ -n "$(ls -A "$dest" 2>/dev/null)" ]; then
        continue
    fi
    log "Installing $font Nerd Font"
    mkdir -p "$dest"
    tmpzip=$(mktemp --suffix=.zip)
    curl -fsSL -o "$tmpzip" "$NERD_BASE/$font.zip"
    unzip -o "$tmpzip" -d "$dest" >/dev/null
    rm -f "$tmpzip"
    fonts_changed=1
done
[ "$fonts_changed" -eq 1 ] && fc-cache -f "$FONT_DIR" >/dev/null

# ---------------------------------------------------------------------------
log "Installing virtualization stack (KVM/libvirt)"
dnf_opt qemu-kvm libvirt libvirt-client virt-install virt-viewer virt-manager \
    virt-top edk2-ovmf swtpm guestfs-tools libosinfo bridge-utils virtio-win
$SUDO systemctl enable --now libvirtd 2>/dev/null || warn "could not enable libvirtd"
$SUDO usermod -aG libvirt "$USER" 2>/dev/null || true

# ---------------------------------------------------------------------------
log "Enabling Cockpit and monitoring services"
$SUDO systemctl enable --now cockpit.socket 2>/dev/null || warn "could not enable cockpit"
dnf_opt pcp cockpit-pcp
$SUDO systemctl enable --now pmcd 2>/dev/null || true
$SUDO systemctl enable --now sysstat lm_sensors tuned 2>/dev/null || true

# ---------------------------------------------------------------------------
log "Installing Flatpaks"
if command -v flatpak >/dev/null 2>&1; then
    $SUDO flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y --noninteractive flathub \
        md.obsidian.Obsidian \
        com.slack.Slack \
        us.zoom.Zoom \
        com.getpostman.Postman \
        com.mongodb.Compass \
        org.dbgate.DbGate \
        com.redis.RedisInsight \
        io.dbeaver.DBeaverCommunity \
        org.gnome.meld \
        io.missioncenter.MissionCenter \
        org.remmina.Remmina \
        org.onlyoffice.desktopeditors \
        || warn "some flatpaks failed to install"
else
    warn "flatpak not found — skipping flatpak apps"
fi

# ---------------------------------------------------------------------------
# Fall back to cargo only for crates Fedora doesn't package; the common
# ones (eza, dust, zoxide, delta, tealdeer, hyperfine) came from dnf above.
log "Installing cargo tools not packaged for Fedora"
export PATH="$HOME/.cargo/bin:$PATH"
if command -v cargo >/dev/null 2>&1; then
    for crate in eza du-dust zoxide tealdeer hyperfine git-delta; do
        bin="${crate/du-dust/dust}"; bin="${bin/tealdeer/tldr}"
        command -v "$bin" >/dev/null 2>&1 || cargo install "$crate" || warn "cargo install $crate failed"
    done
else
    warn "cargo not available — skipping"
fi

# ---------------------------------------------------------------------------
# fnm, Claude Code, and Zed below use the vendors' official curl|bash
# installers over TLS — accepted risk for a personal workstation; review
# the scripts at their URLs if that trust level ever changes.
log "Installing fnm + Node 26"
if ! command -v fnm >/dev/null 2>&1 && [ ! -d "$HOME/.local/share/fnm" ]; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi
export PATH="$HOME/.local/share/fnm:$PATH"
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --shell bash)" || true
    fnm list 2>/dev/null | grep -q v26 || fnm install 26 || true
    fnm default 26 || true
fi

# ---------------------------------------------------------------------------
log "Setting up shell environment (zsh, liquidprompt, antidote, dotfiles)"
mkdir -p "$HOME/sh" "$HOME/setup"
# liquidprompt is not packaged for Fedora — clone the stable branch.
[ -d "$HOME/sh/liquidprompt" ] \
    || git clone --branch stable https://github.com/liquidprompt/liquidprompt.git "$HOME/sh/liquidprompt"
[ -d "$HOME/sh/antidote" ] \
    || git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/sh/antidote"
[ -d "$HOME/setup/rcfiles" ] \
    || git clone git@github.com:chaudhryjunaid/rcfiles.git "$HOME/setup/rcfiles" \
    || warn "could not clone rcfiles (SSH key not set up yet?)"

ZSH_BIN="$(command -v zsh || true)"
if [ -n "$ZSH_BIN" ] && [ "$(getent passwd "$USER" | cut -d: -f7)" != "$ZSH_BIN" ]; then
    $SUDO chsh -s "$ZSH_BIN" "$USER" || warn "could not change shell; run: chsh -s $ZSH_BIN"
fi

# ---------------------------------------------------------------------------
log "Creating home directory skeleton"
mkdir -p "$HOME"/{can,work,personal,projects,backups,archive,inbox,homelab,data}

# ---------------------------------------------------------------------------
log "Installing standalone tools (Claude Code, Zed)"
command -v claude >/dev/null 2>&1 || curl -fsSL https://claude.ai/install.sh | bash
command -v zed    >/dev/null 2>&1 || curl -fsSL https://zed.dev/install.sh | sh

# ---------------------------------------------------------------------------
log "Applying GNOME settings"
if command -v gsettings >/dev/null 2>&1 && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true
    gsettings set org.gnome.desktop.default-applications.terminal exec-arg '' 2>/dev/null || true
    for ext in dash-to-dock@micxgx.gmail.com appindicatorsupport@rgcjonas.gmail.com; do
        gnome-extensions enable "$ext" 2>/dev/null || true
    done
else
    warn "no GNOME session — skipping gsettings (re-run from a desktop terminal)"
fi

# ---------------------------------------------------------------------------
log "Updating system"
$SUDO dnf update -y --refresh >/dev/null 2>&1 || warn "dnf update failed"

# ---------------------------------------------------------------------------
cat <<'NOTE'

Done. Manual follow-ups:
  1. cd ~/setup/rcfiles && ./configure.sh && ./setup-git-identity.sh
  2. Log out/in — picks up zsh, docker & libvirt groups, fonts.
  3. gh auth login            (then re-run this script to clone work repos)
  4. gcloud init && gcloud auth application-default login
  5. claude mcp add --scope user gcloud -- npx -y @google-cloud/gcloud-mcp
  6. WebStorm: download tarball from jetbrains.com, extract to ~/.local/webstorm
     (PATH is already handled by ~/.zshrc from rcfiles).
  7. GNOME extensions from extensions.gnome.org: Astra Monitor.
  8. Set terminal font to "CaskaydiaCove Nerd Font" or "JetBrainsMono Nerd Font".
NOTE
