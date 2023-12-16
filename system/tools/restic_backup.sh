#!/bin/bash

set -e
set -u

v=0.16.0
restic_dl_url="https://github.com/restic/restic/releases/download/v${v}/restic_${v}_linux_amd64.bz2"
restic_dl_file_compressed="restic_${v}_linux_amd64.bz2"
restic_dl_file="restic_${v}_linux_amd64"

# set HOME just in case it wasn't set properly
export HOME=$(getent passwd $(whoami) | cut -d: -f6)

restic_dist_dir=${HOME}/restic_dist
restic_bin=${restic_dist_dir}/restic

mkdir -p $restic_dist_dir

if ! [ -f ${restic_dist_dir}/${restic_dl_file} ]; then
	echo
	echo "Downloading ${restic_dl_url}"
	echo
	(
	cd ${restic_dist_dir}
	wget -q "${restic_dl_url}" -O ${restic_dl_file_compressed}
	bzip2 -d ${restic_dl_file_compressed}
	chmod +x ${restic_dl_file}
	ln -sf ${restic_dl_file} ${restic_bin}
	)
fi

source $1

quiet=""

# always read one file at a time, prevents fragmentation
export RESTIC_READ_CONCURRENCY=1

${restic_bin} snapshots &>/dev/null || ${restic_bin} init

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Running backup for $DT_RESTIC_BACKUP_DIRECTORY"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo

${restic_bin} --limit-upload=${DT_RESTIC_UPLOAD_LIMIT_KB} ${quiet} backup \
	--read-concurrency=1 \
	${DT_RESTIC_BACKUP_DIRECTORY}

echo
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo " Running cleanup for $DT_RESTIC_BACKUP_DIRECTORY"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo

# DT_RESTIC_SNAPSHOTS_REMOVE_OLDER_THAN example: 1y5m7d2h

${restic_bin} --limit-upload=${DT_RESTIC_UPLOAD_LIMIT_KB} ${quiet} forget \
	--keep-within ${DT_RESTIC_SNAPSHOTS_REMOVE_OLDER_THAN} \
	--prune --max-unused=1G

#(source my.profile && restic prune --max-unused=0%)

# some.profile example:
#export B2_ACCOUNT_ID=
#export B2_ACCOUNT_KEY=
#export RESTIC_REPOSITORY=b2:
#export RESTIC_PASSWORD=
#export DT_RESTIC_BACKUP_DIRECTORY=
#export DT_RESTIC_SNAPSHOTS_REMOVE_OLDER_THAN=2m
#export DT_RESTIC_UPLOAD_LIMIT_KB=0
