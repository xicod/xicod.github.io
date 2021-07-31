#!/bin/bash

source vars.sh

cat dt-profile.sh \
	| sed "s|__TOOLS_DIR__|${TOOLS_DIR}|g" \
	> /etc/profile.d/dt-profile.sh
