#!/bin/bash

function trap_logfile_cleanup {
	rm ${LOG_FILE}
}

LOG_FILE=$(mktemp --tmpdir log_bufferer.XXXXXXXXXX)

if ! [[ "${LOG_FILE}" =~ ^/tmp/log_bufferer\.[a-zA-Z0-9]+$ ]]; then
	echo "Log file '${LOG_FILE}' is not valid." 1>&2
	exit 1
fi

trap "trap_logfile_cleanup" EXIT

cat > ${LOG_FILE}

cat ${LOG_FILE}
