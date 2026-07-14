#!/bin/bash

set -e
set -u

source vm.profile

set -x

virsh start ${DT_VM_HOSTNAME}
