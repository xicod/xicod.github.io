#!/bin/bash

set -e

PRINT_FUNC_OK=echo
PRINT_FUNC_ERROR=echo

OPTIND=1
while getopts "c" opt; do
	case "$opt" in
		c)
			PRINT_FUNC_OK=printGreen
			PRINT_FUNC_ERROR=printRed
			;;
	esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

if [ $# -lt 2 ]; then
	$PRINT_FUNC_ERROR "Need exactly two parameters: [-c] MAX_AGE_SECONDS 'PATTERN'"
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
