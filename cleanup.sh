#!/bin/bash

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
	local status=$(dpkg --status "$pkgName" 2>/dev/null)
	if [[ -z "$status" ]]; then
		info "Already purged"
	else
		sudo apt purge "$pkgName"
	fi
}

purge_apt_package gedit
purge_apt_package vim
remove_dir "$HOME/.local/share/gedit"
remove_dir "$HOME/.local/config/gedit"
remove_file "$HOME/.vimrc"
remove_link "$HOME/.local/bin/mountui.sh"
