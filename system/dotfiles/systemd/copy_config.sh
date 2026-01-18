#!/bin/bash

set -e
set -u
#set -x

CURR_DIR=$(dirname `readlink -f $0`)

systemd_etc=/etc/systemd

if ! [ -d ${systemd_etc} ]; then
	echo "Seems systemd is not present on the system"
	exit 0
fi

for t in system journald; do
	conf_dir=${systemd_etc}/${t}.conf.d

	src=${CURR_DIR}/dt-systemd-${t}.conf
	dst=${conf_dir}/dt-systemd-${t}.conf

	mkdir -p ${conf_dir}

	echo "Setting ${dst}"
	cp -a ${CURR_DIR}/dt-systemd-${t}.conf ${dst}
done
