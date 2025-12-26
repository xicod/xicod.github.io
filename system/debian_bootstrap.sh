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
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCVxaRrUXiy4rOqtzCeoTajlGd0y1vK3y5mLYmNz+8+3F4Cv0iaEG+gd40qufN/LdQXD7++0L4HRLg1sukHwVDvt56LCHUdgMGl3mHXljAE+AoxK6f36yjR4E9N1TFQC9fW1ekFgaOmf4Bio/aMBKdpcbtsN7aZrmc3uNCcIGUBcTQz25lkbWn7gp4UGLHmMbEiZIdBZwjQGsiTfbI2mBnHHS7mKUjWcIhhVYEwFx7gH4Fo0kvn64hInE/FO4kGbXqO/P7PkbLyNDO7Njf96VbX5jQQAyEIrZaH8VRLPwwmfp6qdqqZDZtlsKahh+Lw2H2hVoGa23cYgGhFuTEjNiW10+y5vuYqyMxfNmCXyF8wUHbi3CxIioJAVOnOzdcguBhOUWN18++5ztOlnRt5KwkXeNFDTLSqX/b6VnaDdLzX1h4LI+FcAMKsBwaG6cGfE/n5b8aCMtraXhauXJS8w3C6kVCS/sj7CTpjazNuMPiKL2v96vLGm8cHvT8b+72Um2Wkh6eGn6yLIO42/z4gqkP3TosPuYWk5yTtam2n7/TvphwCYb0hybBta7KMbE0NTb3LlYtWiulb3SYd/QSKKhbpGdORNO8wSPxfgIqyJE5/dCPfq8TLpYj9y94QDs3zIJ4cAJlUSJYJrOTNknqJmgR/Nl9NWUdxD8lIp4oxP0h7Tw== root@main' > ~/.ssh/authorized_keys

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
