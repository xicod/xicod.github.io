#!/bin/bash

set -e
set -u

if [ $# -eq 1 ]; then
	vm=$1
else
	source vm.profile
	vm=${DT_VM_HOSTNAME}
fi

ip=`dig @192.168.122.1 ${vm} +short`
if [ "${ip}" = "" ]; then
	echo "Couldn't resolve '${vm}'"
	exit 1
fi

#ssh-keygen -f '/root/.ssh/known_hosts' -R "${ip}"

set -x

ssh \
	-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null \
	${ip}
