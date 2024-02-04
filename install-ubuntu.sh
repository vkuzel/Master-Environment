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

install_nerd_fonts() {
	info "=== Install Nerd Fonts ==="
	if [ ! -d "/usr/share/fonts/truetype/dejavu-nerd" ]; then
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

install_apt_package() {
	local pkgName=$1

	info "=== Install $pkgName ==="
	local status=$(dpkg --status "$pkgName" 2>/dev/null)
	if [[ -z "$status" ]]; then
		sudo apt install "$pkgName"
	else
		info "Already installed"
	fi
}

uninstall_apt_package() {
	local pkgName=$1

	info "=== Uninstall $pkgName ==="
	local status=$(dpkg-cache --status "$pkgName" 2>/dev/null)
	if [[ ! -z "$status" ]]; then
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

install_lite_xl() {
	local editorUrl="$1"
	local installDir=/opt/lite-xl
	local archiveFile=$(echo "$editorUrl" | grep -Eo "[^/]+$")

	info "=== Install Lite XL $archiveFile ==="

	if [[ ! -d "$installDir" ]]; then
		pushd /tmp > /dev/null
		curl --location "$editorUrl" --output "$archiveFile" || fail "Cannot download $editorUrl"
		tar -xzf "$archiveFile" || fail "Cannot unpack $archiveFile"

		sudo mv lite-xl "$installDir" || fail "Cannot install into $installDir"
		sudo chown -R root:root "$installDir"

		rm "$archiveFile"
		popd > /dev/null
	else
		info "Already installed"
	fi
}

install_lite_xl_plugin() {
	local pluginUrl="$1"
	local pluginsDir="$HOME/.config/lite-xl/plugins"
	local pluginFile=$(echo "$pluginUrl" | grep -Eo "[^/]+$" | grep -Eo "^[^?]+")

	info "=== Install Lite XL plugin: $pluginFile ==="

	if [[ ! -f "$pluginsDir/$pluginFile" ]]; then
		pushd /tmp > /dev/null
		mkdir -p "$pluginsDir" || fail "Cannot create dir $pluginsDir"
		curl --location "$pluginUrl" --output "$pluginFile" || fail "Cannot download $pluginUrl"
		mv "$pluginFile" "$pluginsDir" || fail "Cannot install into $pluginsDir"
		popd > /dev/null
	else
		info "Already installed"
	fi
}

install_lite_xl_desktop_file() {
	local desktopFile="lite-xl.desktop"

	info "=== Install Lite XL desktop file: $desktopFile ==="

	pushd /tmp > /dev/null
	cat <<- 'DESKTOP_FILE' > "$desktopFile"
	[Desktop Entry]
	Type=Application
	Name=Lite XL
	GenericName=Text Editor
	Comment=Lite XL Text Editor

	Categories=Utility;Development;TextEditor;IDE
	Keywords=Text;Editor;
	MimeType=text/plain;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;text/x-java;text/x-dsrc;text/x-pascal;text/x-perl;text/x-python;application/x-php;application/x-httpd-php3;application/x-httpd-php4;application/x-httpd-php5;application/xml;text/html;text/css;text/x-sql;text/x-diff;

	Exec=/opt/lite-xl/lite-xl
	Terminal=false
DESKTOP_FILE
	if command -v desktop-file-install &> /dev/null; then
		# Gnome desktop
		sudo desktop-file-install --rebuild-mime-info-cache "$desktopFile"
	elif [[ ! -f "/usr/share/applications/$desktopFile" ]]; then
		sudo cp -f "$desktopFile" /usr/share/applications
	fi
	rm "$desktopFile"
	popd > /dev/null
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
                        fail "Cannot symlink into existing regular file $dst_path"
                fi

                info "Create $dst_path"
		ln -s "$src_path" "$dst_path" || fail "Cannot create symlink $dst_path"
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
uninstall_apt_package byobu
uninstall_apt_package tilix
uninstall_apt_package screen
uninstall_apt_package tmux
uninstall_apt_package cloud-guest-utils
uninstall_apt_package cloud-initramfs-copymods
uninstall_apt_package cloud-initramfs-dyn-netconf

# Shell
install_nerd_fonts
install_apt_package zsh
install_starship
install_zsh_plugin "https://github.com/zsh-users/zsh-autosuggestions.git"
install_zsh_plugin "https://github.com/zsh-users/zsh-history-substring-search.git"
install_zsh_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git"
chsh_zsh

# Dotfiles
create_directory_structure $SRC_DIR $DST_DIR
create_links $SRC_DIR $DST_DIR

# Utils
install_lite_xl "https://github.com/lite-xl/lite-xl/releases/download/v2.1.3/lite-xl-v2.1.3-addons-linux-x86_64-portable.tar.gz"
install_lite_xl_plugin "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/autosave.lua"
install_lite_xl_plugin "https://github.com/lite-xl/lite-xl-plugins/blob/master/plugins/gitstatus.lua?raw=1"
install_lite_xl_plugin "https://github.com/lite-xl/lite-xl-plugins/blob/master/plugins/minimap.lua?raw=1"
install_lite_xl_desktop_file

