#!/bin/bash

while IFS= read -r -d '' file; do
	chafa --animate off "$file"
	read -p "Delete file $file [y/N] " answer < /dev/tty
	if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
		rm "$file"
	fi
	echo
done < <(find . \( -iname "*.jpeg" -o -iname "*.jpg" -o -iname "*.gif" -o -iname "*.bmp" \) -print0)

