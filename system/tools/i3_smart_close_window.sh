#!/bin/bash

focused_window_id=`xdotool getactivewindow 2>/dev/null`

if [ -z "${focused_window_id}" ]; then
	exit 0
fi

isfloating=`i3-msg -t get_tree | jq -r '..|objects|select(.type=="workspace")|.floating_nodes[].nodes[0].window' | grep -q "^${focused_window_id}$" && echo TRUE || echo FALSE`

#echo "isfloating=$isfloating"

i3-msg kill &>/dev/null || exit 1

if [ x${isfloating} = xTRUE ]; then
	# it might take seconds for an active window to actually close
	for ((i=0 ; i<100 ; i++)); do
		if [ x`xdotool getactivewindow 2>/dev/null` != x${focused_window_id} ]; then
			break
		fi
		sleep 0.1
	done

	# Might fail if there's no more floating windows left. We don't care.
	i3-msg 'focus floating' &>/dev/null
fi

exit 0
