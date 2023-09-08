#!/bin/bash

fail() {
	echo "$1" >> /dev/stderr
	exit 1
}

check_os() {
	if [ "$(uname)" != "Darwin" ]; then
		fail "Run this script on macOS!"
	fi
}

check_working_dir() {
	if [ ! -d "home" ]; then
		fail "Run this script from the projects dir!"
	fi
}

install_apps() {
	echo "=== Install Apps ==="
}

create_directory_structure() {
	echo "=== Create directory structure ==="
	local src_dir=$1
	local dst_dir=$2

	pushd "$src_dir" > /dev/null

	for dir_path in $(find . -mindepth 1 -type d); do
		local dst_path="$dst_dir/$dir_path"
		if [ -d "$dst_path" ]; then
			continue
		fi
		
		echo "Create $dst_path"
		mkdir -p "$dst_path" || fail "Cannot create $dst_path"
	done

	popd > /dev/null
}

clone_git_project() {
	local project_name=$1
	local repo_dir=$2
	local repo_url=$3

	echo "$project_name"
	if [ -d "$repo_dir/.git" ]; then
		pushd "$repo_dir" >> /dev/null
		git pull || fail "Cannot pull Git repository $repo_url into $repo_dir"
		popd
	else
		git clone "$repo_url" "$repo_dir" || fail "Cannot clone Git repository $repo_url into $repo_dir"
	fi
}

clone_git_projects() {
	echo "=== Clone/update Git projects ==="
	local dst_dir=$1

	clone_git_project "zsh-autosuggestions" \
		"$dst_dir/.config/zsh/zsh-autosuggestions" \
		"git@github.com:zsh-users/zsh-autosuggestions.git"
	clone_git_project "zsh-history-substring-search" \
		"$dst_dir/.config/zsh/zsh-history-substring-search" \
		"git@github.com:zsh-users/zsh-history-substring-search.git"
	clone_git_project "zsh-syntax-highlighting" \
		"$dst_dir/.config/zsh/zsh-syntax-highlighting" \
		"git@github.com:zsh-users/zsh-syntax-highlighting.git"
}

normalpath() {
	local path=$1
	# Hacky path normalization
	echo "$1" | sed "s/\/.\//\//g"
}

create_links() {
	echo "=== Create links ==="
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

                echo "Create $dst_path"
		ln -s "$src_path" "$dst_path" || fail "Cannot create symlink $dst_path"
        done

        popd > /dev/null
}

check_os
check_working_dir

SRC_DIR=home
DST_DIR=$HOME

install_apps
create_directory_structure $SRC_DIR $DST_DIR
clone_git_projects $DST_DIR
create_links $SRC_DIR $DST_DIR

