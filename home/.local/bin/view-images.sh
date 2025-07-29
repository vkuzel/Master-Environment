#!/bin/bash

find -iname "*.jpeg" -o -iname "*.jpg" -o -iname "*.gif" -o -iname "*.bmp"

while IFS= read -r -d '' file; do
	chafa --speed 1000fps "$file"
	read -p "Delete file $file [y/N] " answer < /dev/tty
	if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
		rm "$file"
	fi
	echo
done < <(find . \( -iname "*.jpeg" -o -iname "*.jpg" -o -iname "*.gif" -o -iname "*.bmp" \) -print0)

