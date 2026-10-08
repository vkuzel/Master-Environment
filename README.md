# The Master Environment Setup (NixOS)

Desktop environment setup for a Java / Kotlin developer, based on [NixOS](https://nixos.org/)
and the tiling window manager [sway](https://swaywm.org/).

This is the declarative port of the original Ubuntu Server + `install.sh` setup.
Everything the shell script used to do imperatively - apt packages, downloaded
Nerd Fonts, GitHub zsh/micro plugins, `chsh`, `usermod -aG`, `gsettings`, and a
tree of symlinks into `$HOME` - is now a single evaluated configuration.

The workflow is unchanged: a laptop with one or two 27-inch external displays,
fixed places for the most common tasks, consistent keyboard shortcuts.

Laptop display on the left:
* Workspace #10: Communication (mail, Signal, ...)

Center display:
* Workspace #1: Terminals (Foot)
* Workspace #2: Browser (Firefox)
* Workspace #3: IDE (IntelliJ IDEA)
* Workspace #4, #5

Right display:
* Workspace #6: Notes (Micro)
* Workspace #7: AI (Copilot)
* Workspace #8, #9

Use an Intel or AMD GPU - sway has issues with NVIDIA drivers.

## Repository layout

```
flake.nix                  inputs, the single nixosConfiguration, the overlay
hosts/master/              the laptop: hardware + disk layout
  default.nix
  hardware-configuration.nix   generated per machine
  disk-config.nix              declarative partitioning (disko), LUKS + btrfs
hosts/vm/                  a QEMU/libvirt guest, see INSTALL-VM.md
modules/nixos/             system concerns, one file per topic
modules/home/              user concerns (Home Manager), one file per program
pkgs/                      the overlay: scripts, pinned Copilot CLI, IDEA
  scripts/src/             the original bash/python helpers, verbatim
assets/                    raw config data (starship.toml, waybar/swaync CSS)
```

There is no configuration framework (no denix, snowfall, flake-parts). A flat
tree of plain NixOS / Home Manager modules is the smallest thing that does the
job, and every file can be read without learning a DSL first.

## Installation

> Trying it out first? [INSTALL-VM.md](INSTALL-VM.md) is a step-by-step guide
> for installing into a QEMU VM with Virtual Machine Manager, including
> creating the VM and fetching the ISO.

1. Prerequisites:
   * Computer with an Intel or AMD GPU.
   * Booted [NixOS minimal ISO](https://nixos.org/download/#nixos-iso).

2. Clone this repository and adjust:
   * `flake.nix` → `user` (name, full name, initial password).
   * `hosts/master/disk-config.nix` → `device` (`ls -l /dev/disk/by-id/`).
   * `hosts/master/hardware-configuration.nix` → replace with the output of
     `sudo nixos-generate-config --no-filesystems --show-hardware-config`.

3. Partition, format and install:

   ```shell
   # after setting the disk in hosts/master/disk-config.nix
   ./install.sh
   ```

   `./install.sh vm` installs the VM host instead.

   Or remotely, from any machine with nix:

   ```shell
   nix run github:nix-community/nixos-anywhere -- --flake .#master root@<ip>
   ```

4. Reboot, log in, change the bootstrap password with `passwd`.

5. Afterwards, every change to the environment is applied with:

   ```shell
   sudo nixos-rebuild switch --flake .#master
   ```

   This is the replacement for re-running `install.sh`. There is no
   `cleanup.sh` equivalent - removing a package from a module and rebuilding
   removes it from the system, and `nix-collect-garbage` reclaims the space.

6. Go through [MANUAL-POST-INSTALL.md](MANUAL-POST-INSTALL.md) - it is much
   shorter than the Ubuntu one.

## Day-to-day

| Task | Command |
| --- | --- |
| Apply configuration | `sudo nixos-rebuild switch --flake .#master` |
| Try without making it the default | `sudo nixos-rebuild test --flake .#master` |
| Build in a throwaway VM | `nixos-rebuild build-vm --flake .#vm && ./result/bin/run-*-vm` |
| Install into a libvirt VM | see [INSTALL-VM.md](INSTALL-VM.md) |
| Update all inputs | `nix flake update` |
| Update one input | `nix flake update nixpkgs` |
| Roll back | `sudo nixos-rebuild switch --rollback` |
| Format the repo | `nix fmt` |
| Build only the helper scripts | `nix build .#master-environment-scripts` |
| One-off tool, not installed | `nix shell nixpkgs#<pkg>` |

## What changed compared to the Ubuntu setup

| Ubuntu (`install.sh`) | NixOS |
| --- | --- |
| `apt install …` ×60 | `modules/nixos/*.nix`, `modules/home/packages.nix` |
| Nerd Font downloaded with curl + `fc-cache` | `modules/nixos/fonts.nix` (`nerd-fonts.dejavu-sans-mono`) |
| `fonts.conf` | `fonts.fontconfig.defaultFonts` |
| zsh plugins unzipped from GitHub `master` | `programs.zsh.{autosuggestion,syntaxHighlighting,historySubstringSearch}` - pinned by `flake.lock` |
| `curl starship.rs/install.sh \| sh` | `programs.starship`, config from `assets/starship.toml` |
| Mozilla PPA + apt pinning | `programs.firefox` / `programs.thunderbird` |
| `create_links` symlink farm | Home Manager generated files |
| `~/.local/bin/*.sh`, `*.py` symlinks | real packages with declared runtime deps (`pkgs/scripts`) |
| `nix profile add ./nix` | `home.packages` |
| separate `~/.config/nix/copilot` dev shell | `pkgs/default.nix` overlay, same pinned version |
| IntelliJ IDEA from JetBrains Toolbox | `pkgs/idea.nix` (`jetbrains.idea` + vmoptions) |
| JDKs downloaded by IntelliJ into `~/.jdks` | `modules/home/java.nix` (17, 21, 25; 25 is the default on `PATH` and in `JAVA_HOME`) |
| `chsh`, `usermod -aG video`, `gsettings set` | `modules/nixos/users.nix`, `modules/home/sway.nix` |
| `bar { swaybar_command waybar }` | waybar as a `sway-session.target` user unit |
| `sway.sh` (`dbus-run-session sway`) | greetd/tuigreet starts a proper session |
| `system/bwrap-userns-restrict` AppArmor profile | not needed - NixOS does not restrict user namespaces |
| `MANUAL-POST-INSTALL.md` steps 1-7 | declarative (`power.nix`, `printing.nix`, `virtualisation.nix`, `users.nix`, `desktop-apps.nix`) |

Script renames (the Ubuntu installer stripped the `.py`/`.sh` suffix; packages
need unambiguous names):

| Before | After |
| --- | --- |
| `kill.sh` | `kill-app` (`kill` would shadow the shell builtin) |
| `.config/sway/lock.py` | `sway-lock` |
| `.config/sway/screenshot.sh` | `sway-screenshot` |
| `.config/sway/rearrange-workspaces.sh` | `sway-rearrange-workspaces` |

`copilotw` was adapted: it no longer shells out to `nix develop` (the Copilot
CLI is pinned by the overlay and baked into the wrapper's `PATH`) and it only
binds `/usr`, `/bin`, `/lib`, `/lib64` into the sandbox if they exist, which on
NixOS they mostly do not.

## Known follow-ups

* Secrets (Wi-Fi, SSH keys, tokens) are still handled manually. The natural
  next step is [sops-nix](https://github.com/Mic92/sops-nix) with a
  `hashedPasswordFile` instead of `initialPassword`.
