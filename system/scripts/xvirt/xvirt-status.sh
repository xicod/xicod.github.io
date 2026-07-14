#!/bin/bash

set -e
set -u

source vm.profile

set -x

virsh domstate ${DT_VM_HOSTNAME}
