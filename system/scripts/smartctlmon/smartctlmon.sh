#!/bin/bash

set -e

# cron sometimes sets HOME=/
export HOME=$(getent passwd $(whoami) | cut -d':' -f6)

source /etc/profile.d/dt-profile.sh
source dt-app-conf.sh


CURR_DIR=$(dirname $(readlink -f $0))

${CURR_DIR}/smartctlmon.py
