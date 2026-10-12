# Installing on real hardware

Run-book for the `master` host: a plain machine booted from the **NixOS minimal
(non-GUI) ISO**. Result is a LUKS-encrypted btrfs system with sway, greetd and
the full Home Manager generation.

For a rehearsal in QEMU first, see [INSTALL-VM.md](INSTALL-VM.md); the post-
install checklist is [MANUAL-POST-INSTALL.md](MANUAL-POST-INSTALL.md).

## 0. Before you start

* Intel or AMD GPU (sway has issues with NVIDIA drivers).
* In the firmware setup: **UEFI mode on**, **Secure Boot off** (systemd-boot is
  unsigned), and disable RAID/"Intel RST" so the NVMe shows up as AHCI/NVMe.
* The target disk is erased without a second chance to back out after step 5.

Write the ISO to a USB stick:

```shell
curl -LO https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso
curl -L https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso.sha256 | sha256sum --check
sudo dd if=latest-nixos-minimal-x86_64-linux.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## 1. Boot the ISO and get online

```shell
ls /sys/firmware/efi            # must exist, otherwise reboot into UEFI mode
sudo systemctl start wpa_supplicant
wpa_cli                         # add_network / set_network / enable_network, or:
nmcli device wifi connect <SSID> --ask
ping -c3 nixos.org
```

Optional but recommended — install from another machine over SSH:

```shell
passwd                          # the `nixos` user ships with an empty password
ip -brief address               # note the IP
```

```shell
ssh -t nixos@<ip>               # from your workstation
```

## 2. Identify the disk

```shell
lsblk -o NAME,SIZE,MODEL
ls -l /dev/disk/by-id/          # pick the stable nvme-eui.* / ata-* path
```

## 3. Clone and adjust

```shell
nix-shell -p git --run 'git clone -b nixos https://github.com/vkuzel/Master-Environment /tmp/me'
cd /tmp/me
```

Three edits (`nix-shell -p micro --run 'micro <file>'`):

| File | Change |
| --- | --- |
| `hosts/master/disk-config.nix` | `device` → the `by-id` path from step 2, replacing `CHANGE-ME` |
| `hosts/master/hardware-configuration.nix` | replace with this machine's, see below |
| `flake.nix` | `user` — name, full name, email, `initialPassword` |

```shell
sudo nixos-generate-config --no-filesystems --show-hardware-config \
  > hosts/master/hardware-configuration.nix
```

Optionally add the matching [nixos-hardware](https://github.com/NixOS/nixos-hardware#modules)
profile to the `imports` in `hosts/master/default.nix`.

**Stage the edits — flakes ignore untracked files in a git repository:**

```shell
nix-shell -p git --run 'git add -A'
```

## 4. Partition, format, install

```shell
./install.sh                    # add --yes to skip the confirmation prompt
```

The script reads the disk out of `hosts/master/disk-config.nix`, refuses to run
on `CHANGE-ME`, confirms, then runs disko (`destroy,format,mount`) followed by
`nixos-install --no-root-password`.
**disko prompts for the LUKS passphrase twice** — this is the passphrase you
will type at every boot. The console is US QWERTY at that point; avoid
characters whose position differs on your layout.

Expect several GiB of downloads from `cache.nixos.org`.

<details><summary>Straight from GitHub, no checkout</summary>

Only works once the disk and hardware config are committed and pushed:

```shell
curl -sSfL https://raw.githubusercontent.com/vkuzel/Master-Environment/nixos/bootstrap.sh \
  | sudo bash -s -- master
```

`bootstrap.sh` runs the same two steps and refuses to start unless
`/etc/os-release` says `VARIANT_ID=installer`, so it cannot be run against an
installed system or another distribution by accident. It also requires UEFI and
at least 8 GiB of RAM. Pin a revision with
`FLAKE=github:vkuzel/Master-Environment/<sha>`.

> **No confirmation prompt** - it erases the disk configured for the host
> immediately.

The equivalent by hand:

```shell
sudo nix --extra-experimental-features 'nix-command flakes' \
  run github:nix-community/disko -- --mode destroy,format,mount \
  --flake github:vkuzel/Master-Environment/nixos#master
