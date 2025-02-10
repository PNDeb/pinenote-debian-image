#!/bin/sh

focusedtransform() {
	swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .transform'
}

focusedname() {
	swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .name'
}

startlisgd() {
  launch_lisgd.sh
}

rotnormal() {
	swaymsg -- output "-" transform 0 scale 1
	focused_name="$(focusedname)"
	swaymsg -- input type:touch map_to_output "$focused_name"
	swaymsg -- input type:tablet_tool map_to_output "$focused_name"
	startlisgd 0
	exit 0
}

rotleft() {
	swaymsg -- output "-" transform 90 scale 1
	focused_name="$(focusedname)"
	swaymsg -- input type:touch map_to_output "$focused_name"
	swaymsg -- input type:tablet_tool map_to_output "$focused_name"
	startlisgd 3
	exit 0
}

rotright() {
	swaymsg -- output "-" transform 270 scale 1
	focused_name="$(focusedname)"
	swaymsg -- input type:touch map_to_output "$focused_name"
	swaymsg -- input type:tablet_tool map_to_output "$focused_name"
	startlisgd 1
	exit 0
}

rotinvert() {
	swaymsg -- output "-" transform 180 scale 1
	focused_name="$(focusedname)"
	swaymsg -- input type:touch map_to_output "$focused_name"
	swaymsg -- input type:tablet_tool map_to_output "$focused_name"
	startlisgd 2
	exit 0
}

"$@"
