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
	swaymsg "workspace 1; move workspace to output $output1"
	swaymsg "workspace 2; move workspace to output $output1"
	swaymsg "workspace 3; move workspace to output $output1"
	swaymsg "workspace 4; move workspace to output $output1"
	swaymsg "workspace 5; move workspace to output $output1"
	swaymsg "workspace 6; move workspace to output $output1"
	swaymsg "workspace 7; move workspace to output $output2"
	swaymsg "workspace 8; move workspace to output $output2"
	swaymsg "workspace 9; move workspace to output $output2"
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

