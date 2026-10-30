#!/bin/bash

function DTT_check_ownership {
	local p="$1"
	local own="$2"

	local path_user=`stat --format=%U "${p}"`
	local path_group=`stat --format=%G "${p}"`
	local path_ownership="${path_user}:${path_group}"

	if [ "${path_ownership}" != "${own}" ]; then
		echo "The ownership is not what is expected for ${p}: ${path_ownership}, need ${own}" 1>&2
		return 1
	else
		return 0
	fi
}

function DTT_check_permissions {
	local p="$1"
	local perm="$2"

	local path_permissions=`stat --format=%a "${p}"`

	if [ "${path_permissions}" != "${perm}" ]; then
		echo "The permissions are not what is expected for ${p}: ${path_permissions}, need ${perm}" 1>&2
		return 1
	else
		return 0
	fi
}

function DTT_check_fs {
	local p="$1"
	local fs="$2"

	local path_fs=`stat --format=%T --file-system "${p}"`

	if [ "${path_fs}" != "${fs}" ]; then
		echo "The filesystem is not what is expected for ${p}: ${path_fs}, need ${fs}" 1>&2
		return 1
	else
		return 0
	fi
}
