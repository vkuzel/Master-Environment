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
    europa | veritas) ;;
    "") fail "Usage: ./update.sh <europa|veritas>" ;;
    *) fail "Unknown host '$host' (expected 'europa' or 'veritas')" ;;
  esac
}

check_repository_root() {
  if [[ ! -f flake.nix ]]; then
    fail "Run this script from the repository root!"
  fi
}

rebuild() {
  local host="$1"

  info "=== Rebuild and switch to '$host' ==="
  sudo nixos-rebuild switch --flake ".#$host"
}

fix_lock_file_owner() {
  if [[ -f flake.lock && ! -O flake.lock ]]; then
    info "=== Take over the lock file written by root ==="
    sudo chown "$(id -u):$(id -g)" flake.lock
  fi
}

host=${1:-}

check_host "$host"
check_repository_root
rebuild "$host"
fix_lock_file_owner

info "=== Done ==="
