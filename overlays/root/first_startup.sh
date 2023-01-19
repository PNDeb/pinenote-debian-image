#!/usr/bin/env sh
# requires kernel options:
# +CONFIG_MD=y
# +CONFIG_BLK_DEV_DM=m
# and https://github.com/tchebb/parse-android-dynparts
lockfile="/boot/waveform_firmware_recovered"

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
dd if=/dev/mmcblk0p3 of=${outdir}/rockchip/ebc_orig.wbf  bs=1k count=2048
ln -s ${outdir}/rockchip/ebc_orig.wbf ${outdir}/rockchip/ebc.wbf

# do not (yet) call this script here as it takes ca. 20 minutes to complete!!!
# python3 /root/parse_waveforms_and_modify.py

# 2) Get wifi/bluetooth firmware from Android partition
# note: should not be required anymore
# dmsetup create --concise "$(/root/parse-android-dynparts /dev/mmcblk0p13)"
# ls /dev/mapper/dynpart-*

# mount /dev/mapper/dynpart-vendor /mnt
# cd /mnt/etc/firmware
# # tar -c -j -f /sdcard/firmware.tar.bz2 *
# cp * ${outdir}

# cd ${outdir}

# cp fw_bcm43455c0_ag_cy.bin brcm/brcmfmac43455-sdio.bin
# cp nvram_ap6255_cy.txt brcm/brcmfmac43455-sdio.txt
# cp fw_bcm43455c0_ag_cy.bin brcm/brcmfmac43455-sdio.pine64,pinenote.bin
# cp nvram_ap6255_cy.txt brcm/brcmfmac43455-sdio.pine64,pinenote.txt
# cp BCM4345C0.hcd brcm/BCM4345C0.hcd

# umount  /mnt
# dmsetup remove /dev/mapper/dynpart-*

# by default we assume / on /dev/mmcblk0p17, but we check when running this
# script and make sure other root partitions are properly taken care of in the
# extlinux.conf file on new reboot
new_root=`mount | grep "on / type" | cut -d " " -f 1 | cut -c 6-`
sed -i "s/mmcblk0p6/${new_root}/" /etc/default/u-boot
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

# we do not want to repeat running this script, see check at the beginning of
# the file
touch "${lockfile}"

reboot
