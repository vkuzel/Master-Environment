#!/bin/bash

info() {
	printf "  [ \033[00;34m..\033[0m ] $1\n"
}

fail() {
	printf "\033[2K  [\033[0;31mFAIL\033[0m] $1\n" >> /dev/stderr
	exit 1
}

check_os() {
	if [ "$(uname)" != "Linux" ]; then
		fail "Run this script on Linux!"
	fi
}

check_working_dir() {
	if [ ! -d "home" ]; then
		fail "Run this script from the projects dir!"
	fi
}

configure_timezone() {
	info "=== Configure timezone ==="
	if [[ -e "/etc/timezone" ]]; then
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
    read
    	sudo dpkg-reconfigure cloud-init
    	sudo apt purge cloud-init
    	sudo rm -rf /etc/cloud/ /var/lib/cloud/ /etc/netplan/*cloud-init.yaml
  fi
}

configure_network_manager() {
  info "=== Configure Network Manager ==="
  if [[ ! -e "/etc/systemd/system/dbus-org.freedesktop.network1.service" ]]; then
    info "Already configured"
  else
    info "Disable systemd-networkd"
    sudo systemctl disable systemd-networkd systemd-networkd.socket
  fi
}

install_nerd_fonts() {
	info "=== Install Nerd Fonts ==="
	if [ -d "/usr/share/fonts/truetype/dejavu-nerd" ]; then
		info "Already installed"
	else
		local fontFile="DejaVuSansMono.zip"
		local fontUrl="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/$fontFile"
		local targetDir="/usr/share/fonts/truetype/dejavu-nerd"

		curl --location --output-dir "/tmp/" --remote-name "$fontUrl" || fail "Cannot download font!"
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
    # Due to a bug, after installing and pinning the Mozilla's package, we have
    # to decrease priority of Ubuntu's Firefox meta-package to prevent
    # overriding the previous one: https://bugs.launchpad.net/ubuntu/+source/firefox/+bug/1999308
    cat <<EOF | sudo tee /etc/apt/preferences.d/mozillateamppa > /dev/null || fail "Cannot set Mozilla PPA!"
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
    sudo apt update || fail "Cannot APT update!"
  fi
}

install_apt_package() {
	local pkgName=$1

	info "=== Install $pkgName ==="
	local status=$(dpkg --status "$pkgName" 2>/dev/null)
	if [[ ! -z "$status" ]]; then
		info "Already installed"
	else
		sudo apt install "$pkgName"
	fi
}

uninstall_apt_package() {
	local pkgName=$1

	info "=== Uninstall $pkgName ==="
	local status=$(dpkg --status "$pkgName" 2>/dev/null)
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
		git pull || fail "Cannot pull $pluginName"
		popd > /dev/null
	else
		git clone "$pluginUrl" "$pluginDir" || fail "Cannot clone Git repository $pluginUrl into $pluginDir"
	fi
}

install_gedit_overscroll_plugin() {
  local pluginUrl=https://github.com/hardpixel/gedit-scroll-past.git
  local pluginsDir="$HOME/.local/share/gedit/plugins"
  local pluginDir="$pluginsDir/gedit-scroll-past"

  info "=== Install gedit overscroll plugin ==="
  if [[ ! -d "$pluginDir" ]]; then
    git clone "$pluginUrl" "$pluginDir" || fail "Cannot clone Git repository $pluginUrl into $pluginDir"
  else
    info "Already installed"
  fi
}

create_directory_structure() {
	info "=== Create directory structure ==="
	local src_dir=$1
	local dst_dir=$2

	pushd "$src_dir" > /dev/null

	for dir_path in $(find . -mindepth 1 -type d); do
		local dst_path="$dst_dir/$dir_path"
		if [ -d "$dst_path" ]; then
			continue
		fi
		
		info "Create $dst_path"
		mkdir -p "$dst_path" || fail "Cannot create $dst_path"
	done

	popd > /dev/null
}

normalpath() {
	local path=$1
	# Hacky path normalization
	echo "$1" | sed "s/\/.\//\//g"
}

create_links() {
	info "=== Create links ==="
  local src_dir=$1
  local dst_dir=$2

  pushd "$src_dir" > /dev/null

  for file_path in $(find . -mindepth 1 -type f); do
		local src_path=$(realpath "$file_path")
                local dst_path=$(normalpath "$dst_dir/$file_path")
		if [ -h "$dst_path" ]; then
			continue
    elif [ -e "$dst_path" ]; then
      info "Cannot symlink into existing regular file $dst_path"
		else
      info "Create $dst_path"
			ln -s "$src_path" "$dst_path" || fail "Cannot create symlink $dst_path"
    fi
  done

  popd > /dev/null
}

chsh_zsh() {
  info "=== ChSh to ZSH ==="
  if [ "$SHELL" != "/bin/zsh" ]; then
    chsh $USER -s /bin/zsh
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
install_apt_package zsh
install_starship
install_zsh_plugin "https://github.com/zsh-users/zsh-autosuggestions.git"
install_zsh_plugin "https://github.com/zsh-users/zsh-history-substring-search.git"
install_zsh_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git"
chsh_zsh

# Sway - screen sharing
# Guidelines: https://wiki.archlinux.org/title/XDG_Desktop_Portal
# Run sway in D-Bus session to allow screensharing, i.e., `dbus-run-session sway`
# Test: https://mozilla.github.io/webrtc-landing/gum_test.html
install_apt_package xdg-desktop-portal-wlr

# Dotfiles
create_directory_structure $SRC_DIR $DST_DIR
create_links $SRC_DIR $DST_DIR

# Mozilla Thunderbird and Firefox
configure_mozilla_apt_repository
install_apt_package firefox-esr
install_apt_package thunderbird

# Office utils
install_apt_package gedit
install_gedit_overscroll_plugin

# Android file mount
install_apt_package gvfs-backends
install_apt_package gvfs-fuse
install_apt_package mtp-tools
install_apt_package jmtpfs

# Utils
install_apt_package htop
install_apt_package unzip
install_apt_package 7zip
install_apt_package uuid
install_apt_package whois
install_apt_package ack
install_apt_package jq
install_apt_package mc

