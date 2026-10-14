# fedora-setup

Turns a fresh Fedora 44 install into a basic dev machine. Plain bash, no menus, and every step is safe to re-run.

## Usage

```sh
sudo dnf install -y git
git clone https://github.com/chaudhryjunaid/os-setup
os-setup/fedora-setup/setup.sh
```

It asks for your sudo password once. The only other prompts are optional: whether to generate an SSH key, and your git name and email if they aren't set. With no terminal to ask on, they're skipped.

```sh
./setup.sh --from 60   # resume after a failure
./setup.sh --only 95   # re-run one step
```

## Steps

| Step | What it does |
|---|---|
| `10-dnf-base` | `dnf upgrade`, then the packages in `packages/dnf.txt` |
| `60-flatpak` | adds the Flathub remote (or enables it, if it's there but disabled), then the apps in `packages/flatpak.txt` (empty by default) |
| `95-post` | offers to generate an ed25519 SSH key, and asks for git `user.name` and `user.email` if they're unset |

## Customizing

- **Packages and apps:** edit `packages/*.txt`. Put one or more names on a line; `#` starts a comment. Installed packages are skipped, and a name dnf doesn't know (renamed or retired in a newer release) is skipped with a warning rather than failing the run.
- **New steps:** add a `steps/NN-name.sh` that sources `../lib/common.sh` first, like the existing ones. Steps run in numeric order. Keep yours safe to re-run by checking before installing.

Packages come only from Fedora's own repositories: this setup adds no third-party repositories or keys, including RPM Fusion. If you want RPM Fusion (for codecs or `ffmpeg`), enable it first by following [its instructions](https://rpmfusion.org/Configuration).
