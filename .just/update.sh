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

update() {
  info "=== Update ==="
  nix flake update

  if git diff --quiet HEAD -- flake.lock; then
    info "=== Already up to date, nothing to commit ==="
    return
  fi

  git --no-pager diff HEAD -- flake.lock

  local answer
  read -r -p "Do you want to apply? [y/N] " answer || answer=""
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    git restore --source=HEAD --staged --worktree -- flake.lock
    info "=== Discarded, flake.lock restored ==="
    return
  fi

  git add flake.lock
  git commit -m "Update packages to latest versions"
}

check_repository_root
update

info "=== Done ==="
