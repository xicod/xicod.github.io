#!/bin/bash

CURR_DIR=$(dirname $(readlink -f $0))

while read line; do
	declare -x "$line"
done < <(dt-app-conf.py $CURR_DIR)

if [ "$DTCONF_STATUS" = "SUCCESS" ]; then
	exit_code=0
else
	echo "Failed. msg: $DTCONF_ERROR_MSG" 1>&2
	exit_code=1

	case "$DTCONF_STATUS" in
		"FAILURE_NO_MAIN_CONFIG")
			exit_code=1
			;;
		"FAILURE_NOT_AN_APP")
			exit_code=2
			;;
		"FAILURE_MISSING_CONFIG")
			exit_code=3
			;;
		"FAILURE_APP_MISCONFIGURED")
			exit_code=4
			;;
	esac
fi

return $exit_code
