#!/bin/bash

if [[ "$1" == "--focused-window" ]]; then
	windowName=$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .name')
	fileName="screenshot-$windowName-$(date +'%Y-%m-%d_%H-%M-%S').png"
	region="$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"')"
else
	# whole screen
	workspaceNo=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .current_workspace')
	fileName="screenshot-workspace-$workspaceNo-$(date +'%Y-%m-%d_%H-%M-%S').png"
	region="$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"')"
fi

grim -g "$region" "$HOME/Downloads/$fileName"

