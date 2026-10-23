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

check_repository_root() {
  if [[ ! -f flake.nix ]]; then
    fail "Run this script from the repository root!"
  fi
}

upgrade() {
  info "=== Upgrade ==="
  nix flake update

  if git diff --quiet HEAD -- flake.lock; then
    info "=== Already up to date, nothing to commit ==="
    return
  fi

  git --no-pager diff HEAD -- flake.lock
  git add flake.lock
  git commit -m "Upgrade packages to latest versions"
}

check_repository_root
upgrade

info "=== Done ==="
