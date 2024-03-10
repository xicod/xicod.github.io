#!/bin/bash

set -e

source /etc/profile.d/dt-profile.sh
source dt-app-conf.sh

#env | grep DT

IFS=, read -ra targets <<< "$DTCONF_targets"
for target in "${targets[@]}"; do
	IFS=: read -r \
		percent_used_threshold \
		mount_point \
	<<< "$target"

	#set -x
	percent_used=$(df --output=pcent ${mount_point} | tail -n+2 | xargs | sed 's/%$//')
	if [ ${percent_used} -gt ${percent_used_threshold} ]; then
		echo "Filesystem mounted at (${mount_point}) is at (${percent_used}%) usage!"
	fi
	#set +x
done
