#!/bin/bash

outputs=$(swaymsg -r -t get_outputs | jq -r '.[].name')

resolve_default_output() {
	echo "$outputs" | grep -E '^eDP-[0-9]$'
}

resolve_output_no() {
	local number=$1
	local default_output=$2
	echo "$outputs" \
		| grep -E '^DP-[0-9]+$'\
		| awk "NR==$number{print; found=1} END{if (!found) print \"$default_output\"}"
}

move_workspaces() {
	local output1=$1
	local output2=$2

	visible1=$(swaymsg -t get_workspaces | jq -r '.[] | select(.visible).name' | grep -E '^[1-6]$')
	visible2=$(swaymsg -t get_workspaces | jq -r '.[] | select(.visible).name' | grep -E '^[7-9]$')

	for i in {1..6}; do \
		swaymsg "workspace $i; move workspace to output $output1"
	done
	for i in {7..9}; do \
		swaymsg "workspace $i; move workspace to output $output2"
	done

	# Focus on last opened workspaces
	swaymsg "workspace $visible2"
	swaymsg "workspace $visible1"
}

default_output=$(resolve_default_output)
output1=$(resolve_output_no 1 "$default_output")
output2=$(resolve_output_no 2 "$output1")

toggle_file=/tmp/should-flip-sway-outputs
if [[ -f "$toggle_file" ]]; then
	move_workspaces "$output1" "$output2"
	rm "$toggle_file"
else
	move_workspaces "$output2" "$output1"
	touch "$toggle_file"
fi

