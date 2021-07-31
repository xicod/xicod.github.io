#!/bin/bash

set -e

source vars.sh

mkdir -p ${TOOLS_DIR}
cp -a tools/* ${TOOLS_DIR}/
