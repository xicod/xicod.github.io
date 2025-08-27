#!/bin/bash

set -e

PRINT_FUNC_OK=echo
PRINT_FUNC_ERROR=echo

if [ -v DT_OUTPUT_USE_COLOR ] && [ "${DT_OUTPUT_USE_COLOR}" = "1" ]; then
	PRINT_FUNC_OK=printGreen
	PRINT_FUNC_ERROR=printRed
fi

if [ $# -lt 2 ]; then
	$PRINT_FUNC_ERROR "Need exactly two parameters: MAX_AGE_SECONDS 'PATTERN'"
	exit 1
fi

age=$1
pat=$2

now=$(date +%s)

for f in $(shopt -s nullglob; echo $pat); do
#	echo "Checking $f .."
	t=$(set -o pipefail; set -e; d=$(btrfs subvolume show $f | grep '^\s*Creation time:' | sed 's/^\s*Creation time:\s*//'); date -d "$d" +%s)
	if [ $(($now - $t)) -gt $age ]; then
		$PRINT_FUNC_ERROR "$(btrfs subvolume delete $f)"
	else
		$PRINT_FUNC_OK "Not removing $f"
	fi
done
