#!/bin/bash

error() {
  echo "$1"
  exit 1
}

restoreFrom() {
  local sourceDir="$1"
  local targetDir="$2"
  local modes="${3:-D755,F644}"

  rsync \
    --recursive \
    --links \
    --times \
    --progress \
    --ignore-missing-args \
    --mkpath \
    --no-perms \
    --no-owner \
    --no-group \
    --chmod="$modes" \
    "$sourceDir" \
    "$targetDir"
}

restoreGitFileModes() {
  local projectsDir="$1"

  [[ -d "$projectsDir" ]] || return 0

  while read -r gitDir; do
    local workTree="${gitDir%/.git}"
    echo "Restoring file modes in $workTree"
    git --git-dir="$gitDir" --work-tree="$workTree" ls-files --stage -z \
      | while IFS= read -r -d '' entry; do
        local mode="${entry%% *}"
        local file="${entry#*$'\t'}"
        [[ "$mode" == "100755" ]] || continue
        chmod +x "$workTree/$file" 2>/dev/null
      done
  done < <(find "$projectsDir" -maxdepth 4 -type d -name ".git")
}

hostname="$1"
if [[ -z "$hostname" ]]; then
  hostname=$(hostname)
fi

backupDevice="$2"
if [[ -z "$backupDevice" ]]; then
  firstDevice=$(ls /media/ | grep "encrypted" | sort | head -1)
  [[ ! -z "$firstDevice" ]] || error "Couldn't find backup device mount /media/encrypted*"
  backupDevice="/media/$firstDevice"
fi

[[ -d "$backupDevice" ]] || error "Backup device $backupDevice does not exist!"

currentYear=$(date "+%Y")
backupDir="$backupDevice/$hostname/$currentYear"

[[ -d "$backupDir" ]] || error "Backup $backupDir does not exist!"

read -p "Restore from $backupDir into $HOME [y/N]" answer
[[ "y" == "$answer" || "Y" == "$answer" ]] || exit

restoreFrom "$backupDir/Documents" "$HOME"
restoreFrom "$backupDir/projects" "$HOME"
restoreFrom "$backupDir/Music" "$HOME"
restoreFrom "$backupDir/Videos" "$HOME"
restoreFrom "$backupDir/Pictures" "$HOME"

restoreGitFileModes "$HOME/projects"
