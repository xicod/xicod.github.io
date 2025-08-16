#!/bin/bash

set -e
set -u

function print_header {
	local msg="$1"
	local length=${#msg}
	local title_pattern="=================================================="
	local to_print="${title_pattern:0:$((${length} +2))}"

	echo "/${to_print}\\"
	echo "| ${msg} |"
	echo "\\${to_print}/"
}

which jq &>/dev/null && jq_exists=1 || jq_exists=0
if [ $jq_exists -eq 0 ]; then
	echo "Please install the 'jq' utility before running."
	exit 1
fi

v=0.18.0
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
exclude_params=()
if [ -v DT_RESTIC_EXCLUDE ] && [ ${#DT_RESTIC_EXCLUDE[@]} -gt 0 ]; then
	for i in "${DT_RESTIC_EXCLUDE[@]}"; do
		exclude_params+=("--exclude=${i}")
	done
fi
if [ -v DT_RESTIC_IEXCLUDE ] && [ ${#DT_RESTIC_IEXCLUDE[@]} -gt 0 ]; then
	for i in "${DT_RESTIC_IEXCLUDE[@]}"; do
		exclude_params+=("--iexclude=${i}")
	done
fi

if [ ${#exclude_params[@]} -gt 0 ]; then
	echo
	echo "Using excludes: ${exclude_params[@]}"
	echo
fi

# always read one file at a time, prevents fragmentation
export RESTIC_READ_CONCURRENCY=1

${restic_bin} snapshots &>/dev/null || ${restic_bin} init

print_header "Running backup for ${DT_RESTIC_BACKUP_DIRECTORY[@]}"
echo
backup_global_params="--limit-upload=${DT_RESTIC_UPLOAD_LIMIT_KB} ${quiet}"
backup_specific_params=("--read-concurrency=1" "${exclude_params[@]}")
if [ -t 0 ]; then
	# running interactivelly
	${restic_bin} ${backup_global_params} backup \
		"${backup_specific_params[@]}" \
		"${DT_RESTIC_BACKUP_DIRECTORY[@]}"
else
	snapshot_id=$(${restic_bin} ${backup_global_params} --json --quiet backup \
				"${backup_specific_params[@]}" \
				"${DT_RESTIC_BACKUP_DIRECTORY[@]}" \
			| jq -r '.snapshot_id')

	parent_id=$(${restic_bin} --json snapshots ${snapshot_id} \
				| jq -r '.[0].parent')
	if [ "${parent_id}" = "null" ]; then
		echo "Created snapshot ${snapshot_id:0:8} with no parent"
	else
		echo "Created snapshot ${snapshot_id:0:8} with parent ${parent_id:0:8}"
		echo
		${restic_bin} diff ${parent_id} ${snapshot_id}
	fi
fi


echo
print_header "Running cleanup for ${DT_RESTIC_BACKUP_DIRECTORY[@]}"
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
