#!/bin/bash

if [ -z "$DT_I3_BAR_DRIVES" ]; then
	DT_I3_BAR_DRIVES="/"
fi

# fontawesome drive icon: 

echo '{"version":1,"click_events":true}'
echo '[[]'
echo ',[{"full_text":""}]'
while [ 1 ]; do
	echo -n ',[{"full_text":""},{"":"","full_text":"'

	echo -n 'Avail: '
	df -h $DT_I3_BAR_DRIVES | tail -n+2 | awk '{printf $6": ("$4"/"$2") | "}' | sed 's/ | $//'

	bat_paths=$(upower -e | grep 'BAT[0-9]\+$')
	if [ -n "$bat_paths" ]; then
		echo -n ' | Battery: '
		for bat_path in $bat_paths; do
			perc=$(upower -i $bat_path | grep '^\s*percentage:' | awk '{print $2}'); \
			bat=${bat_path##*BAT}; \
			echo "$bat: ($perc)"; \
		done | tr '\n' ',' | sed -e 's/,$//' -e 's/,/, /g'
	fi

	echo '","name":"memory","separator":false,"separator_block_width":15,"markup":"none"}]'
	sleep 30
done
