#!/bin/bash

set -e

source /etc/profile.d/dt-profile.sh

cron_file="/etc/cron.d/dt-cron"

echo
echo "Adding $cron_file"
echo

grep '^[A-Z]\+' /etc/crontab > $cron_file
echo >> $cron_file

find ./ -name cronfile.dist | while read app_cronfile; do
	(
	full_path=$(dirname $(readlink -f $app_cronfile))
	cd $full_path

	set +e

	msg=$(bash -c "source dt-app-conf.sh" 2>&1)
	ret=$?

	if [ $ret -eq 4 ]; then
		echo "$msg" 1>&2
		exit 1
	elif [ $ret -eq 0 ]; then
		(cat cronfile 2>/dev/null || cat cronfile.dist) | sed "s|CRON_FILE_DIR|${full_path}|g" >> "$cron_file"
	fi
	)
done

echo
echo "This is the $cron_file"
echo
cat "$cron_file"
echo
