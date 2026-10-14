#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "\033[2K  [\033[0;31mFAIL\033[0m] Line %s w/ exit code %s\n" "$LINENO" "$?" >&2' ERR

info() {
  printf '  [ \033[00;34m..\033[0m ] %s\n' "$1";
}

fail() {
  printf '\033[2K  [\033[0;31mFAIL\033[0m] %s\n' "$1" >&2;
  exit 1;
}

check_host() {
  local host="$1"

  case "$host" in
    master | vm) ;;
    "") fail "Usage: ... | sudo bash -s -- <master|vm>" ;;
    *) fail "Unknown host '$host' (expected 'master' or 'vm')" ;;
  esac
}

check_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    fail "Run as root: ... | sudo bash"
  fi
}

check_nixos_installer() {
  if [[ ! -r /etc/os-release ]]; then
    fail "Not nixos installer system"
  fi

  # shellcheck disable=SC1091
  . /etc/os-release

  if [[ "${VARIANT_ID:-}" != "installer" ]]; then
    fail "Not nixos installer system"
  fi
}

check_memory() {
  local memGiB
  memGiB=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1024 / 1024 ))

  if [[ "$memGiB" -lt 7 ]]; then
    fail "Only ${memGiB}GiB RAM. Expect 'No space left on device' from the tmpfs store; 8GiB is recommended."
  fi
}

check_tty() {
  # The node exists even without a controlling terminal, so try to open it.
  # Redirect stderr first, otherwise bash reports the failed open itself.
  if ! : 2> /dev/null < /dev/tty; then
    fail "No terminal available; disko cannot ask for the wipe confirmation."
  fi
}

partition_disk() {
  local repository="$1"
  local flake="$2"

  info "=== Partition, format and mount (disko) ==="
  # `--inputs-from` resolves the bare `disko` installable through this
  # repository's flake.lock, so the tool matches the disko module the system is
  # built with. Without it nix would fetch disko's master head.
  #
  # Under `curl | bash` stdin is the script itself, so disko's "Type 'yes' to
  # continue" prompt would read a line of bash instead of the answer.
  nix --extra-experimental-features 'nix-command flakes' \
    run --inputs-from "$repository" disko -- --mode destroy,format,mount \
    --flake "$flake" < /dev/tty
}

install_os() {
  local flake="$1"

  info "=== Install the system ==="
  nixos-install --flake "$flake" --no-write-lock-file --no-root-password
}

host=${1:-}
repository="github:vkuzel/Master-Environment/nixos"
flake="$repository#$host"

check_host "$host"

info "=== Host: $host"
info "=== Flake: $flake"

check_root
check_nixos_installer
check_memory
check_tty
partition_disk "$repository" "$flake"
install_os "$flake"

info "=== Done - reboot, log in and run 'passwd' ==="
