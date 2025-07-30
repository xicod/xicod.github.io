#!/bin/bash

set -e

source /etc/profile.d/dt-profile.sh
source dt-app-conf.sh

active_root_sessions=$(netstat -tnpa | grep -c 'ESTABLISHED.*sshd:\s*root@') || :

[ $active_root_sessions -ge 1 ] && exit 0

awk -v THRESHOLD=$DTCONF_report_threshold -v LOAD15=`cat /proc/loadavg | awk '{print $3}'` -v HOSTNAME=`hostname -s` \
	'BEGIN{ if (LOAD15 > THRESHOLD){print "Load on " HOSTNAME " is high (" LOAD15 " > " THRESHOLD ")";} }'
