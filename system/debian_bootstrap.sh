#!/bin/bash

set -e
set -x

apt-get update
apt-get install -y ufw
ufw --force reset
ufw --force enable

# optional ============================
apt-get install -y openssh-server

sshd_config_dir=/etc/ssh/sshd_config.d
if [ -z "$(find ${sshd_config_dir} -maxdepth 0 -empty)" ]; then
	echo "${sshd_config_dir} is not empty, please handle before running"
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
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCgZvu36qurmPnxD27JBKjVyNNIbD5QBFNniiGlriLQInVNPC9ku/dH9UvEt6xtWUoHpqgwnDAlzCtjABvdiraTiZv9hMnDwX2ZR6uf1ZiTJgjhRNAs133ptGYrqVGXnTfjrjW7Tfeos7nM3nWYrckHEYsKFg4cFWesHMJjN16gGwDmcq5fZaCPSnMnUygpZ26rM5EvKnUrxoi5E740Cr0lFQWdMDEvF2nUtogr7lkVVjoQ5HSOIc+odckm8+KWBdfZRgGlfY5hnJ5ZNeJJ3t4xICfC5D7lXBVTp+uOmyz8VYvLXNww3uOJGka0DASK/5j1wggib4kMgl8esKwfaAw4YpRR3z0V+bCcKuD+fV8h3mTJ8ILxXekeJ1ov/L4tuefHp1kilMFKi4wzUAn3NiPfzUemRic7emdAGqlwZC6ZUIvZ37at73wW3oLkEf7tIyKOhUfKXzHDdX+ux7Ns1KCodhzSspAh1/BLU0CRhbq62piPuM35JtBIKNgyH68NxQlLYSKJMF4daAXLuLvueRII7jBx92kcxyC9pOcGz9tduTZL9ebsAnTvnGMBRKcFJWT7HcMSDhHBoHMndL9IGS/n9O2gh9WTI/7JvYVLqnpFJAGgq0dqc7rDJXU2ZCI297dMgEVRZnAA5vXaPdzSctkX3lpDS4BEHWs2d6nFIv35uQ== root@main' > ~/.ssh/authorized_keys

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
