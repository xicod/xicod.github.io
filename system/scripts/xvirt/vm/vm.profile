DT_VM_HOSTNAME=debtest
DT_VM_VCPUS=2
DT_VM_RAM_MB=4096
DT_VM_DISK_SIZE=20G
DT_VM_SWAP_SIZE=4G
DT_VM_OS_VARIANT=debian13
# host_folder|guest_device_name|guest_mount_path|fs
DT_VM_PASSTHROUGH_FS=(
	"`pwd`/shared|host_shared|/mnt/host-data|virtiofs"
)
