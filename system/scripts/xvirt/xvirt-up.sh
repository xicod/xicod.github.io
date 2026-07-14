#!/bin/bash

set -e
set -u

CURR_DIR=$(readlink -f $(dirname $0))

set -x

source vm.profile

set +x

disk_image_file=os.qcow2

function os_debian13_get {
	wget https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2 \
		-O debian-13-genericcloud-amd64.qcow2
	wget https://cloud.debian.org/images/cloud/trixie/latest/SHA512SUMS \
		-O SHA512SUMS
	sha512sum -c --ignore-missing SHA512SUMS
	mv debian-13-genericcloud-amd64.qcow2 ${disk_image_file}
	#cp debian-13-genericcloud-amd64.qcow2 ${disk_image_file}
}

# func_to_get_img
declare -A OS_VARIANTS=(
	["debian13"]="os_debian13_get"
)

if ! [[ -v OS_VARIANTS[${DT_VM_OS_VARIANT}] ]]; then
	echo "Couldn't get config for os variant '${DT_VM_OS_VARIANT}'"
	exit 1
fi

os_variant_conf=${OS_VARIANTS[${DT_VM_OS_VARIANT}]}
set -x

os_variant_get_func=`echo "${os_variant_conf}" | cut -d: -f1`

${os_variant_get_func}

qemu-img resize ${disk_image_file} ${DT_VM_DISK_SIZE}

set +x
install_param_passthrough_fs=()
user_data_mount_entries=""

if [ ${#DT_VM_PASSTHROUGH_FS[@]} -ge 0 ]; then
	for fs_decl in ${DT_VM_PASSTHROUGH_FS[@]}; do
		host_src=`echo "${fs_decl}" | cut -d'|' -f1`
		guest_src=`echo "${fs_decl}" | cut -d'|' -f2`
		guest_dst=`echo "${fs_decl}" | cut -d'|' -f3`
		fs=`echo "${fs_decl}" | cut -d'|' -f4`

		install_param_passthrough_fs+=(--filesystem type=mount,accessmode=passthrough,source=${host_src},target=${guest_src},driver.type=${fs})

		user_data_mount_entries=$(cat <<EOF
${user_data_mount_entries}
  - [ "${guest_src}", "${guest_dst}", "${fs}", "defaults", "0", "0" ]
EOF
		)
	done
fi

#echo ${install_param_passthrough_fs[@]}
if [ -n "${user_data_mount_entries}" ]; then
	user_data_mount_entries=$(cat <<EOF
mounts:
${user_data_mount_entries}
EOF
	)
	#echo "${user_data_mount_entries}"
fi

set -x

#cloud-localds -m local -N network-config init.iso user-data.yaml
#cloud-localds init.iso user-data.yaml

virt-install \
	--name ${DT_VM_HOSTNAME} \
	--memory ${DT_VM_RAM_MB} \
	--vcpus ${DT_VM_VCPUS} \
	--disk path=`pwd`/${disk_image_file},format=qcow2 \
	--os-variant ${DT_VM_OS_VARIANT} \
	--network network=default \
	--import \
	--noautoconsole \
	--cloud-init meta-data=<(echo ""),user-data=<(write-mime-multipart \
		${CURR_DIR}/user-data/0defaults.yaml:text/cloud-config \
		${CURR_DIR}/user-data/${DT_VM_OS_VARIANT}.yaml:text/cloud-config \
		custom-data.yaml:text/cloud-config \
		<(cat << EOF
#cloud-config

merge_how:
  - name: list
    settings: [append]
  - name: dict
    settings: [no_replace, recurse_list]

hostname: ${DT_VM_HOSTNAME}

ssh_authorized_keys:
  - `cat ~/.ssh/id_rsa.pub`

${user_data_mount_entries}

EOF
):text/cloud-config \
		) \
	--memorybacking source.type=memfd,access.mode=shared \
	${install_param_passthrough_fs[@]}

set +x
echo
echo "Waiting for the ip to be assigned.."
for (( i=0 ; i<60 ; i++ )); do
	ip=`virsh domifaddr ${DT_VM_HOSTNAME} | awk 'NR==3 {print $4}' | cut -d'/' -f1`
	if [ "${ip}" != "" ]; then
		sleep 5
		echo "Got ${ip}"
		echo
		break
	else
		sleep 1
	fi
done

if [ "${ip}" = "" ]; then
	echo "Error: couldn't get the ip of the new vm."
else
	set -x
	ssh -t \
		-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		${ip} \
		cloud-init status --long --wait
fi
