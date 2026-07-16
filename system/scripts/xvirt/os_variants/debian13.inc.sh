#!/bin/bash

function xvirt_os_variant_get {
	wget https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2 \
		-O debian-13-genericcloud-amd64.qcow2
	wget https://cloud.debian.org/images/cloud/trixie/latest/SHA512SUMS \
		-O SHA512SUMS
	sha512sum -c --ignore-missing SHA512SUMS
	mv debian-13-genericcloud-amd64.qcow2 ${disk_image_file}
	#cp debian-13-genericcloud-amd64.qcow2 ${disk_image_file}
}
