# ubuntu-setup

Rebuilds my Ubuntu dev machine after a reinstall: apps, dev toolchains and dotfiles, in a fixed order, with no menus. Everything is plain bash, and every step is safe to re-run.

The app set is taken from what is actually installed on the reference machine (Ubuntu 26.04 "resolute"). Dotfiles come from [rcfiles](https://github.com/chaudhryjunaid/rcfiles). Work repos are never cloned.

## Fresh machine

```sh
sudo apt install -y git
git clone https://github.com/chaudhryjunaid/os-setup ~/setup/os-setup
~/setup/os-setup/ubuntu-setup/setup.sh
```

It asks for sudo once. After that it only prompts for things it can't know: git identity, where your private fonts are, and whether to generate an SSH key. Log out and back in when it finishes.

```sh
./setup.sh --from 50   # resume after a failure
./setup.sh --only 70   # re-run one step
```

## Steps

| Step | What it does |
|---|---|
| `10-apt-base` | Ubuntu-archive packages (`packages/apt.txt`), plus Intel GPU drivers when an Intel GPU is present |
| `50-snaps` | OnlyOffice, Foliate |
| `60-flatpak` | Gear Lever |
| `70-manual-installs` | Claude Code, Zed, Google Cloud SDK |
| `80-toolchains` | fnm + Node 26, uv, rustup, Go, Java |
| `85-fonts` | private fonts, copied from a folder you give it |
| `88-groups-services` | libvirt/kvm groups; libvirtd service |
| `90-dotfiles` | clone rcfiles and run its `install.sh`: antidote, bob + Neovim, tree-sitter, Nerd Fonts, zsh as login shell, dotfile links, git identity |
| `95-post` | optional SSH key, then the list of manual sign-ins |

Package lists are in the order things were installed on the reference machine.

## Keeping it in sync

After installing or removing something on the reference machine:

```sh
bin/inventory.sh
```

It lists what's installed but not in `packages/*.txt` (`+`), and what's listed but missing (`-`). Update the lists by hand so the order is kept. Only Ubuntu-archive packages go in the apt lists: this setup adds no third-party apt repos or keys.

The only pinned version is `NODE_VERSION` (a major version) in `steps/80-toolchains.sh`. Everything else installs the latest release, so don't add installs that download a hardcoded version.
