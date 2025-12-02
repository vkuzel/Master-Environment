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

purge_apt_package() {
	local pkgName=$1

	info "=== Purge $pkgName ==="
	local status=$(dpkg --status "$pkgName" 2>/dev/null || true)
	if [[ -z "$status" ]]; then
		info "Already purged"
	else
		sudo apt purge "$pkgName"
	fi
}

purge_apt_package gedit
purge_apt_package vim
# Provides desktop-portal integration for GTK 3 applications. When installed,
# for example Firefox loads color scheme (dark mode) configuration from
# `gsettings` instead of GTK 3 settings file. Thus, appropriate configuration
# has to be set: `gsettings set org.gnome.desktop.interface color-scheme prefer-dark`
purge_apt_package xdg-desktop-portal-gtk
remove_dir "$HOME/.local/share/gedit"
remove_dir "$HOME/.local/config/gedit"
remove_link "$HOME/.vimrc"
remove_link "$HOME/.local/bin/mountui.sh"
