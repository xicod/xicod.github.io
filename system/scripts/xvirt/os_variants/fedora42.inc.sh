#!/bin/bash

function xvirt_os_variant_get {
	curl -O https://fedoraproject.org/fedora.gpg

	wget https://download.fedoraproject.org/pub/fedora/linux/releases/44/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-44-1.7.x86_64.qcow2 \
		-O Fedora-Cloud-Base-Generic-44-1.7.x86_64.qcow2
	wget https://dl.fedoraproject.org/pub/fedora/linux/releases/44/Cloud/x86_64/images/Fedora-Cloud-44-1.7-x86_64-CHECKSUM \
		-O Fedora-Cloud-44-1.7-x86_64-CHECKSUM

	gpgv --keyring ./fedora.gpg --output - \
		Fedora-Cloud-44-1.7-x86_64-CHECKSUM \
		| sha256sum -c --ignore-missing

	mv Fedora-Cloud-Base-Generic-44-1.7.x86_64.qcow2 ${disk_image_file}
}
