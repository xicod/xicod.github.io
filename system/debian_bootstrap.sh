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

mkdir -p ~/git && cd ~/git
rm xicod.github.io -rf
git clone https://github.com/xicod/xicod.github.io.git
cd xicod.github.io/system
make

# optional ============================
mkdir -p ~/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCnsE2OId858o+LHYkrI7bLQLghd8kwdA8pLqrt7W4JXSeMGPgOD283yeUReS9HvFMHTAz95kLnj3HBYoBWqzN00Bn4J2hequxeSuXKq1FUfRjURGx3wzEsRnCOM948YNRp1/DxGoTQ6tscvflSPQKT8C1tHSPbv/pRHHWUVoPQ0jZpUbVwgjS77efAqS29E4pF2yNjR2mehPaIvStBt8eW/tc8wzFmmGT0tUBt3h1uyAwKIqwfvQ+ZEDOE9fPw0tnVRutGpcZ9M8u/29x7kbz4ACIGyDENrxIVujmmPteWviFOmuTdjq5vz2Ncs61VVFoZChmRzT8Fe4e6Wu6hXg+Ex7hUNKbcMIcv2Z8fobP8tL+177XGhzw/FI9Y70d6OfCL2DNT426MmKCjBSqdBm8rqw6lhWIYMxIOwvhmd23vu+ZYfF8o/gV0VnzRnOmtMCZxn6XUgks8TsIRGIVA6kefovbCL2c8uJhT7MfqsSESg3QAskm9UfMVQZG2yd9nmPYbS3jOuKVJ+yCxKkxLqqfBDWEvUnrqEyRREmifEhJUALgtXciE6I/lNRD8zcU2/NwpO/hkX64WS/Di3iQ9TR08RHcBpSDkSw4eERR8fZPDDSCiVkkK/wJKO4e4zE1+4Dm8Dw2Cmlh1Z9NYy2WO5FvM3yBkCJ+/uHtVE6l7GMik3Q== root@main' > ~/.ssh/authorized_keys

systemctl restart sshd
ufw allow ssh
# =====================================

gpg --keyserver keys.openpgp.org --recv-keys D42B7B2502A056EFB5EC92CBD8B0A486CA9CA2F5
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key D42B7B2502A056EFB5EC92CBD8B0A486CA9CA2F5 trust

timedatectl set-timezone America/Vancouver

set +x
echo
echo ========================
echo "Done. Consider a reboot."
echo ========================
echo
