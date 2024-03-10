#!/bin/bash

set -e

source /etc/profile.d/dt-profile.sh
source dt-app-conf.sh


CURR_DIR=$(dirname $(readlink -f $0))

${CURR_DIR}/smartctlmon.py
