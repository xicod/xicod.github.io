#!/bin/bash

direction=$1

current_ws_num=$(i3-msg -t get_workspaces | jq -r '..|objects|select(.focused)|.num')

focused_window_id=$(xdotool getactivewindow)

i3-msg -t get_tree \
	| jq -r '..|objects|select(.type=="workspace" and .num=='${current_ws_num}')|.floating_nodes[].nodes[0].window' \
	| while read window; do \
		export WINDOW_OVERRIDE=$window; \
		if [ "$direction" = "left" ] || [ "$direction" = "right" ]; then \
			export RESIZE_WINDOW_PERCENT_W=50; \
		fi; \
		i3_floating_to_edges.sh $direction; \
	done

xdotool windowfocus --sync $focused_window_id
