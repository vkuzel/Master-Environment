#!/bin/bash
set -Eeuo pipefail
trap 'echo -e "\033[2K  [\033[0;31mFAIL\033[0m] Line $LINENO w/ exit code $?"' ERR

info() {
	printf '  [ \033[00;34m..\033[0m ] %s\n' "$1"
}

remove_file() {
  local fileName=$1

  info "=== Delete file $fileName ==="
  if [[ -f "$fileName" ]]; then
    rm "$fileName"
  else
    info "Already removed"
  fi
}

remove_link() {
  local fileName=$1

  info "=== Delete link $fileName ==="
  if [[ -h "$fileName" ]]; then
    rm "$fileName"
  else
    info "Already removed"
  fi
}

remove_dir() {
  local dirName=$1

  info "=== Delete dir $dirName ==="
  if [[ -d "$dirName" ]]; then
    rm -r "$dirName"
  else
    info "Already removed"
  fi
}

remove_root_file() {
  local fileName=$1

  info "=== Delete root-owned file $fileName ==="
  if [[ -e "$fileName" ]]; then
    sudo rm "$fileName"
  else
    info "Already removed"
  fi
}

remove_root_dir() {
  local dirName=$1

  info "=== Delete root-owned dir $dirName ==="
  if [[ -d "$dirName" ]]; then
    sudo rm -r "$dirName"
  else
    info "Already removed"
  fi
}

remove_group() {
  local groupName=$1

  info "=== Remove group $groupName ==="
  if id -nG "$USER" | grep -qw docker; then
    sudo gpasswd -d "$USER" "$groupName" || true
  else
    info "Already removed"
  fi
}

purge_apt_package() {
	local pkgName=$1

	info "=== Purge $pkgName ==="
	local status=$(dpkg --status "$pkgName" 2>/dev/null || true)
	if [[ -z "$status" ]]; then
		info "Already purged"
	else
		sudo apt purge --yes "$pkgName"
	fi
}

purge_apt_package gedit
purge_apt_package vim
purge_apt_package neovim
purge_apt_package neovim-qt
purge_apt_package neovim-runtime
purge_apt_package jmtpfs
remove_dir "$HOME/.local/share/gedit"
remove_dir "$HOME/.local/config/gedit"
remove_dir "$HOME/.config/nvim"
remove_link "$HOME/.vimrc"
remove_link "$HOME/.local/bin/mountui.sh"
remove_link "$HOME/.local/bin/start-me-apps"
remove_link "$HOME/.local/bin/view-images.sh"
remove_link "$HOME/.local/bin/dockershell.sh"
remove_link "$HOME/.local/bin/copilotshell.sh"
remove_group docker

# Applications moved from APT into nix, see nix/flake.nix
purge_apt_package fonts-noto-color-emoji
purge_apt_package waybar
purge_apt_package fuzzel
purge_apt_package sway-notification-center
purge_apt_package libnotify-bin
purge_apt_package brightnessctl
purge_apt_package playerctl
purge_apt_package grim
purge_apt_package slurp
purge_apt_package chafa
purge_apt_package wl-clipboard
purge_apt_package gimp
purge_apt_package 7zip
purge_apt_package ack
purge_apt_package bc
purge_apt_package whois
purge_apt_package transmission-cli
purge_apt_package mpv
purge_apt_package mpv-mpris
# Sway and swayidle are provided by nix now. Swaylock and Xwayland stay on APT,
# see install.sh.
purge_apt_package sway
purge_apt_package swayidle

# Applications previously installed manually, now installed by nix
remove_root_file "/usr/local/bin/starship"
remove_root_dir "/usr/share/fonts/truetype/dejavu-nerd"
remove_dir "$HOME/.config/zsh/zsh-autosuggestions"
remove_dir "$HOME/.config/zsh/zsh-history-substring-search"
remove_dir "$HOME/.config/zsh/zsh-syntax-highlighting"

# Fontconfig aliases are declared by home-manager now, see nix/home.nix
remove_link "$HOME/.config/fontconfig/fonts.conf"
