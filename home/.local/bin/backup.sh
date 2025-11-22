#!/bin/bash
# Backup user data to backup device

error() {
  echo "$1"
  exit 1
}

backupDevice="$1"
if [[ -z "$backupDevice" ]]; then
  firstDevice=$(ls /media/ | grep "encrypted" | sort | head -1)
  [[ ! -z "$firstDevice" ]] || error "Couldn't find backup device mount /media/encrypted*"
  backupDevice="/media/$firstDevice"
fi

[[ -d "$backupDevice" ]] || error "Backup device $backupDevice does not exist!"

hostname=$(hostname)
currentYear=$(date "+%Y")
backupDir="$backupDevice/$hostname/$currentYear"

read -p "Backup into $backupDir? [y/N]" answer
[[ "y" == "$answer" || "Y" == "$answer" ]] || exit

rsync \
	--archive \
	--delete \
	--progress \
	--ignore-missing-args \
	--mkpath \
	--exclude="node_modules/" \
	--exclude=".gradle" \
	--exclude=".kotlin" \
	--exclude="build" \
	"$HOME/Documents" \
	"$HOME/projects" \
	"$HOME/Music" \
	"$HOME/Videos" \
	"$HOME/Pictures" \
	"$backupDir"
