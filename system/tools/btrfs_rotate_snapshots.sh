#!/bin/bash

set -e
set -u

target_path="$1"
snapshot_base_name="$2"
days_to_keep="$3"

if [ "`stat --format=%T --file-system ${target_path}`" != "btrfs" ]; then
	echo "The path at '${target_path}' is not a btrfs drive." 1>&2
	exit 1
fi

master_subvolume_path=${target_path}/@master

if [ `btrfs subvolume show ${master_subvolume_path} &>/dev/null && echo TRUE || echo FALSE` = "FALSE" ] \
	|| ! [ -d "${target_path}"/snapshots ]; then
	echo "The location at '${target_path}' doesn't look like a supported structure." 1>&2
	exit 1
fi

ts=$(date +%Y%m%d_%H%M%S)
snapshot_base=${target_path}/snapshots/@${snapshot_base_name}_

btrfs_clean_snapshots.sh $((60*60*24*${days_to_keep} - 60)) ${snapshot_base}'*'
echo

if [ -v DT_OUTPUT_USE_COLOR ] && [ "${DT_OUTPUT_USE_COLOR}" = "1" ]; then
	CREATE_SNAPSHOT_OUTPUT_FUNC=printBoldBlue
else
	CREATE_SNAPSHOT_OUTPUT_FUNC=echo
fi
$CREATE_SNAPSHOT_OUTPUT_FUNC "$(btrfs subvolume snapshot -r ${master_subvolume_path} ${snapshot_base}${ts})"

echo
