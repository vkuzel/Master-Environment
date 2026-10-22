# The Master Environment Setup (NixOS)

Desktop environment setup for a Java / Kotlin developer, based on [NixOS](https://nixos.org/) and the tiling window manager [sway](https://swaywm.org/).

The workflow is optimized for a laptop with one or two 27-inch external displays. The goal is to create a minimal, productivity-focused environment inspired by [ThePrimeagen](https://github.com/ThePrimeagen/)'s idea of reducing search fatigue. The most common tasks have a fixed place and are accessible with as few keystrokes as possible. Keyboard shortcuts are also designed to be consistent across the system.

Laptop display on the left:
* Workspace #0: Communication (mail, Signal, ...)

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

The environment is intended for an Intel-based ThinkPads. Sway has issues with Nvidia drivers (both open source and proprietary), so it is recommended to use Intel or AMD based GPUs. If you want to use it don't forget to adjust `flake.nix` (name, password, ...).

## Installation

1. Prerequisites:
   * Computer with an Intel or AMD GPU.
   * Booted [NixOS minimal ISO](https://nixos.org/download/#nixos-iso).

2. Partition, format and install:

   ```shell
   curl -sSfL https://raw.githubusercontent.com/vkuzel/Master-Environment/nixos/bootstrap.sh \
     | sudo bash -s -- europa
   ```

3. Reboot and log in. Initial password: `master`

## Maintenance

- Update

   ```shell
   ./update.sh europa
   ```
