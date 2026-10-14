# fedora-setup

One-shot setup for a Fedora 44 Workstation, adapted from my RHEL 10 setup
(`../rhel-setup`) and this machine's actual state (repos, installed packages,
flatpaks, shell history).

## Usage

On a freshly installed Fedora 44 Workstation:

```sh
./setup.sh
```

Safe to re-run — every step skips what's already present, and third-party
packages are installed best-effort.

## How this differs from the RHEL setup

- No `subscription-manager` — Fedora needs no registration.
- **RPM Fusion** (free + nonfree) replaces EPEL/CRB, which also makes
  `ffmpeg` installable.
- Modern CLI tools RHEL pulled from cargo/curl are **packaged natively**
  here, so they come from dnf: `eza`, `du-dust`, `zoxide`, `git-delta`,
  `tealdeer`, `hyperfine`, `k9s`, `shfmt`. Cargo is only a fallback.
- Docker uses the official **Fedora** Docker CE repo.

## What it does

- **Repos**: RPM Fusion free+nonfree, Docker CE (Fedora), GitHub CLI,
  Google Cloud CLI, Chrome, MongoDB 8.0 (el9 repo — no Fedora packages),
  VS Code, Sublime, TablePlus, Beyond Compare 5, Flathub
- **Docker**: removes the podman stack, installs Docker CE + compose/buildx,
  enables the service, adds user to the `docker` group
- **CLI tooling**: build toolchain, python/pipx/uv, go, rust/cargo, fzf,
  ripgrep, bat, fd, eza, dust, zoxide, delta, btop, just, yq, mongosh +
  mongo tools, gcloud, kubectl, helm, opentofu, k9s, pandoc/texlive, ffmpeg,
  hardware & monitoring utils
- **fnm** + Node 26 (default)
- **Desktop apps**: kitty, VS Code, Sublime Text/Merge, Beyond Compare,
  TablePlus, Chrome stable+beta, GNOME tweaks/extensions, LibreOffice
- **Flatpaks**: Obsidian, Slack, Zoom, Postman, Compass, DbGate, RedisInsight,
  DBeaver, Meld, Mission Center, Remmina, OnlyOffice
- **Virtualization**: qemu-kvm/libvirt/virt-manager, user in `libvirt` group
- **Cockpit** + PCP monitoring, sysstat, tuned
- **Fonts**: Noto/Liberation/DejaVu/JetBrains Mono/Inter rpms + CascadiaCode
  and JetBrainsMono Nerd Fonts
- **Shell**: zsh as login shell, liquidprompt + antidote into `~/sh`,
  clones [rcfiles](https://github.com/chaudhryjunaid/rcfiles) into `~/setup`
- **Standalone installers**: Claude Code, Zed
- **GNOME**: kitty as default terminal, dash-to-dock + appindicator enabled

## After running

1. `cd ~/setup/rcfiles && ./configure.sh && ./setup-git-identity.sh`
2. Log out/in (zsh, docker/libvirt groups, fonts)
3. `gh auth login`
4. `gcloud init && gcloud auth application-default login`
5. WebStorm: extract JetBrains tarball to `~/.local/webstorm`
