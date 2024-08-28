#!/usr/bin/env sh
# requires kernel options:
# +CONFIG_MD=y
# +CONFIG_BLK_DEV_DM=m
# and https://github.com/tchebb/parse-android-dynparts
lockfile="/boot/waveform_firmware_recovered"
# we read the waveform data from this partition
waveform_partition="/dev/disk/by-partlabel/waveform"

test -e "${lockfile}" && exit

echo "First boot with the Pinenote!!!"
echo "Press [ENTER] to continue"
echo "Sleeping 3 seconds"
sleep 3
echo "Done"

cd /root
pwd=$PWD
outdir="/usr/lib/firmware"
mkdir -p ${outdir}/brcm
mkdir -p ${outdir}/rockchip

# 1) Get epd/eink waveforms from the waveform partition
# md5sum: 62a4817fda54ed39602a51229099ff02
dd if="${waveform_partition}" of=${outdir}/rockchip/ebc_orig.wbf  bs=1k count=2048
ln -s ${outdir}/rockchip/ebc_orig.wbf ${outdir}/rockchip/ebc.wbf

# by default we assume / on /dev/mmcblk0p8, but we check when running this
# script and make sure other root partitions are properly taken care of in the
# extlinux.conf file on new reboot
new_root=`mount | grep "on / type" | cut -d " " -f 1 | cut -c 6-`
# sed -i "s/mmcblk0p8/${new_root}/" /etc/default/u-boot
 sed -i "s/U_BOOT_ROOT=\"root=\/dev\/mmcblk0p[0-9].\"/U_BOOT_ROOT=\"root=\/dev\/${new_root}\"/" /etc/default/u-boot

# Now that we have the firmware, regenerate the initrd for the kernel
update-initramfs -c -k all
u-boot-update

# quirk: sshd is not properly configured at first boot and needs to generate
# its certificate
dpkg-reconfigure openssh-server

# in case we install using an disc image, grow the ext4 rootfs to the edge of
# the partition
echo "Growing root fs to the edge of the partition"
resize2fs /dev/"${new_root}"

# HOME directory options

# we only want to react to files specific to this partition
use_as_home_var="pn_use_as_home_${new_root}"
transfer_files_var="pn_transfer_files_${new_root}"
grow_fs_var="pn_grow_fs_${new_root}"
recreate_fs_var="pn_recreate_fs_${new_root}"

# check if partition 10 should be used as /home
mnt_point="/tmp_pn_mount_data"
# only proceed if the mount point does not exist
if [ ! -e "${mnt_point}" ];
then
	target_partition="/dev/disk/by-partlabel/data"
	if [ -e "${target_partition}" ];
	then
		mkdir "${mnt_point}"
		mount "${target_partition}" "${mnt_point}"
		# check that the partition is mounted and contains an ext4 fs
		check_mount=`mount | grep "${target_partition}" | grep ext4 | grep "${mnt_point}" | wc -l`
		if [ "${check_mount}" -eq 1 ]
		then
			echo "Found a valid ext4 fs on ${target_partition}"
			# Do we want this partition as /home ?
			if [ -e "${mnt_point}/${use_as_home_var}" ]; then
				echo "Using ${target_partition} as /home"
				fstab_line="${target_partition} /home              ext4   defaults"
				echo "Adding line to /etc/fstab"
				echo "    ${fstab_line}"
				echo "${fstab_line}" >> /etc/fstab
				echo "Changes will take effect after reboot"
			fi
			transfer_user_files=0
			if [ -e "${mnt_point}/${transfer_files_var}" ]; then
				transfer_user_files=1
			fi

			grow_part=0
			if [ -e "${mnt_point}/${grow_fs_var}" ]; then
				grow_part=1
				echo "Growing partition to full size"
			fi

			recreate_part=0
			if [ -e "${mnt_point}/${recreate_fs_var}" ]; then
				recreate_part=1
				echo "Recreating ext4 fs"
			fi
		fi

		umount "${mnt_point}"

		if [ ${grow_part} -eq 1 ]; then
			echo "Executing resize2fs"
			e2fsck -fy "${target_partition}"
			resize2fs "${target_partition}"
		fi

		if [ ${recreate_part} -eq 1 ]; then
			mkfs.ext4 "${target_partition}"
			mount "${target_partition}" "${mnt_point}"
			# we want to keep this, but none of the other control files
			touch "${mnt_point}/${use_as_home_var}"
			umount "${mnt_point}"
		fi

		# remount again after growing so we can transfer the files, if
		# requested
		# assume two things:
		#  1) the mount succeeds (we already did it once if we reach this code)
		#  2) there is enough disc space in the new partition
		if [ ${transfer_user_files} -eq 1 ]; then
			mount "${target_partition}" "${mnt_point}"
			rsync -avh /home/ "${mnt_point}"/
			test -e "${mnt_point}/pn_transfer_files" && rm "${mnt_point}/pn_transfer_files"
			umount "${mnt_point}"
		fi
		test -d "${mnt_point}" && rm -r "${mnt_point}"
	fi
fi

# we do not want to repeat running this script, see check at the beginning of
# the file
touch "${lockfile}"

reboot
