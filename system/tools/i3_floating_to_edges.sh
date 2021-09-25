#!/bin/bash

WINDOW_TITLE_HEIGHT=22
WINDOW_BORDER_WIDTH=3

eval $(i3-msg -t get_workspaces | jq -r 'map(select(.focused))[0].rect | to_entries | .[] | .key + "=" + (.value | @sh)')
eval $(xdotool getactivewindow getwindowgeometry --shell)

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
