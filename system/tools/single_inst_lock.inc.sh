#!/bin/bash

filename_sum=$(readlink -f "$0" | md5sum | awk '{print $1}')
LOCKDIR="/tmp/lock_${filename_sum}"

function locking_cleanup {
	rmdir $LOCKDIR
	_single_inst_cleanup_func
}

if mkdir $LOCKDIR 2>/dev/null; then
	# Ensure that if we "grabbed a lock", we release it
	# Works for SIGTERM and SIGINT(Ctrl-C)
	trap "locking_cleanup" EXIT

#	echo "Acquired lock $LOCKDIR , running"

else
#	echo "Could not create lock directory '$LOCKDIR'"
	exit 0
fi
