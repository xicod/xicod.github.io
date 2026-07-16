#!/bin/bash

set -e
set -u
#set -x

source vm.profile

state=$(virsh domstate ${DT_VM_HOSTNAME} 2>/dev/null || echo "NONEXIST")
state=`echo "${state}" | xargs`

if [ "${state}" = "NONEXIST" ]; then
	echo "Vm '${DT_VM_HOSTNAME}' doesn't exist."
else
	if [ "${state}" = "running" ]; then
		virsh destroy ${DT_VM_HOSTNAME}
	fi

	virsh undefine ${DT_VM_HOSTNAME} --remove-all-storage
fi
