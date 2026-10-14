# os-setup

Small, re-runnable bash scripts that turn a fresh Ubuntu or Fedora install into a basic dev machine. Read the package lists, change what you like, run one command.

| Directory | Target |
| --- | --- |
| [`ubuntu-setup/`](ubuntu-setup/) | Ubuntu 26.04 |
| [`fedora-setup/`](fedora-setup/) | Fedora 44 |

```sh
git clone https://github.com/chaudhryjunaid/os-setup
os-setup/ubuntu-setup/setup.sh     # or: os-setup/fedora-setup/setup.sh
```

The README in each directory has the details.

## What they do

- Install a short list of packages from the distro's own repositories: a C/C++ compiler and `make`, `git`, `curl`, `wget`, `vim`, `htop`, `jq`, `tree`, an SSH client, Python's `pip`, and `flatpak`.
- Add the Flathub remote, and install any Flathub apps you list (and, on Ubuntu, any Snap Store apps).
- Offer to create an SSH key, and to set your git name and email if they aren't set yet.
- On Fedora, upgrade the installed packages first.

## What they don't do

- Add third-party package repositories or signing keys.
- Run vendor `curl | bash` installers.
- Touch your dotfiles or change your login shell.
- Enable services or open network ports.
- Remove anything.

## Layout

Each directory is self-contained and shares no code with the other, by design: a change for one OS can't break the other. If both need a helper, copy it rather than factoring it out.

```
setup.sh          runs steps/NN-*.sh in order (--from N to resume, --only N for one step)
lib/common.sh     helpers the steps source
steps/NN-*.sh     one job each, safe to re-run
packages/*.txt    the package and app lists: edit these to customize
```
