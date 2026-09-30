# Installing the Master Environment in a QEMU VM (Virtual Machine Manager)

A full walkthrough, from an empty libvirt host to a running sway session.
Use this to try the environment out before installing it on real hardware.

Everything here targets the `vm` host (`hosts/vm/`), which is the same
configuration as the laptop minus LUKS, TLP, Bluetooth, printing and Twingate,
plus the QEMU guest agent and a software-rendering fallback for sway.

Expect ~30-45 minutes, most of it downloading from the binary cache.

---

## 0. Prerequisites on the host

You need libvirt, QEMU/KVM, virt-manager and the **UEFI firmware** (the
configuration boots with systemd-boot, so a BIOS guest will not work).

Ubuntu / Debian host:

```shell
sudo apt install qemu-kvm libvirt-daemon-system virt-manager ovmf
sudo usermod -aG libvirt "$USER"
newgrp libvirt
```

NixOS host, in your own configuration:

```nix
virtualisation.libvirtd.enable = true;
virtualisation.libvirtd.qemu.ovmf.enable = true;
programs.virt-manager.enable = true;
users.users.<you>.extraGroups = [ "libvirtd" ];
```

Check that hardware virtualisation is available - without it the VM will be
unusably slow:

```shell
egrep -c '(vmx|svm)' /proc/cpuinfo   # must be > 0
```

## 1. Download the NixOS ISO

Get the **minimal** 64-bit ISO (the graphical one works too, but is a larger
download and you will not use its desktop):

```shell
cd ~/Downloads
curl -LO https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso
```

Verify it:

```shell
curl -L https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso.sha256 \
  | sha256sum --check
```

## 2. Create the VM in Virtual Machine Manager

Open **Virtual Machine Manager** → **File → New Virtual Machine**.

1. **Local install media (ISO image)** → Forward.
2. Browse to the ISO you downloaded. Uncheck *Automatically detect from the
   installation media*, type `NixOS` and pick **Generic Linux 2022** (or any
   recent generic entry) → Forward.
3. **Memory: 8192 MiB, CPUs: 4.**
   Less will work, but Nix builds are memory-hungry; 4096 MiB is the practical
   floor → Forward.
4. **Disk: 60 GiB.** The store grows quickly - a full desktop closure plus
   IntelliJ and Firefox is comfortably over 20 GiB → Forward.
5. Name it `master-vm`, and **tick "Customize configuration before install"**
   → Finish.

In the configuration window that opens:

| Section | Setting |
| --- | --- |
| **Overview → Firmware** | `UEFI x86_64: …/OVMF_CODE_4M.fd` — **required**, see note below |
| **Overview → Chipset** | `Q35` |
| **CPUs** | tick *Copy host CPU configuration* |
| **SATA Disk 1 → Advanced** | Disk bus: **VirtIO** |
| **NIC → Device model** | `virtio` |
| **Display Spice → Listen type** | `None`, tick *OpenGL* if your host GPU supports it |
| **Video** | Model: **Virtio**, tick *3D acceleration* (only together with OpenGL above) |
| **Add Hardware → Channel** | `spice agent (spicevmc)` — usually present already |

Click **Begin Installation**.

> **Firmware must be chosen now.** libvirt fixes the firmware at first boot and
> the dropdown is greyed out afterwards. If you forget, delete the VM
> (*including* its storage) and start over.

> **3D acceleration is optional.** `hosts/vm/default.nix` sets
> `WLR_RENDERER = "pixman"`, so sway renders in software and works either way.
> If you enabled OpenGL + 3D and want the faster path, remove that line, or
> override it per boot with `WLR_RENDERER=gles2 sway`.

## 3. Boot the installer and prepare the guest

The VM boots into the NixOS installer shell as user `nixos`.

Give yourself a password, so you can copy the repository in and work from a
real terminal instead of the virt-manager console. `sshd` is already running -
the installer enables it by default - but both accounts ship with an empty
password, and SSH refuses those, so setting one is what actually unlocks login:

```shell
passwd                       # set a password for the `nixos` user
ip -brief address            # note the guest IP, e.g. 192.168.122.42
```

Confirm the guest booted in UEFI mode - this directory must exist:

```shell
ls /sys/firmware/efi
```

If it does not, the VM is running in BIOS mode; go back to step 2.

Check networking:

```shell
ping -c3 nixos.org
```

## 4. Get the configuration

The branch is public, so **nothing has to be copied into the guest** - both
disko and `nixos-install` take a flake URI directly:

```
github:vkuzel/Master-Environment/nixos
```

