#!/bin/bash

# Hack to mitigate issue w/ switching keyboard layouts in early versions of
# Sway 1.7: https://github.com/swaywm/sway/issues/6011
#
# On a newer Sway version, the `xkb_options "grp:alt_space_toggle"` shlould be
# used instead.

activeLayoutIndex=$(swaymsg -t get_inputs | grep -i xkb_active_layout_index | head -n 1 | grep -Eo "[0-9]")

if [ "$activeLayoutIndex" == "0" ]; then
	swaymsg input type:keyboard xkb_switch_layout 1
else
	swaymsg input type:keyboard xkb_switch_layout 0
fi

