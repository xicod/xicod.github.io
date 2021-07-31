#!/bin/bash

root_home=$(getent passwd "root" | cut -d':' -f6)

if ! [ -f ${root_home}/dt_config.yaml ]; then
	echo
	echo "Placing default dt_config.yaml"
	echo

	cp ./dt_config.yaml-default ${root_home}/dt_config.yaml
fi
