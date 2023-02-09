#!/bin/bash

#set -e

# cron sometimes sets HOME=/
export HOME=$(getent passwd $(whoami) | cut -d':' -f6)

source /etc/profile.d/dt-profile.sh
source dt-app-conf.sh

if [ "$DTCONF_enabled" != "TRUE" ]; then
	exit 0
fi

LOGS_DIR=/root/logs/apt
LOGFILE=${LOGS_DIR}/apt_upgrade-$(date +%Y%m%d%H%M%S).log

! [ -d "$LOGS_DIR" ] && mkdir -p "$LOGS_DIR"

apt-get update >/dev/null

result=$(apt-get dist-upgrade --dry-run | grep Inst)

if [ -n "$result" ]; then
	echo "Packages will be upgraded:"
	echo
	echo "$result"
	echo

	(
	DEBIAN_FRONTEND=noninteractive \
	APT_LISTCHANGES_FRONTEND=none \
	NEEDRESTART_SUSPEND=1 \
	apt-get \
	-o Dpkg::Options::=--force-confold \
	-o Dpkg::Options::=--force-confdef \
	-y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
	dist-upgrade \
	&& apt-get autoremove -y \
	&& apt-get clean
	) &>${LOGFILE}

	if [ $? -ne 0 ]; then
		echo
		echo "Something went wrong!"
		echo
		cat ${LOGFILE}
		exit 1
	else
		echo
		echo "Done"
		echo
	fi
fi

new_confs=$(find /etc -name "*.dpkg-new" -o -name "*.ucf-dist")
if [ -n "$new_confs" ]; then
	echo
	echo "Configuration needs to be considered:"
	echo
	echo "$new_confs" | while read new_conf; do
		old_conf=$(echo $new_conf | sed -e 's/\.dpkg-new$//' -e 's/\.ucf-dist$//')
		echo "vimdiff ${new_conf} ${old_conf}"
	done
	echo
fi

needrestart -r a -l -q

sleep 10

(
eval $(needrestart -p | head -n1 | cut -d'|' -f2 | sed 's/\(=[0-9]\+\)[0-9;]*/\1/g')
do_restart=FALSE
if [ -n "$Kernel" ] && [ $Kernel -gt 0 ]; then
	do_restart=TRUE
	echo
	echo "New kernel needs to be booted"
	echo
fi

if [ -n "$Services" ] && [ $Services -gt 0 ]; then
	do_restart=TRUE
	echo
	echo "Services left to be restarted:"
	needrestart -p | tail -n +2 | python3 -c "import yaml,sys;obj=yaml.load(sys.stdin, Loader=yaml.FullLoader);print(str(obj['Services']))"
	echo
fi

if [ "$do_restart" = "TRUE" ]; then
	echo
	echo "Rebooting"
	echo
	(sleep 30s; reboot) &
fi
)