`hosts/vm/disk-config.nix` already targets `/dev/vda` and
`hosts/vm/hardware-configuration.nix` already describes a virtio guest, so just
confirm the disk is there:

```shell
lsblk      # expect vda, 60G, no partitions
```

<details><summary>Alternative: a local checkout in the guest</summary>

Only needed if you want to change something before installing (a different user
name, another disk). Clone it:

```shell
nix-shell -p git --run \
  'git clone -b nixos https://github.com/vkuzel/Master-Environment /tmp/master-environment'
cd /tmp/master-environment
```

or copy a working tree from the **host** (replace the IP with the one from
step 3):

```shell
rsync -a --exclude result --exclude .git \
  ./ nixos@192.168.122.42:/tmp/master-environment/
```

</details>

## 5. Adjust the configuration (optional)

Installing straight from GitHub uses the committed defaults, which already suit
a VM - **there is nothing to edit**:

| Setting | Default | Defined in |
| --- | --- | --- |
| login name | `vkuzel` | `user` in `flake.nix` |
| bootstrap password | `master` | `user.initialPassword` - change with `passwd` after first boot |
| target disk | `/dev/vda` | `hosts/vm/disk-config.nix` |

A remote flake cannot be edited, so using a different identity means taking the
local-checkout route in step 4 and changing:

```nix
user = {
  name = "vkuzel";
  fullName = "Vaclav Kuzel";
  initialPassword = "master";   # changed with `passwd` after first boot
};
```

```shell
nano flake.nix     # or: nix-shell -p micro --run 'micro flake.nix'
```

## 6. Install

Two commands, both reading the configuration straight from GitHub.

**Partition, format and mount** (GPT + 1 GiB ESP + btrfs subvolumes, mounted at
`/mnt`):

```shell
sudo nix --extra-experimental-features 'nix-command flakes' \
  run github:nix-community/disko -- --mode destroy,format,mount \
  --flake github:vkuzel/Master-Environment/nixos#vm
```

> **This erases `/dev/vda` without asking.** The `install.sh` confirmation
> prompt is not available on this route, because that script needs a local
> checkout.

**Install the system**, which builds the whole system *and* the Home Manager
generation:

```shell
sudo nixos-install --flake github:vkuzel/Master-Environment/nixos#vm \
  --no-write-lock-file --no-root-password
```

`--no-write-lock-file` is required: the repository has no committed
`flake.lock`, and nix refuses to build an unlocked flake it cannot write a lock
file back to. The trade-off is that the build is not reproducible - every
install pins whatever the inputs happen to be that day.

`--flake` switches on the `nix-command`/`flakes` features by itself, so
`nixos-install` needs no `--extra-experimental-features`.

This is where the time goes: several GiB are fetched from `cache.nixos.org`.

<details><summary>Alternative: from a local checkout</summary>

If you cloned in step 4, use the wrapper instead - it validates the host, reads
the target disk out of `hosts/vm/disk-config.nix` and asks for confirmation
before erasing anything:

```shell
./install.sh vm
```

This also works over SSH, which is the safest route of all: you keep the
confirmation prompt *and* the disk checks. The prompt needs a terminal, so
allocate one with `ssh -t`, and run it under `screen` (present on the ISO) so a
dropped connection cannot kill a half-finished `nixos-install`:

```shell
rsync -a --exclude result --exclude .git \
  ./ nixos@192.168.122.42:/tmp/master-environment/
ssh -t nixos@192.168.122.42 \
  'cd /tmp/master-environment && screen -S inst ./install.sh vm'
```

Reattach after a disconnect with `ssh -t nixos@192.168.122.42 screen -r inst`.

For an unattended run, skip the prompt explicitly - no `-t` needed:

```shell
ssh nixos@192.168.122.42 'cd /tmp/master-environment && ./install.sh vm --yes'
```

`sudo` never prompts here: the installer ISO grants the `nixos` user
passwordless sudo.

</details>

## 7. First boot

```shell
sudo reboot
```

In virt-manager, open **Virtual Machine → Details → Boot Options** and untick
the CD-ROM, or simply eject the ISO, so the VM boots from disk.

You should get:

1. systemd-boot menu,
2. **tuigreet** asking for a username and password - use the `user.name` and
   `initialPassword` from `flake.nix`,
3. a sway session: turquoise background, waybar at the top.

Change the bootstrap password immediately:

```shell
passwd
```

## 8. Check it works

Open a terminal with `Mod4+Return` (Mod4 is the Super/Windows key). The
`master-environment` bindings all apply:

