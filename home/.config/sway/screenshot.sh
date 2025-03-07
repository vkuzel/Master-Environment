#!/bin/bash

if [[ "$1" == "--focused-window" ]]; then
	region="$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"')"
else
	# whole screen
	region="$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"')"
fi

GRIM_DEFAULT_DIR="$HOME/Downloads" grim -g "$region"

