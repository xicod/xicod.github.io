#!/bin/bash

conf=~/snip_manager.snips
if [ -f "$conf" ]; then
	IFS=$'\r\n' command eval 'cmds=("" $(cat '$conf'))'
else
	cmds=("No $conf found")
fi

cmd=$(zenity --list --width=1000 --height=300 --column "cmd" -- "${cmds[@]}" 2>/dev/null)
if [ -n "$cmd" ]; then
	echo -n "$cmd" | xsel -ib
fi

