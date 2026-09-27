#!/usr/bin/env bash
# Partition, format and install the Master Environment onto this machine.
#
# Run from a NixOS installer ISO:
#
#   ./install.sh          # the laptop, see hosts/master/disk-config.nix
#   ./install.sh vm       # a QEMU/libvirt guest, see INSTALL-VM.md
#
# Over SSH the confirmation prompt needs a terminal, so either allocate one
# or skip the prompt explicitly:
#
#   ssh -t nixos@host 'cd /tmp/master-environment && ./install.sh vm'
#   ssh    nixos@host 'cd /tmp/master-environment && ./install.sh vm --yes'
#
# Everything afterwards is a rebuild, not a re-install:
#   sudo nixos-rebuild switch --flake ".#$host"
set -Eeuo pipefail
trap 'echo -e "\033[2K  [\033[0;31mFAIL\033[0m] Line $LINENO w/ exit code $?"' ERR

# Flags for the `nix` CLI. Not for `nixos-install`, which has its own option
# parser and turns the features on itself when given `--flake`.
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

host=""
assumeYes=0
for arg in "$@"; do
	case "$arg" in
		-y | --yes) assumeYes=1 ;;
		-*) fail "Unknown option '$arg' (use -y/--yes)" ;;
		*)
			[ -z "$host" ] || fail "Only one host can be given (got '$host' and '$arg')"
			host="$arg"
			;;
	esac
done
host="${host:-master}"

diskConfig="hosts/$host/disk-config.nix"
[ -f "$diskConfig" ] || fail "Unknown host '$host' (no $diskConfig)"

disk=$(grep -oP 'device = "\K[^"]+' "$diskConfig")
[ -n "$disk" ] || fail "Cannot read the target disk from $diskConfig"
[ "$disk" != "/dev/disk/by-id/CHANGE-ME" ] || fail "Set the target disk in $diskConfig first!"
[ -e "$disk" ] || fail "No such disk: $disk"

info "=== Host: $host, target disk: $disk ==="
if [ "$assumeYes" -eq 1 ]; then
	info "--yes given, skipping the confirmation prompt."
else
	# Without a terminal `read` would hit EOF and abort with a confusing
	# "FAIL Line ..." from the ERR trap - explain what to do instead.
	[ -t 0 ] || fail "No terminal to confirm on. Re-run with 'ssh -t', or pass --yes."
	read -rp "This ERASES $disk. Continue [y/N] " answer
	[[ "$answer" == "y" || "$answer" == "Y" ]] || exit 1
fi

info "=== Partition, format and mount (disko) ==="
sudo nix "${NIX_FLAGS[@]}" run github:nix-community/disko -- \
	--mode destroy,format,mount \
	--flake ".#$host"

info "=== Install the system ==="
sudo nixos-install --flake ".#$host" --no-root-password

info "=== Done - reboot, log in and run 'passwd' ==="
