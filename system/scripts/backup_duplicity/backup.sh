#!/bin/bash

set -e

# cron sometimes sets HOME=/
export HOME=$(getent passwd $(whoami) | cut -d':' -f6)

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

PASSPHRASE=${DTCONF_backup_passphrase} \
duplicity incr --full-if-older-than ${DTCONF_full_backup_rotation} \
--verbosity e --no-print-statistics \
${INCLUDE_EXCLUDE_STR} \
/ \
file://${DTCONF_backup_dest}

PASSPHRASE=${DTCONF_backup_passphrase} \
duplicity remove-all-but-n-full 1 --force --verbosity e \
file://${DTCONF_backup_dest}

chown -R ${DTCONF_backup_owner} ${DTCONF_backup_dest}