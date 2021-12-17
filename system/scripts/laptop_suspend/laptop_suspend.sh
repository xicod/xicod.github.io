#!/bin/bash

set -e

# cron sometimes sets HOME=/
export HOME=$(getent passwd $(whoami) | cut -d':' -f6)

source /etc/profile.d/dt-profile.sh
source dt-app-conf.sh

bat_paths=$(upower -e | grep 'BAT[0-9]\+$')

if [ -z "$bat_paths" ]; then
	exit 0
fi

s_perc=0
s_bats=0

charger_status=""

while read bat_path; do
	out=$(upower -i $bat_path)

	perc=$(echo "$out" | grep '^\s*percentage:' | awk '{print $2}' | sed 's/%$//')
	s_perc=$((s_perc + perc))

	charger_status=$(echo "$out" | grep '^\s*state:' | awk '{print $2}')

	s_bats=$((++s_bats))
done <<<"$bat_paths"

avg_perc=$((${s_perc}/${s_bats}))

if awk "BEGIN {exit !( $avg_perc < $DTCONF_suspend_threshold )}" && [ "$charger_status" = "discharging" ]; then
	echo "Current charge (${avg_perc}) is below the required threshold of ${DTCONF_suspend_threshold}. Suspending." \
		| mail -s "Cron `hostname -s` laptop_suspend" $MAILTO
	loginctl lock-sessions
	sleep 3
	systemctl suspend
fi

