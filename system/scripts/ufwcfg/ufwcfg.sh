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

function setupLocalNet {
	net_device=$(ip -json route show | \
		python3 -c \
			$'import sys, json, re\nfor d in json.load(sys.stdin): print(d["dev"]) if d["dst"] == "default" and not re.match(r"^(wg|tun)", d["dev"]) else None')

	local_net=$(ip -f inet -json addr show $net_device | \
		python3 -c \
			$'import sys, json\nprint(json.load(sys.stdin)[0]["addr_info"][0]["local"])')

	IFS=',' read -ra PORTS <<< "$DTCONF_local_ports_open"
	for p in "${PORTS[@]}"; do
#		ufw allow from $local_net to any port $p
		ufw allow in on $net_device to any port $p
	done
}

function setupWg {
	IFS=',' read -ra PORTS <<< "$DTCONF_int_wg_ports_open"
	for p in "${PORTS[@]}"; do
		ufw allow in on $DTCONF_int_wg_name to any port $p
	done
}

function setupFw {
	ufw default allow outgoing
	ufw default deny incoming

	removeAllUfwRules

	# allow out (completely) and in (specific ports) on local network
	setupLocalNet

	# to allow my vpn network access to specific ports
	if [ -n "$DTCONF_int_wg_name" ]; then
		setupWg
	fi

	ufw --force enable
}

setupFw
