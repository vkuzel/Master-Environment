#!/bin/bash

region="$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"')"

GRIM_DEFAULT_DIR="$HOME/Downloads" grim -g "$region"
