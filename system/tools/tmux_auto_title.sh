#!/bin/bash

automatic_rename=$1
curr_dir="$2"
curr_title="$3"
curr_pane_pid=$4

if [ "$automatic_rename" = "no" ]; then
	echo -n "$curr_title"
	exit 0
fi

home_dir=$(getent passwd `whoami` | cut -d':' -f6)

current_child=""
p=$(set -o pipefail; pgrep -P $curr_pane_pid | tail -n1)
if [ $? -eq 0 ]; then
	current_child=$(ps -p $p -o comm=)
fi

if [ "$current_child" = "ssh" ]; then
	echo -n "ssh "
	proc_args=$(ps -p $p -o args=)
	read -ra args_arr <<< "$proc_args"
	for a in "${args_arr[@]}"; do
		if [ "$a" = "ssh" ]; then
			continue
		elif [[ "$a" =~ ^[a-zA-Z]+ ]] \
			|| [[ "$a" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
			echo -n "$a"
			break
		fi
	done
else
	echo -n $curr_dir | sed -E \
		-e "s|^${home_dir}|~|" \
		-e "s|([^/]{1})[^/]*/|\1/|g" \
		-e "s|/([^/]{1,10})([^/]*)$|/\1@\2@|" \
		-e "s|@[^@]{3,}@|..|g" \
		-e "s|@([^@]*)@$|\1|"

	if [ -n "$current_child" ]; then
		echo -n "|${current_child}"
	fi
fi
