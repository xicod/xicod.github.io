#!/bin/bash

set -e
set -u

source /etc/profile.d/dt-profile.sh
source dt-app-conf.sh

if [ $DTCONF_silent != "FALSE" ]; then
	exec 1>>/dev/null
fi

ts=$(date +%Y%m%d_%H%M%S)

IFS=, read -ra targets <<< "$DTCONF_targets"
for target in "${targets[@]}"; do
	IFS=: read -r \
		days_to_keep \
		target_path \
	<<< "$target"

	snapshot_base=${target_path}/snapshots/@daily_

	btrfs_clean_snapshots.sh $((60*60*24*${days_to_keep} - 60)) ${snapshot_base}'*'
	btrfs subvolume snapshot -r ${target_path}/@master ${snapshot_base}${ts}

	echo
done
