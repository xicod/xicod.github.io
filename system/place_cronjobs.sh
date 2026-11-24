#!/bin/bash

set -e

if [ -f /run/qubes/this-is-*vm ]; then
	os_var=qubes
else
	os_var=regular
fi

source /etc/profile.d/dt-profile.sh

function remove_user_from_entry_if_needed {
	if [ "${os_var}" = "qubes" ]; then
		sed -E '/^\s*(#|$)/! s/^((\S+\s+){5})\S+\s+/\1/'
	else
		cat
	fi
}

if [ "${os_var}" = "qubes" ]; then
	cron_src=${HOME}/.cron.d
	mkdir -p ${cron_src}

	cron_env_file=${cron_src}/01_cron_env
	if ! [ -f ${cron_env_file} ]; then
		grep '^[A-Z]\+' /etc/crontab > ${cron_env_file}
		echo >> ${cron_env_file}
	fi

	cron_cust_file=${cron_src}/05_custom
	if ! [ -f ${cron_cust_file} ]; then
		echo "# This file is for custom user entries:" > ${cron_cust_file}
	fi

	cron_file=${cron_src}/09_tools
	rm -f ${cron_file}
else
	cron_file="/etc/cron.d/dt-cron"

	touch ${cron_file}
	chown root:root ${cron_file}
	chmod 644 ${cron_file}

	grep '^[A-Z]\+' /etc/crontab > ${cron_file}
	echo >> ${cron_file}
fi

echo "# These entries are generated from the tools repo:" >> ${cron_file}

find ./ -name cronfile.dist | while read app_cronfile; do
	(
	full_path=$(dirname $(readlink -f ${app_cronfile}))
	cd ${full_path}

	set +e

	msg=$(bash -c "source dt-app-conf.sh" 2>&1)
	ret=$?

	if [ ${ret} -eq 4 ]; then
		echo "${msg}" 1>&2
		exit 1
	elif [ ${ret} -eq 0 ]; then
		(cat cronfile 2>/dev/null || cat cronfile.dist) \
			| sed "s|CRON_FILE_DIR|${full_path}|g" \
			| remove_user_from_entry_if_needed \
			>> "${cron_file}"
	fi
	)
done

if [ "${os_var}" = "qubes" ]; then
	cat ${cron_src}/* | crontab -
fi

echo
echo "This is the cronfile:"
echo
if [ "${os_var}" = "qubes" ]; then
	crontab -l
else
	cat "${cron_file}"
fi
echo
