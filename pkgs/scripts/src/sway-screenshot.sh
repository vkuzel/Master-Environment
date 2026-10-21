#!/bin/bash

if [[ "$1" == "--focused-window" ]]; then
	windowName=$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .name')
	fileName="screenshot-$windowName-$(date +'%Y-%m-%d_%H-%M-%S').png"
	region="$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"')"
else
	# selected region
	fileName="screenshot-region-$(date +'%Y-%m-%d_%H-%M-%S').png"
	region="$(slurp)" || exit 1
fi

escapedFileName=$(echo "$fileName" | sed 's/\//-/g')
filePath="$HOME/Downloads/$escapedFileName"

grim -g "$region" "$filePath"
notify-send --urgency=low "Screenshot" "$filePath"

