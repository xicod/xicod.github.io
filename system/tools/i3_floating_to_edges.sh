#!/bin/bash

WINDOW_TITLE_HEIGHT=22
WINDOW_BORDER_WIDTH=3

eval $(i3-msg -t get_workspaces | jq -r 'map(select(.focused))[0].rect | to_entries | .[] | .key + "=" + (.value | @sh)')

function set_window_vars {
	if [ -n "$WINDOW_OVERRIDE" ]; then
		eval $(xdotool getwindowgeometry --shell $WINDOW_OVERRIDE)
	else
		eval $(xdotool getactivewindow getwindowgeometry --shell)
	fi
}

set_window_vars

if [ -n "$RESIZE_WINDOW_PERCENT_W" ]; then
	xdotool windowfocus --sync $WINDOW
	i3-msg "resize set $RESIZE_WINDOW_PERCENT_W ppt"

	set_window_vars
fi

case $1 in
	left)
		coord="$((x+WINDOW_BORDER_WIDTH)) y"
		;;
	right)
		coord="$((x+width-WIDTH-WINDOW_BORDER_WIDTH)) y"
		;;
	up)
		coord="x $((y+WINDOW_TITLE_HEIGHT))"
		;;
	down)
		coord="x $((y+height-HEIGHT-WINDOW_BORDER_WIDTH))"
		;;
	*)
		echo "Bad input"
		exit 1
		;;
esac

xdotool windowmove --sync $WINDOW $coord
