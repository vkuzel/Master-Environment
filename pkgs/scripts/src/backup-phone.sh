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

phoneBaseDir="$phoneDevice/Phone"
if [[ ! -d "$phoneBaseDir" ]]; then
  error "Couldn't find phone base dir $phoneBaseDir"
fi

rsync \
	--archive \
	--delete \
	--progress \
	--ignore-missing-args \
	--mkpath \
  "$phoneBaseDir/Alarms" \
  "$phoneBaseDir/Android/media" \
  "$phoneBaseDir/Audiobooks" \
  "$phoneBaseDir/DCIM" \
  "$phoneBaseDir/Documents" \
  "$phoneBaseDir/Download" \
  "$phoneBaseDir/LazyList" \
  "$phoneBaseDir/Movies" \
  "$phoneBaseDir/Music" \
  "$phoneBaseDir/Notifications" \
  "$phoneBaseDir/Pictures" \
  "$phoneBaseDir/Podcasts" \
  "$phoneBaseDir/Recordings" \
  "$phoneBaseDir/Ringtones" \
	"$backupDir"
