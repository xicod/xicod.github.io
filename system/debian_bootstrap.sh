#!/bin/bash

set -e
set -x

apt-get update
apt-get install -y ufw
ufw --force reset
ufw --force enable

# this pre-check prevents ssmpt from failing to configure later
getent hosts $(hostname -s)

# optional ============================
apt-get install -y openssh-server

sshd_config_dir=/etc/ssh/sshd_config.d
if [ -z "$(find ${sshd_config_dir} -maxdepth 0 -empty)" ]; then
	{ set +x; } 2>/dev/null
	echo "${sshd_config_dir} is not empty, please handle before running"
	set -x
	exit 1
fi
# =====================================

DEBIAN_FRONTEND=noninteractive \
APT_LISTCHANGES_FRONTEND=none \
NEEDRESTART_SUSPEND=1 \
apt-get dist-upgrade -y

apt-get install -y \
	cron sudo git curl \
	tig vim tmux \
	needrestart build-essential \
	jq python3-yaml \
	docker.io docker-compose \
	htop iotop nethogs \
	zip unzip \
	mailutils ssmtp \
	wireguard rsync duplicity gpg \
	net-tools iputils-ping dnsutils

(
mkdir -p ~/git
cd ~/git
rm xicod.github.io -rf
git clone https://github.com/xicod/xicod.github.io.git
cd xicod.github.io/system
make
)

# optional ============================
mkdir -p ~/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDO8yncs2yS6Rjncli5/yLTzZ/rdJ4v3GDLfnshTMH6MbLaPeCNPMB3mAe4y6wCeMPhYYECazqQhG48Qgyt+vIdwxuPJmixhvkxnN3ossW7CyL96KG7qi/yZySpGjui1w1pOmjnxZeFneqnjcav9ixYI5JQCyqh9gQoWC34PoFsobgAgIeAU0EV1n24SMaQBgLdWjmnl8JZUyk7vU+hjU4RzZdFcfZ3KGpK+TrBOrGdWYiuU/xY3gNEUHrOtz1cDwGpUgoaiB/AUwE3m/iShnezY5aXDYqhb0rvdgK+K/wxiwZbYYTaYGgIckOv6pvD39nh0WsGq+BEpsTWAwktWazC80sbTAPUL5G1X6OgoyN0C1bk0SjtsAsx+QJXvz1F0/81bF9Dv1m5ayRR6JTbWkCWV7CUy5yUI/MN/fiqY3TE/yp8+EAs4OaBi6Oqye2M4KnYvQJxNg8YK6D8aFie6lXF64sigNcA5oYqwKMHzczsDRh0roHeWrV09mxha1xeumGV0LLoa55eL9SVZoHfHyvnQL9E0SZhHtw8rVqAiAP/ka2BNDWPag7eFTMcHbE4j78Qt1LhJE9peCtcc1EVzDi6XpXiwGjZ9XXqzJD8wo6hMUPk3S0sD9/GfqJb6B1ZXkMAfO4b8jIRnJS8xgvSeUPqjdXzf0B19iSi2seIOpxZmw== root@main' > ~/.ssh/authorized_keys

systemctl restart sshd
ufw allow ssh
# =====================================

gpg --keyserver keys.openpgp.org --recv-keys D42B7B2502A056EFB5EC92CBD8B0A486CA9CA2F5
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key D42B7B2502A056EFB5EC92CBD8B0A486CA9CA2F5 trust

(
systemctl stop unattended-upgrades.service
systemctl disable unattended-upgrades.service
apt-get remove --purge -y -qq unattended-upgrades
) || :

timedatectl set-timezone America/Vancouver

set +x
echo
echo ========================
echo "Done. Consider a reboot."
echo ========================
echo
