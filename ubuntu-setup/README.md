# ubuntu-setup

Turns a fresh Ubuntu 26.04 install into a basic dev machine. Plain bash, no menus, and every step is safe to re-run.

## Usage

```sh
sudo apt install -y git
git clone https://github.com/chaudhryjunaid/os-setup
os-setup/ubuntu-setup/setup.sh
```

It asks for your sudo password once. The only other prompts are optional: whether to generate an SSH key, and your git name and email if they aren't set. With no terminal to ask on, they're skipped.

```sh
./setup.sh --from 50   # resume after a failure
./setup.sh --only 60   # re-run one step
```

## Steps

| Step | What it does |
|---|---|
| `10-apt-base` | `apt-get update`, then the packages in `packages/apt.txt`. With an Intel GPU, also `packages/apt-intel.txt` (graphics firmware and the VA-API video driver). |
| `50-snaps` | Snap Store apps in `packages/snap.txt` (empty by default) |
| `60-flatpak` | adds the Flathub remote, then the apps in `packages/flatpak.txt` (empty by default) |
| `95-post` | offers to generate an ed25519 SSH key, and asks for git `user.name` and `user.email` if they're unset |

## Customizing

- **Packages and apps:** edit `packages/*.txt`. Put one or more names on a line; `#` starts a comment. Installed packages are skipped, and a name apt doesn't know (renamed or dropped in a newer release) is skipped with a warning rather than failing the run.
- **New steps:** add a `steps/NN-name.sh` that sources `../lib/common.sh` first, like the existing ones. Steps run in numeric order. Keep yours safe to re-run by checking before installing.

Packages come only from the Ubuntu archive: this setup adds no third-party apt repositories or keys.
