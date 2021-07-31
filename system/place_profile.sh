#!/bin/bash

source vars.sh

CURR_DIR=$(readlink -f $(dirname $0))

cat dt-profile.sh \
	| sed "s|__TOOLS_DIR__|${TOOLS_DIR}|g" \
	| sed "s|__PARENT_GIT_REPO__|${CURR_DIR}|g" \
	> /etc/profile.d/dt-profile.sh
