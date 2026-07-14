#!/bin/bash

set -e
set -u
set -x

source vm.profile

virsh destroy ${DT_VM_HOSTNAME}
virsh undefine ${DT_VM_HOSTNAME} --remove-all-storage
