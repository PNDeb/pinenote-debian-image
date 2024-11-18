#!/usr/bin/env bash
# Note: this script uses arrays. Be careful when switching shells

lockfile="/boot/waveform_firmware_recovered"
# we read the waveform data from this partition
waveform_partition="/dev/disk/by-partlabel/waveform"

# depending on whether this is our first boot, show a different screen content
if [ -e "${lockfile}" ]; then
	# show on each boot
	fbi -T 1 -d /dev/fb0 etc/off_and_suspend_screen/logo_booting_v2.png
else
	# show only on first boot
	fbi -T 1 -d /dev/fb0 etc/off_and_suspend_screen/logo_first_boot_v2.png
fi

test -e "${lockfile}" && exit

# prevent some error messages until we re-generated the key
echo "Stopping ssh service"
systemctl stop ssh

echo "First boot with the Pinenote!!!"
echo "Sleeping 3 seconds"
sleep 3
echo "Done"

# detect current root partition
new_root=`mount | grep "on / type" | cut -d " " -f 1 | cut -c 6-`

# #############################################################################
# regenerate ssh key
#
# quirk: sshd is not properly configured at first boot and needs to generate
# its certificate
echo "Re-generating ssh keys"
dpkg-reconfigure openssh-server
echo "Starting ssh service"
systemctl start ssh.service

# #############################################################################
# grow root partition
# in case we install using an disc image, grow the ext4 rootfs to the edge of
# the partition
echo "Growing root fs to the edge of the partition"
resize2fs /dev/"${new_root}"

# #############################################################################
# HOME directory options
echo "Checking /home and data partition options"

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
		device=`readlink -f ${target_partition}`

		# check that the partition is mounted and contains an ext4 fs
		check_mount=`mount | grep "${device}" | grep ext4 | grep "${mnt_point}" | wc -l`
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
				# make sure that the system is aware of the new home
				echo "Initiating systemctl daemon-reload"
				systemctl daemon-reload
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
			echo "Executing resize2fs..."
			e2fsck -fy "${target_partition}"
			resize2fs "${target_partition}"
		fi

		if [ ${recreate_part} -eq 1 ]; then
			echo "Re-creating partition..."
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

		# now that everything is finished, potentially mount /home
		if [ -e "${mnt_point}/${use_as_home_var}" ]; then
			echo "Mounting home"
			# mount home
			mount /home
		fi
	fi
fi

cd /root

# #############################################################################
# Waveform extraction
outdir="/usr/lib/firmware"
mkdir -p ${outdir}/rockchip


target_wbf_file="/usr/lib/firmware/rockchip/ebc.wbf"
if [ -e "${target_wbf_file}" ]; then
	echo 'EBC waveform file already exists. Will not reboot'
	wbf_already_exists=1
else
	echo 'EBC waveform file does not already exist. Will reboot'
	wbf_already_exists=0
fi

# 1) Get epd/eink waveforms from the waveform partition
# md5sum: 62a4817fda54ed39602a51229099ff02
dd if="${waveform_partition}" of=${outdir}/rockchip/ebc_orig.wbf  bs=1k count=2048

# this array contains hashes of known, good, waveform files
# we only replace existing waveform files if the hashes match
# md5-hashes
waveform_hashes=("62a4817fda54ed39602a51229099ff02" "086faea8714e6a365a0174850d0823c0")
hash=$(md5sum /usr/lib/firmware/rockchip/ebc_orig.wbf | cut -d ' ' -f 1)
echo "We got a waveform hash: ${hash}"
hash_found=0
for test_hash in ${waveform_hashes[@]}
do
	echo "Checking against known good waveform: ${test_hash}"
	if [ "${hash}" == "${test_hash}" ]; then
		echo "Found a correct hash"
		hash_found=1
	fi
done

# only proceed if the hash is known
if [ "${hash_found}" -eq 1 ]; then
	echo "Proceeding with setting the waveform"

	if [ -e "${target_wbf_file}" ]; then
		echo "Found a waveform file at ${target_wbf_file}. Will move to .backup"
		mv "${target_wbf_file}" "${target_wbf_file}".backup
	fi

	ln -s ${outdir}/rockchip/ebc_orig.wbf ${outdir}/rockchip/ebc.wbf

	# by default we assume / on /dev/mmcblk0p5, but we check when running this
	# script and make sure other root partitions are properly taken care of in the
	# extlinux.conf file on new reboot
	sed -i "s/U_BOOT_ROOT=\"root=\/dev\/mmcblk0p[0-9].\"/U_BOOT_ROOT=\"root=\/dev\/${new_root}\"/" /etc/default/u-boot

	# Now that we have the firmware, regenerate the initrd for the kernel
	if [ "${wbf_already_exists}" -eq 0 ]; then
		update-initramfs -c -k all
	fi
fi

u-boot-update

# Batch 2 factory image: We need to install u-boot on first boot
# cd /root/uboot
# bash install_stable_1056mhz_uboot.sh

# we do not want to repeat running this script, see check at the beginning of
# the file
touch "${lockfile}"
echo "This is a lockfile for the first-boot script of the PineNote. Do not delete" >> "${lockfile}"

# only for batch 2 factory image
# reboot
if [ "${wbf_already_exists}" -eq 0 ]; then
	reboot
fi