sudo nixos-install --flake github:vkuzel/Master-Environment/nixos#master \
  --no-write-lock-file --no-root-password
```

`--no-write-lock-file` is required while the repository has no committed
`flake.lock`.

</details>

<details><summary>Remotely, from a machine that already runs nix</summary>

```shell
nix run github:nix-community/nixos-anywhere -- --flake .#master root@<ip>
```

Needs a root SSH login on the target and a `disko.devices.disk.main.content.…
passwordFile` for the LUKS passphrase, since there is no interactive prompt.

</details>

## 5. Copy the checkout off the ISO

`/tmp` is wiped on reboot, and the installed system has no clone:

```shell
sudo mkdir -p /mnt/home/<user>/projects
sudo cp -a /tmp/me /mnt/home/<user>/projects/Master-Environment
sudo chown -R 1000:100 /mnt/home/<user>/projects/Master-Environment
```

## 6. First boot

```shell
sudo reboot                     # remove the USB stick
```

1. LUKS passphrase prompt,
2. systemd-boot menu,
3. **tuigreet** — log in with `user.name` / `initialPassword` from `flake.nix`,
4. sway session with waybar at the top.

```shell
passwd                          # replace the bootstrap password immediately
```

## 7. Verify

```shell
lsblk -o NAME,FSTYPE,MOUNTPOINT # crypt layer above the btrfs subvolumes
echo $SHELL                     # /run/current-system/sw/bin/zsh
systemctl --user status waybar
command -v copilotw mountui backup start-apps java-home
java -version && echo "$JAVA_HOME"
fastfetch
```

Keys: `Mod+Return` terminal, `Mod+Space` launcher, `Mod+1`…`Mod+0` workspaces,
`Mod+l` lock, `Print` region screenshot.

## 8. Afterwards

```shell
cd ~/projects/Master-Environment
sudo nixos-rebuild switch --flake .#master     # every later change
sudo nixos-rebuild switch --rollback           # undo
```

Finish with [MANUAL-POST-INSTALL.md](MANUAL-POST-INSTALL.md): Wi-Fi, printer,
Twingate, IntelliJ plugins, Firefox extensions.

Add a second LUKS passphrase or a recovery key now, while you still remember
the first one:

```shell
sudo cryptsetup luksAddKey /dev/disk/by-id/<disk>-part2
sudo cryptsetup luksDump   /dev/disk/by-id/<disk>-part2   # check the key slots
```

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `Set the target disk in hosts/master/disk-config.nix first!` | `device` is still `CHANGE-ME`. |
| disko or `nixos-install` builds the *old* configuration | Edits are untracked; flakes only see staged files — `git add -A`. |
| systemd-boot fails, `Not a EFI system` | Booted in BIOS/CSM mode. Reboot into UEFI and redo step 4. |
| Secure Boot refuses to start the bootloader | Disable Secure Boot, or adopt [lanzaboote](https://github.com/nix-community/lanzaboote). |
| Disk missing from `lsblk` | Firmware is in RAID/RST mode; switch it to AHCI/NVMe. |
| Passphrase rejected at boot but accepted during install | Keyboard layout differs at the initrd prompt (US QWERTY there). |
| `error: cannot write modified lock file of flake 'github:…'` | Add `--no-write-lock-file`; the repository has no committed `flake.lock`. |
| Build killed / OOM | `nix.settings.max-jobs = 1;`, or add swap before installing. |
| No Wi-Fi in the installer | `sudo systemctl start wpa_supplicant` first, then `wpa_cli` / `nmcli`. |
| Forgot the LUKS passphrase | Nothing to do — reinstall from step 4. |
