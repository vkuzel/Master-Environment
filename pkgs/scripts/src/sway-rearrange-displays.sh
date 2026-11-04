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

resolve_output_width() {
  local output=$1
  swaymsg -r -t get_outputs \
    | jq ".[] | select(.name == \"$output\") | .current_mode.width"
}

default_output=$(resolve_default_output)
output1=$(resolve_output_no 1 "$default_output")
output2=$(resolve_output_no 2 "$output1")

default_output_position_x=0
swaymsg output $default_output pos $default_output_position_x 0
echo "output $default_output pos $default_output_position_x 0"

echo "$output1"
if [[ -n "$output1" ]]; then
  default_output_width=$(resolve_output_width "$default_output")
  output1_position_x=$default_output_width
  swaymsg output $output1 pos $output1_position_x 0
  echo "output $output1 pos $output1_position_x 0"
fi

if [[ "$output1" != "$output2" ]]; then
  default_output_width=$(resolve_output_width "$default_output")
  output1_width=$(resolve_output_width "$output1")
  output2_position_x=$(($default_output_width + $output1_width))
  swaymsg output $output2 pos $output2_position_x 0
fi
