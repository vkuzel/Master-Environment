#!/usr/bin/env bash
# Partition, format and install the Master Environment onto this machine.
#
# Run from a NixOS installer ISO, after setting the target disk in
# hosts/master/disk-config.nix:
#
#   ./install.sh
#
# Everything afterwards is a rebuild, not a re-install:
#   sudo nixos-rebuild switch --flake .#master
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

disk=$(grep -oP 'device = "\K[^"]+' hosts/master/disk-config.nix)
[ -n "$disk" ] || fail "Cannot read the target disk from hosts/master/disk-config.nix"
[ "$disk" != "/dev/disk/by-id/CHANGE-ME" ] || fail "Set the target disk in hosts/master/disk-config.nix first!"
[ -e "$disk" ] || fail "No such disk: $disk"

info "=== Target disk: $disk ==="
read -rp "This ERASES $disk. Continue [y/N] " answer
[[ "$answer" == "y" || "$answer" == "Y" ]] || exit 1

info "=== Partition, format and mount (disko) ==="
sudo nix "${NIX_FLAGS[@]}" run github:nix-community/disko -- \
	--mode destroy,format,mount \
	--flake .#master

info "=== Install the system ==="
sudo nixos-install "${NIX_FLAGS[@]}" --flake .#master --no-root-password

info "=== Done - reboot, log in and run 'passwd' ==="
