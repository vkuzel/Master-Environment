#!/bin/bash
# Backup user data to backup device

error() {
  echo "$1"
  exit 1
}

backupDevice="/media/veracrypt1"

[[ -d "$backupDevice" ]] || error "Backup device $backupDevice does not exist!"

hostname=$(hostname)
currentMonth=$(date "+%Y-Q$(( ( $(date +%-m) - 1 ) / 3 + 1 ))")
backupDir="$backupDevice/$hostname/$currentMonth"

echo "Backup into $backupDir"
rsync \
	--archive \
	--delete \
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
	"$backupDir"
