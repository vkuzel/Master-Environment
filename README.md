# The Master Environment Setup

Desktop environment setup for Java / Kotlin developer based on [Ubuntu Server](https://ubuntu.com/download/server) and the tilling window manager [sway](https://swaywm.org/).

The workflow is optimized for a laptop running additional one or two external 27-inch displays. Motivation is to have a minimal environment focused on productivity, inspired by [ThePrimeagen](https://github.com/ThePrimeagen/)'s idea of search fatigue reduction. Most common tasks have their fixed place and are as little keystrokes away as possible.

Laptop display on the left:
* Workspace #0: Social apps (mail, ...)

Center display:
* Workspace #1: Terminals (Foot)
* Workspace #2: Browser (Firefox)
* Workspace #3: IDE (IntelliJ IDEA)
* Workspace #4:
* Workspace #5:
* Workspace #6:

Right display:
* Workspace #7: Notes (NeoVim-QT)
* Workspace #8:
* Workspace #9:

The environment is usually installed on an Intel-based ThinkPads. Sway has issues with Nvidia drivers (both open source and proprietary), so it is recommended to use Intel or AMD based GPUs. Ubuntu Server is used as a basis for the environment because it doesn't contain desktop-related clutter.  

## Installation

1. Prerequisites:
   * Computer w/ Intel or AMD GPU.
   * Ubuntu Server 24.04 installed on the machine.

2. Clone the project into a directory.

3. Run `install.sh` script. You can re-run the script to update the environment.

    The script installs APT packages, create symlinks into your home directory and download/copy relevant files.

    After application is removed from this project, cleanup may be performed by the `./cleanup.sh` script. Take note, this is just an experiment functionality and the proper cleanup is not guaranteed.

4. After first installation go through the [MANUAL-POST-INSTALL.md](MANUAL-POST-INSTALL.md) and complete manual steps.