| Key | Action |
| --- | --- |
| `Mod+Return` | foot terminal |
| `Mod+Space` | fuzzel launcher |
| `Mod+1`…`Mod+0` | workspaces 1-10 |
| `Mod+Shift+q` | close window |
| `Mod+l` | lock (`sway-lock`) |
| `Mod+Shift+r` | rearrange workspaces across outputs |
| `Print` | region screenshot |

Verify the migration landed:

```shell
echo $SHELL                 # /run/current-system/sw/bin/zsh
starship --version
micro --version
systemctl --user status waybar
command -v copilotw mountui backup start-apps
fastfetch
```

## 9. Iterating

Installing from GitHub leaves no repository in the guest. Clone one to work on
the configuration:

```shell
mkdir -p ~/projects
nix-shell -p git --run \
  'git clone -b nixos https://github.com/vkuzel/Master-Environment ~/projects/Master-Environment'
cd ~/projects/Master-Environment
```

(If you installed from a checkout under `/tmp`, copy that out instead - `/tmp`
is wiped on reboot.)

From now on, every change is applied with:

```shell
sudo nixos-rebuild switch --flake .#vm
```

To pull the latest commit without keeping a clone at all:

```shell
sudo nixos-rebuild switch --flake github:vkuzel/Master-Environment/nixos#vm \
  --no-write-lock-file
```

Useful variants:

```shell
sudo nixos-rebuild test --flake .#vm      # apply now, do not add to the boot menu
sudo nixos-rebuild switch --rollback      # undo the last switch
nix flake update                          # bump all inputs
```

Because `home-manager.backupFileExtension = "hm-bak"` is set, activation never
destroys a hand-edited dotfile - it renames it to `<file>.hm-bak` instead.

**Take a libvirt snapshot now** (virt-manager → the camera icon). Reverting to
it is much faster than reinstalling when an experiment goes wrong.

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| systemd-boot fails to install, `Not a EFI system` | VM booted in BIOS mode. Recreate the VM with UEFI firmware (step 2). |
| sway exits immediately, `failed to create renderer` | GPU passthrough/3D mismatch. Make sure `WLR_RENDERER = "pixman"` is still set in `hosts/vm/default.nix`. |
| Black screen after tuigreet | Set Video model to **Virtio** in virt-manager; `qxl` does not work well with wlroots. |
| Tiny 1024x768 screen that will not resize | The spice agent channel is missing. Add Hardware → Channel → `spice agent (spicevmc)`, then reboot. |
| `error: experimental Nix feature 'nix-command' is disabled` | Prefix with `nix --extra-experimental-features 'nix-command flakes'`; the installer ISO does not enable flakes by default. The installed system does (`modules/nixos/nix.nix`). |
| `nixos-install: unknown option '--extra-experimental-features'` | `nixos-install` has its own option parser and rejects `nix` CLI flags. It enables the flake features itself when given `--flake`, so simply drop them. |
| `[FAIL] No terminal to confirm on` from `install.sh` | Running it over SSH without a TTY. Use `ssh -t`, or pass `--yes` to skip the prompt. |
| `error: cannot write modified lock file of flake 'github:…'` | The repository has no committed `flake.lock`. Add `--no-write-lock-file` to the `nixos-install` / `nixos-rebuild` command (step 6). |
| Build fails on a bug you already fixed and pushed | Nix caches the `github:…/nixos` branch → commit lookup for `tarball-ttl` (3600 s by default), so it keeps building the previous commit. Pin the exact revision instead: `--flake 'github:vkuzel/Master-Environment/<commit-sha>#vm'`. Alternatively clear the cache with `sudo rm -rf /root/.cache/nix` — it holds only regenerable data, no store paths. Note the cache is per user, and `nixos-install` runs as root. |
| `error: path '/nix/store/…' does not exist` during install | Out of disk. 60 GiB is the recommended minimum. |
| Build killed / OOM | Raise the VM memory, or add `nix.settings.max-jobs = 1;`. |
| No network in the guest | libvirt's `default` network is down: `sudo virsh net-start default && sudo virsh net-autostart default`. |

## Installing on the real laptop afterwards

Same procedure, with three differences:

1. Use the `master` host, which adds LUKS full-disk encryption.
2. Set the real disk in `hosts/master/disk-config.nix`
   (`ls -l /dev/disk/by-id/`) - replace `CHANGE-ME`.
3. Replace `hosts/master/hardware-configuration.nix` with the machine's own:

   ```shell
   sudo nixos-generate-config --no-filesystems --show-hardware-config \
     > hosts/master/hardware-configuration.nix
   ```

Then `./install.sh` (no argument) and continue with
[MANUAL-POST-INSTALL.md](MANUAL-POST-INSTALL.md).
