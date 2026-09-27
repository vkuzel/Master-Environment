#!/usr/bin/env bash
# Partition, format and install the Master Environment onto this machine.
#
# Run from a NixOS installer ISO:
#
#   ./install.sh          # the laptop, see hosts/master/disk-config.nix
#   ./install.sh vm       # a QEMU/libvirt guest, see INSTALL-VM.md
#
# Everything afterwards is a rebuild, not a re-install:
#   sudo nixos-rebuild switch --flake ".#$host"
set -Eeuo pipefail
trap 'echo -e "\033[2K  [\033[0;31mFAIL\033[0m] Line $LINENO w/ exit code $?"' ERR

NIX_FLAGS=(--extra-experimental-features "nix-command flakes")

info() {
	printf '  [ \033[00;34m..\033[0m ] %s\n' "$1"
}

fail() {
	printf '\033[2K  [\033[0;31mFAIL\033[0m] %s\n' "$1" >&2
	exit 1
}

command -v nix > /dev/null || fail "Run this from a NixOS installer ISO."
[ -f flake.nix ] || fail "Run this script from the repository root!"

host="${1:-master}"
diskConfig="hosts/$host/disk-config.nix"
[ -f "$diskConfig" ] || fail "Unknown host '$host' (no $diskConfig)"

disk=$(grep -oP 'device = "\K[^"]+' "$diskConfig")
[ -n "$disk" ] || fail "Cannot read the target disk from $diskConfig"
[ "$disk" != "/dev/disk/by-id/CHANGE-ME" ] || fail "Set the target disk in $diskConfig first!"
[ -e "$disk" ] || fail "No such disk: $disk"

info "=== Host: $host, target disk: $disk ==="
read -rp "This ERASES $disk. Continue [y/N] " answer
[[ "$answer" == "y" || "$answer" == "Y" ]] || exit 1

info "=== Partition, format and mount (disko) ==="
sudo nix "${NIX_FLAGS[@]}" run github:nix-community/disko -- \
	--mode destroy,format,mount \
	--flake ".#$host"

info "=== Install the system ==="
sudo nixos-install "${NIX_FLAGS[@]}" --flake ".#$host" --no-root-password

info "=== Done - reboot, log in and run 'passwd' ==="
