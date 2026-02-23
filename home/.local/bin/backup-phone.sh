#!/bin/bash
# Backup Android phone to backup device
# Both devices phone and backup device have to be mounted

error() {
  echo "$1"
  exit 1
}

phoneDevice="$1"
if [[ -z "$phoneDevice" ]]; then
  firstDevice=$(ls /media/ | grep "android" | sort | head -1)
  [[ ! -z "$firstDevice" ]] || error "Couldn't find phone device mount /media/android*"
  phoneDevice="/media/$firstDevice"
fi

backupDevice="$2"
if [[ -z "" ]]; then
  firstDevice=$(ls /media/ | grep "encrypted" | sort | head -1)
  [[ ! -z "$firstDevice" ]] || error "Couldn't find backup device mount /media/encrypted*"
  backupDevice="/media/$firstDevice"
fi

phoneName=$(echo $phoneDevice | grep -Eo "android.*")
currentYear=$(date "+%Y")
backupDir="$backupDevice/$phoneName/$currentYear"

read -p "Backup $phoneDevice into $backupDir [y/N]" answer
[[ "y" == "$answer" || "Y" == "$answer" ]] || exit

backupTarget() {
  echo "=== $phoneDevice/Phone/$1 === "
  ls $phoneDevice/Phone/$1
}

rsync \
	--archive \
	--delete \
	--progress \
	--ignore-missing-args \
	--mkpath \
  "$phoneDevice/Phone/Alarms" \
  "$phoneDevice/Phone/Android/media" \
  "$phoneDevice/Phone/Audiobooks" \
  "$phoneDevice/Phone/DCIM" \
  "$phoneDevice/Phone/Documents" \
  "$phoneDevice/Phone/Download" \
  "$phoneDevice/Phone/LazyList" \
  "$phoneDevice/Phone/Movies" \
  "$phoneDevice/Phone/Music" \
  "$phoneDevice/Phone/Notifications" \
  "$phoneDevice/Phone/Pictures" \
  "$phoneDevice/Phone/Podcasts" \
  "$phoneDevice/Phone/Recordings" \
  "$phoneDevice/Phone/Ringtones" \
	"$backupDir"
