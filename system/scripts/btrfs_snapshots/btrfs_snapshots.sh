#!/bin/bash

set -e
set -u

source /etc/profile.d/dt-profile.sh
source dt-app-conf.sh

if [ $DTCONF_silent != "FALSE" ]; then
	exec 1>>/dev/null
fi

IFS=, read -ra targets <<< "$DTCONF_targets"
for target in "${targets[@]}"; do
	IFS=: read -r \
		days_to_keep \
		target_path \
	<<< "$target"

	btrfs_rotate_snapshots.sh ${target_path} daily ${days_to_keep}
done
