#!/bin/bash
set -Eeuo pipefail
trap 'echo -e "\033[2K  [\033[0;31mFAIL\033[0m] Line $LINENO w/ exit code $?"' ERR

info() {
	printf '  [ \033[00;34m..\033[0m ] %s\n' "$1"
}

fail() {
	printf '\033[2K  [\033[0;31mFAIL\033[0m] %s\n' "$1" >> /dev/stderr
	exit 1
}

check_os() {
  local distroName="Ubuntu 24.04"
	if ! grep -q "$distroName" /etc/os-release; then
		fail "Run this script on $distroName!"
	fi
}

check_working_dir() {
	if [ ! -d "home" ]; then
		fail "Run this script from the projects dir!"
	fi
}

configure_timezone() {
	info "=== Configure timezone ==="
	if [[ -e "/etc/localtime" ]]; then
		info "Already configured"
	else
		sudo ln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime
	fi
}

uninstall_cloud_init() {
  info "=== Uninstall Cloud Init ==="
  # Details: https://gist.github.com/zoilomora/f862f76335f5f53644a1b8e55fe98320
  if [[ ! -e "/etc/cloud/" ]]; then
		info "Already uninstalled"
  else
		info 'Disable all services except "none" and then press Enter'
		read -r
		sudo dpkg-reconfigure cloud-init
		sudo apt purge cloud-init
		sudo rm -r /etc/cloud/ /var/lib/cloud/ /etc/netplan/*cloud-init.yaml
  fi
}

configure_network_manager() {
  info "=== Configure Network Manager ==="
  if [[ ! -e "/etc/systemd/system/dbus-org.freedesktop.network1.service" ]]; then
		info "Already configured"
  else
		info "Disable systemd-networkd"
		sudo systemctl disable systemd-networkd systemd-networkd.socket
		sudo apt purge networkd-dispatcher
		info "Restart NetworkManager"
		sudo systemctl restart NetworkManager
  fi
}

install_nerd_fonts() {
	info "=== Install Nerd Fonts ==="
	local targetDir="/usr/share/fonts/truetype/dejavu-nerd"
	if [ -d "$targetDir" ]; then
		info "Already installed"
	else
		local fontFile="DejaVuSansMono.zip"
		local fontUrl="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/$fontFile"

		curl --location --output-dir "/tmp/" --remote-name "$fontUrl"
		sudo mkdir -p "$targetDir"
		sudo unzip "/tmp/$fontFile" -d "$targetDir"
		info "Refresh font cache"
		sudo fc-cache -fv
		# Verify font installed: `fc-list`
	fi
}

configure_mozilla_apt_repository() {
  info "=== Configure Mozilla APT repository ==="
  if [[ -e "/etc/apt/preferences.d/mozillateamppa" ]]; then
		info "Already configured"
  else
    sudo add-apt-repository ppa:mozillateam/ppa
		# Due to a bug, after installing and pinning the Mozilla's package, we have
		# to decrease priority of Ubuntu's Firefox meta-package to prevent
		# overriding the previous one: https://bugs.launchpad.net/ubuntu/+source/firefox/+bug/1999308
		cat <<EOF | sudo tee /etc/apt/preferences.d/mozillateamppa > /dev/null
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1

Package: thunderbird*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: thunderbird*
Pin: release o=Ubuntu*
Pin-Priority: -1
EOF
		sudo apt update
  fi
}

add_current_user_into_group() {
  local group=$1

  info "=== Add user $USER into group $group ==="
  if id -nG "$USER" | grep -qw "$group"; then
	  info "$USER is already in $group"
  else
	  sudo usermod -aG "$group" "$USER"
  fi
}

enable_systemctl_service() {
  local service=$1

  info "=== Enable $service service ==="
  if systemctl is-enabled --quiet "$service"; then
	  info "Service is already enabled"
  else
	  sudo enable --now "$service"
  fi
}

install_apt_package() {
	local pkgName=$1

	info "=== Install $pkgName ==="
	local status=$(dpkg --status "$pkgName" 2>/dev/null || true)
	if [[ ! -z "$status" ]]; then
		info "Already installed"
	else
		sudo apt install "$pkgName"
	fi
}

uninstall_apt_package() {
	local pkgName=$1

	info "=== Uninstall $pkgName ==="
	local status=$(dpkg --status "$pkgName" 2>/dev/null || true)
	if [[ -z "$status" ]]; then
		info "Already uninstalled"
	else
		sudo apt purge "$pkgName"
	fi
}

install_starship() {
	info "=== Install Starship ==="
	if command -v starship &> /dev/null; then
		info "Already installed"
	else
		curl -sS https://starship.rs/install.sh | sh
	fi
}

install_zsh_plugin() {
	local pluginUrl=$1
	local pluginsDir="$HOME/.config/zsh"
	local pluginName=$(echo "$pluginUrl" | grep -Eo "[^/]+$" | grep -Eo "^[^.]+")
	local pluginDir="$pluginsDir/$pluginName"

	info "=== Install ZSH plugin $pluginName ==="
	if [[ -z "$pluginName" ]]; then
		fail "Plugin name cannot be resolved from $pluginUrl"
	fi
	
	if [[ -d "$pluginDir/.git" ]]; then
		pushd "$pluginDir" >> /dev/null
		git pull
		popd > /dev/null
	else
		git clone "$pluginUrl" "$pluginDir"
	fi
}

create_directory_structure() {
	info "=== Create directory structure ==="
	local srcDir=$1
	local dstDir=$2

	pushd "$srcDir" > /dev/null

	for dirPath in $(find . -mindepth 1 -type d); do
		local dstPath="$dstDir/$dirPath"
		if [ -d "$dstPath" ]; then
			continue
		fi
		
		info "Create $dstPath"
		mkdir -p "$dstPath"
	done

	popd > /dev/null
}

normalpath() {
	local path=$1
	# Hacky path normalization
	echo "$path" | sed "s/\/.\//\//g"
}

create_links() {
	info "=== Create links ==="
  local srcDir=$1
  local dstDir=$2

  pushd "$srcDir" > /dev/null

  for filePath in $(find . -mindepth 1 -type f); do
		local srcPath=$(realpath "$filePath")
		local dstPath=$(normalpath "$dstDir/$filePath" | sed 's/\.py$//')
		if [ -h "$dstPath" ]; then
			continue
		elif [ -e "$dstPath" ]; then
		  info "Cannot symlink into existing regular file $dstPath"
		else
		  info "Create $dstPath"
			ln -s "$srcPath" "$dstPath"
		fi
  done

  popd > /dev/null
}

chsh_zsh() {
  info "=== ChSh to ZSH ==="
  if [ "$SHELL" != "/bin/zsh" ]; then
	chsh "$USER" -s /bin/zsh
  fi
}

check_os
check_working_dir

SRC_DIR=home
DST_DIR=$HOME

# Remove Ubuntu Server
uninstall_apt_package ubuntu-server
uninstall_apt_package byobu
uninstall_apt_package tilix
uninstall_apt_package screen
uninstall_apt_package tmux
uninstall_apt_package cloud-guest-utils
uninstall_apt_package cloud-initramfs-copymods
uninstall_apt_package cloud-initramfs-dyn-netconf

# Basic setup
configure_timezone

# Networking
install_apt_package network-manager
configure_network_manager

# Shell
install_nerd_fonts
install_apt_package fonts-noto-color-emoji
install_apt_package zsh
install_starship
install_zsh_plugin "https://github.com/zsh-users/zsh-autosuggestions.git"
install_zsh_plugin "https://github.com/zsh-users/zsh-history-substring-search.git"
install_zsh_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git"
chsh_zsh

# Sway
install_apt_package xwayland
install_apt_package sway
install_apt_package swaylock
install_apt_package swayidle
install_apt_package waybar
install_apt_package fuzzel
install_apt_package sway-notification-center
install_apt_package libnotify-bin
install_apt_package brightnessctl
# Add the user into the video group to use brightnessctl
add_current_user_into_group video
install_apt_package playerctl
install_apt_package desktop-file-utils
install_apt_package grim
install_apt_package slurp
install_apt_package chafa

# screen sharing
# Guidelines: https://wiki.archlinux.org/title/XDG_Desktop_Portal
# Run sway in D-Bus session to allow screensharing, i.e., `dbus-run-session sway`
# Test: https://mozilla.github.io/webrtc-landing/gum_test.html
install_apt_package xdg-desktop-portal-wlr

# Audio
install_apt_package pipewire
install_apt_package pipewire-pulse
install_apt_package pipewire-audio-client-libraries
install_apt_package libspa-0.2-bluetooth
install_apt_package libspa-0.2-jack
install_apt_package wireplumber

# Bluetooth
install_apt_package bluetooth
enable_systemctl_service bluetooth

# Dotfiles
create_directory_structure $SRC_DIR $DST_DIR
create_links $SRC_DIR $DST_DIR

# Mozilla Thunderbird and Firefox
install_apt_package software-properties-common
configure_mozilla_apt_repository
# TODO On some machines latest firefox should be installed on other firefox-esr
# install_apt_package firefox-esr
install_apt_package thunderbird

# Video
# Current version (Ubuntu 22.04) of MPV does not support PipeWire
# (`--ao=pipewire`), set it as a default ao as soon as it will.
install_apt_package mpv
install_apt_package mpv-mpris

# Office utils
install_apt_package wl-clipboard
install_apt_package neovim-qt
install_apt_package gimp

# Android file mount
install_apt_package gvfs-backends
install_apt_package gvfs-fuse
install_apt_package mtp-tools
install_apt_package jmtpfs

# Utils
install_apt_package libfuse2t64
install_apt_package htop
install_apt_package unzip
install_apt_package 7zip
install_apt_package uuid
install_apt_package whois
install_apt_package ack
install_apt_package mc
install_apt_package jq
install_apt_package bc
install_apt_package transmission-cli
