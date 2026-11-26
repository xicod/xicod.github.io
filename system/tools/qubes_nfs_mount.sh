#!/bin/bash

#set -x

function mount_nfs_drive {
	share=$1
	dst=$2

	mkdir -p ${dst}

	(
		while ! mountpoint -q ${dst}; do
			echo "Trying to mount ${share} to ${dst}"
			mount -t nfs4 -o port=2049,proto=tcp,rsize=1048576,wsize=1048576,soft,timeo=10,retrans=2 127.0.0.1:${share} ${dst}

			sleep 5
		done
	) &
}

if [ -z "${DT_NFS_MOUNT_DATA}" ]; then
	echo "Need DT_NFS_MOUNT_DATA defined"
	exit 1
fi

nfs_host=$(echo "${DT_NFS_MOUNT_DATA}" | cut -d'|' -f1)
nfs_port=$(echo "${DT_NFS_MOUNT_DATA}" | cut -d'|' -f2)
nfs_mount_points=$(echo "${DT_NFS_MOUNT_DATA}" | cut -d'|' -f3)

qvm-connect-tcp 2049:${nfs_host}:${nfs_port}

IFS=, read -ra nfs_mount_points_arr <<< "${nfs_mount_points}"
for nfs_mount_point in "${nfs_mount_points_arr[@]}"; do
	mount_point_share=$(echo "${nfs_mount_point}" | cut -d':' -f1)
	mount_point_dst=$(echo "${nfs_mount_point}" | cut -d':' -f2)

	mount_nfs_drive ${mount_point_share} ${mount_point_dst}
done

sleep 1

echo Done
