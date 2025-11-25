#!/bin/bash
# Backup user data to backup device

error() {
  echo "$1"
  exit 1
}

prepareFirefoxBackupInto() {
  local tmpDir="$1"
  local backupDir="$tmpDir/firefox-bookmarks"

  mkdir "$backupDir" || error "Cannot create directory $backupDir"
  find $HOME/.mozilla/firefox/*.default-release/bookmarkbackups \
    -name "bookmarks*jsonlz4" \
    -exec cp {} "$backupDir" \;

  echo "$backupDir"
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

read -p "Backup into $backupDir [y/N]" answer
[[ "y" == "$answer" || "Y" == "$answer" ]] || exit

tmpDir=$(mktemp --directory --suffix=backup)

firefoxBackupDir=$(prepareFirefoxBackupInto "$tmpDir")

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
  "$firefoxBackupDir" \
	"$backupDir"

rm -r "$tmpDir"
