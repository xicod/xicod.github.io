#!/bin/bash

set -e

source /etc/profile.d/dt-profile.sh
source dt-app-conf.sh

INCLUDE_EXCLUDE_STR=""

while read line; do
	if [[ "$line" =~ ^- ]]; then
		INCLUDE_EXCLUDE_STR="${INCLUDE_EXCLUDE_STR} --exclude"
		line=$(echo $line | sed 's/^-//')
	else
		INCLUDE_EXCLUDE_STR="${INCLUDE_EXCLUDE_STR} --include"
	fi
	
	INCLUDE_EXCLUDE_STR="${INCLUDE_EXCLUDE_STR} $line"
done < <(echo "$DTCONF_include_exclude_list" | tr ',' '\n')

################################################################################

curr_dir=$(dirname `readlink -f $0`)

(
set +e
which duplicity > /dev/null
if [ $? -ne 0 ]; then
	echo "duplicity was not found"
	exit 1
fi
)

bash -c "${DTCONF_pre_backup_bash_func}"

if [ -z "${DTCONF_backup_passphrase}" ]; then
	gpg_key_param="--encrypt-key=$DTCONF_backup_gpg_key_id"
	echo "Using pgp key ${DTCONF_backup_gpg_key_id} to encrypt the backup"
else
	gpg_key_param=""
fi

if [ -f /run/qubes/this-is-*vm ]; then
	os_var=qubes
else
	os_var=regular
fi

if [ "${os_var}" = "qubes" ]; then
	export sysbackup_sync_marker_file=/root/sysbackup_sync_marker
	if ! [ -f ${sysbackup_sync_marker_file} ]; then
		touch ${sysbackup_sync_marker_file}
		sleep 2
	fi
fi

PASSPHRASE=${DTCONF_backup_passphrase} \
duplicity incr --full-if-older-than ${DTCONF_full_backup_rotation} \
--verbosity e --no-print-statistics \
${gpg_key_param} \
${INCLUDE_EXCLUDE_STR} \
/ \
file://${DTCONF_backup_dest}

PASSPHRASE=${DTCONF_backup_passphrase} \
duplicity remove-all-but-n-full 1 --force --verbosity e \
${gpg_key_param} \
file://${DTCONF_backup_dest}

if [ "${os_var}" = "qubes" ]; then
	(
	# dest vm needs to be a config
	find ${DTCONF_backup_dest} -type f -newer ${sysbackup_sync_marker_file} -print0 \
		| xargs -0 -r qvm-copy-to-vm --without-progress backups
	) 2> >(grep -v '^In order to avoid typing target qube name twice' >&2)

	touch ${sysbackup_sync_marker_file}
fi
