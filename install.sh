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
		sudo apt purge --yes cloud-init
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
		sudo apt purge -- yes networkd-dispatcher
		info "Restart NetworkManager"
		sudo systemctl restart NetworkManager
	fi
}

configure_dark_mode() {
	info "=== Configure dark mode ==="
	local colorScheme=$(gsettings get org.gnome.desktop.interface color-scheme)
	if [[ "$colorScheme" == "'prefer-dark'" ]]; then
		info "Already configured"
	else
		info "Set gsettings color scheme"
		gsettings set org.gnome.desktop.interface color-scheme prefer-dark
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
		sudo apt install --yes "$pkgName"
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

install_bubblewrap_apparmor_profile() {
	# The profile should be included in new versions of Ubuntu, but its not in Ubuntu 24.04 yet.
	# Deets: https://www.staldal.nu/tech/2025/10/19/linux-sandboxing-with-bubblewrap/
	local source="system/bwrap-userns-restrict"
	local target="/etc/apparmor.d/bwrap-userns-restrict"

	info "=== Install AppArmor bubblewrap profile ==="
	if [[ -e "$target" ]]; then
		info "Already installed"
	else
		sudo cp "$source" "$target"
		sudo service apparmor reload
	fi
}

install_plugin_from_github_archive() {
	local pluginName="$1"
	local pluginUrl="$2"
	local pluginDir="$3"

	if [[ -z "$pluginName" ]]; then
		fail "Plugin name cannot be resolved from $pluginUrl"
	fi

	if [[ -d "$pluginDir" ]]; then
		info "Already installed"
	else
		local pluginArchiveDir=$(mktemp -d --suffix="$pluginName")

		local pluginArchivePath="$pluginArchiveDir/$pluginName.zip"
		curl --location --output "$pluginArchivePath" --remote-name "$pluginUrl"

		local pluginUnzipDir="$pluginArchiveDir/content"
		python3 -m zipfile -e "$pluginArchivePath" "$pluginUnzipDir"

		local pluginSrcDir="$pluginUnzipDir/$(ls "$pluginUnzipDir")"
		mkdir -p $(dirname "$pluginDir")
		mv "$pluginSrcDir" "$pluginDir"

		rm -r "$pluginArchiveDir"
	fi
}

install_micro_plugin() {
	local pluginUrl="$1"
	local pluginName=$(echo $pluginUrl | grep -Eo "[^/]+/archive" | grep -Eo "^[^/]+")
	local pluginDir="$HOME/.config/micro/plug/$pluginName"

	info "=== Install Micro plugin $pluginName ==="
	install_plugin_from_github_archive "$pluginName" "$pluginUrl" "$pluginDir"
}

install_nix() {
  info "=== Install nix ==="
	if [[ -d "/nix" ]]; then
		info "Already installed"
	else
	  curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
	  info "Enable experimental features"
	  echo 'experimental-features = nix-command flakes' | sudo tee -a "/etc/nix/nix.conf" >/dev/null
	  info "Restart nix-daemon"
	  sudo systemctl restart nix-daemon
	fi
}

source_nix_profile() {
	local nixProfile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
	if ! command -v nix > /dev/null && [ -e "$nixProfile" ]; then
		info "Source default nix profile"
		set +u
		source "$nixProfile"
		set -u
	fi
}

remove_legacy_nix_profile() {
	info "=== Remove legacy nix profile ==="
	# Applications used to be installed by `nix profile add`. They are managed
	# by home-manager now, so the old generation has to be dropped first.
	if nix profile list 2>/dev/null | grep -q "master-environment"; then
		nix profile remove --all
	else
		info "Already removed"
	fi
}

install_home_manager() {
	info "=== Activate home-manager generation ==="
	# The `path:` reference is used on purpose, a plain path would be resolved
	# to the git tree and would not see uncommitted changes.
	local flakeRef="path:$(realpath "nix")"
	local attribute="$flakeRef#homeConfigurations.master-environment.activationPackage"
	local features="nix-command flakes"

	info "Lock missing flake inputs (if any)"
	nix --extra-experimental-features "$features" flake lock "$flakeRef"

	# The configuration reads $USER and $HOME, thus it has to be evaluated
	# impurely. The activation package is built directly, so the home-manager
	# command does not have to be installed beforehand.
	info "Build the home-manager generation"
	local activationPackage
	activationPackage=$(nix --extra-experimental-features "$features" \
		build --impure --no-link --print-out-paths "$attribute")

	info "Activate the home-manager generation"
	"$activationPackage/activate"
}

setup_nix_gpu_drivers() {
	info "=== Setup GPU drivers for nix applications ==="
	# Nix applications look for GPU drivers in /run/opengl-driver. The setup
	# command is provided by the home-manager targets.genericLinux module and
	# has to run as root. It is idempotent and has to be re-run whenever the
	# drivers in the nix store change.
	local setupCommand="$HOME/.nix-profile/bin/non-nixos-gpu-setup"
	if [ ! -x "$setupCommand" ]; then
		fail "$setupCommand not found, did the home-manager activation succeed?"
	fi
	sudo "$setupCommand"
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

# The home-manager configuration reads the user from the environment, see
# nix/flake.nix. The variable is not set in every shell, e.g., under `sudo -i`.
export USER="${USER:-$(id -un)}"

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

# Nix
# Applications and the session environment are managed by home-manager, see
# nix/home.nix
install_nix
source_nix_profile
remove_legacy_nix_profile
install_home_manager
setup_nix_gpu_drivers

# Shell
# Fonts, Starship and ZSH plugins are installed by nix, see nix/home.nix
# Fontconfig stays on APT, it renders fonts for the APT applications as well
install_apt_package fontconfig
# ZSH stays on APT, chsh needs a stable path listed in /etc/shells
install_apt_package zsh
chsh_zsh

# Sway
# Sway, Xwayland, swayidle, foot, waybar, fuzzel, sway-notification-center,
# libnotify, brightnessctl, playerctl, grim, slurp and chafa are installed by
# nix, see nix/home.nix
# Swaylock stays on APT, it has to be setuid root to read /etc/shadow and nix
# cannot install setuid binaries into a user profile
install_apt_package swaylock
install_apt_package desktop-file-utils
# Add the user into the video group to use brightnessctl
add_current_user_into_group video

# screen sharing
# Guidelines: https://wiki.archlinux.org/title/XDG_Desktop_Portal
# Run sway in D-Bus session to allow screensharing, i.e., `dbus-run-session sway`
# Test: https://mozilla.github.io/webrtc-landing/gum_test.html
install_apt_package xdg-desktop-portal-wlr
# Provides desktop-portal integration for GTK 3 applications. E.g., file picker
# dialog for Outlook running in Chrome.
install_apt_package xdg-desktop-portal-gtk
# When Gtk portal is installed Firefox reads color scheme (dark mode)
# information from `gsettings` instead of GTK 3 settings file. Thus,
# appropriate configuration has to be set.
configure_dark_mode

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

# Python libs
install_apt_package python3-tk
install_apt_package python3-pil
install_apt_package python3-pil.imagetk
install_apt_package python3-yaml

# AI isolation
install_bubblewrap_apparmor_profile

# Mozilla Thunderbird and Firefox
# Installed from APT to keep the Mozilla's PPA builds and system integration
install_apt_package software-properties-common
configure_mozilla_apt_repository
install_apt_package firefox
install_apt_package thunderbird

# Office utils
# MPV, Micro, GIMP and wl-clipboard are installed by nix, see nix/home.nix
install_micro_plugin "https://github.com/vkuzel/Micro-Filemanager-Plugin/archive/refs/heads/main.zip"

# Android file mount
# The MTP tools rely on the system FUSE and GVfs setup, thus they stay on APT
install_apt_package gvfs-backends
install_apt_package gvfs-fuse
install_apt_package mtp-tools
install_apt_package go-mtpfs

# Utils
# 7zz, ack, bc, fastfetch, htop, jq, mc, transmission, unzip and whois are
# installed by nix, see nix/home.nix
install_apt_package libfuse2t64
install_apt_package uuid
