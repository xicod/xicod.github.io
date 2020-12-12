#!/bin/bash

if [ -z "$DT_I3_BAR_DRIVES" ]; then
	DT_I3_BAR_DRIVES="/"
fi

# fontawesome drive icon: 

echo '{"version":1,"click_events":true}'
echo '[[]'
echo ',[{"full_text":""}]'
while [ 1 ]; do
	echo -n ',[{"full_text":""},{"":"","full_text":"Avail: '
	df -h $DT_I3_BAR_DRIVES | tail -n+2 | awk '{printf $6": ("$4"/"$2") | "}' | sed 's/ | $//'
	echo '","name":"memory","separator":false,"separator_block_width":15,"markup":"none"}]'
	sleep 30
done
