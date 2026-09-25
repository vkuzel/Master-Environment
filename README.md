# The Master Environment Setup

Desktop environment setup for Java / Kotlin developer based on [Ubuntu Server](https://ubuntu.com/download/server) and the tilling window manager [sway](https://swaywm.org/).

The workflow is optimized for a laptop with one or two 27-inch external displays. The goal is to create a minimal, productivity-focused environment inspired by [ThePrimeagen](https://github.com/ThePrimeagen/)'s idea of reducing search fatigue. The most common tasks have a fixed place and are accessible with as few keystrokes as possible. Keyboard shortcuts are also designed to be consistent across the system.

Laptop display on the left:
* Workspace #0: Social apps (mail, ...)

Center display:
* Workspace #1: Terminals (Foot)
* Workspace #2: Browser (Firefox)
* Workspace #3: IDE (IntelliJ IDEA)
* Workspace #4:
* Workspace #5:

Right display:
* Workspace #6: Notes (Micro)
* Workspace #7: AI (Copilot)
* Workspace #8:
* Workspace #9:

The environment is usually installed on an Intel-based ThinkPads. Sway has issues with Nvidia drivers (both open source and proprietary), so it is recommended to use Intel or AMD based GPUs. Ubuntu Server is used as a basis for the environment because it doesn't contain desktop-related clutter.  

## Installation

1. Prerequisites:
   * Computer w/ Intel or AMD GPU.
   * Ubuntu Server 24.04 installed on the machine.

2. Clone the project into a directory.

3. Run `install.sh` script. You can re-run the script to update the environment.

    The script installs APT packages, activates the [home-manager](nix/home.nix) generation with the user applications, create symlinks into your home directory and download/copy relevant files.

    After application is removed from this project, cleanup may be performed by the `./cleanup.sh` script. Take note, this is just an experiment functionality and the proper cleanup is not guaranteed.

4. After first installation go through the [MANUAL-POST-INSTALL.md](MANUAL-POST-INSTALL.md) and complete manual steps.

## Package management

User applications are managed by a standalone [home-manager](https://github.com/nix-community/home-manager) configuration in [nix/home.nix](nix/home.nix), pinned by `nix/flake.lock`. Home-manager is used instead of a plain `nix profile` because it also sets up the things a nix application needs on a non-NixOS distribution:

* `targets.genericLinux.enable` puts the nix profile on `XDG_DATA_DIRS`, `XCURSOR_PATH` and `TERMINFO_DIRS`, so desktop files, D-Bus services, cursors and terminfo entries are found.
* The same option provides `non-nixos-gpu-setup`, which links the nix GPU drivers into `/run/opengl-driver`. Without it sway and other GPU accelerated applications would not start. `install.sh` runs it with `sudo`.
* `fonts.fontconfig` registers the nix fonts and declares the default monospace and emoji families for nix and APT applications alike.

The configuration reads `$USER` and `$HOME`, so it is evaluated with `--impure`. The generation is built and activated directly from the flake, which means home-manager does not have to be installed beforehand. Afterwards `home-manager switch --flake path:$PWD/nix#master-environment --impure` works as well.

Dotfiles are still symlinked from `home/` by `install.sh` rather than declared in nix.

### What stays on APT

* **NetworkManager, BlueZ, PipeWire and WirePlumber** are system daemons. They need system D-Bus policies, systemd units and udev rules, and other Ubuntu packages depend on them, so they cannot be purged.
* **swaylock** must be setuid root to read `/etc/shadow`, and nix cannot install setuid binaries into a user profile.
* **xdg-desktop-portal-wlr and -gtk** discover backends through `/usr/share/xdg-desktop-portal/portals`. Mixing nix and APT portals breaks screen sharing.
* **zsh** is the login shell. `chsh` needs a stable path listed in `/etc/shells`, which a garbage-collected nix store path is not.
* **fontconfig** renders fonts for the APT applications too.
* **Firefox and Thunderbird** come from the Mozilla PPA on purpose, see `configure_mozilla_apt_repository` in `install.sh`.
* **GVfs, MTP tools and libfuse** integrate with the system FUSE and GVfs setup.

### Recovering a broken session

Sway is started manually from a TTY by `~/sway.sh`, there is no login manager. If a nix generation breaks the session, log in on a TTY and either roll back

```shell
/nix/var/nix/profiles/per-user/$USER/home-manager-*-link/activate
```

or fall back to the distribution's compositor

```shell
sudo apt install sway
XDG_CURRENT_DESKTOP=sway dbus-run-session /usr/bin/sway
```
