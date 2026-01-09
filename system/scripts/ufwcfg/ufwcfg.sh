#!/bin/bash

set -e
set -u

source /etc/profile.d/dt-profile.sh
source dt-app-conf.sh

set -x

function removeAllUfwRules {
	while : ; do
		ufw status numbered | grep '^\[' | tac | cut -d'[' -f2 | cut -d']' -f1 | xargs -I% ufw --force delete %
		[ $? -eq 0 ] && break
	done
}

function getPortProtoUfwParam {
	local port_decl="$1"
	local port=$(echo "${port_decl}" | cut -d/ -f1)
	local proto=$(echo "${port_decl}" | cut -d/ -f2)

	local ret="port ${port}"

	if [ "${port}" != "${proto}" ]; then
		ret="${ret} proto ${proto}"
	fi
	
	echo "${ret}"
}

function setupLocalNet {
	net_device=$(ip -json route show | \
		python3 -c \
			$'import sys, json, re\nfor d in json.load(sys.stdin): print(d["dev"]) if d["dst"] == "default" and not re.match(r"^(wg|tun)", d["dev"]) else None')

	local_net=$(ip -f inet -json addr show $net_device | \
		python3 -c \
			$'import sys, json\nprint(json.load(sys.stdin)[0]["addr_info"][0]["local"])')

	IFS=',' read -ra PORTS <<< "$DTCONF_ports_open_local"
	for p in "${PORTS[@]}"; do
		port_proto_param=`getPortProtoUfwParam ${p}`

#		ufw allow from $local_net to any port $p
		ufw allow in on $net_device to any ${port_proto_param}
	done
}

function setupCustom {
	IFS=',' read -ra FWDECL <<< "$DTCONF_ports_open_custom"
	for fwdecl in "${FWDECL[@]}"; do
		interface=$(echo "$fwdecl" | cut -d: -f1)
		port=$(echo "$fwdecl" | cut -d: -f2)

		port_proto_param=`getPortProtoUfwParam ${port}`

		ufw allow in on $interface to any ${port_proto_param}
	done
}

function setupFw {
	ufw default allow outgoing
	ufw default deny incoming

	removeAllUfwRules

	setupLocalNet
	setupCustom

	ufw --force enable
}

setupFw
