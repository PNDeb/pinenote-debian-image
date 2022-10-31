#!/usr/bin/env sh
# requires kernel options:
# +CONFIG_MD=y
# +CONFIG_BLK_DEV_DM=m
# and https://github.com/tchebb/parse-android-dynparts
#
test -e /extlinux/waveform_firmware_recovered && exit

echo "First boot with the Pinenote!!!"
echo "Press [ENTER] to continue"
echo "Sleeping 10 seconds"
sleep 3
echo "Done"

cd /root
pwd=$PWD
outdir="/usr/lib/firmware"
mkdir -p ${outdir}/brcm
mkdir -p ${outdir}/rockchip

# 1) Get waveforms
# md5sum: 62a4817fda54ed39602a51229099ff02
dd if=/dev/mmcblk0p3 of=${outdir}/rockchip/ebc.wbf  bs=1k count=2048

# 2) Get wifi/bluetooth firmware
dmsetup create --concise "$(/root/parse-android-dynparts /dev/mmcblk0p13)"
ls /dev/mapper/dynpart-*

mount /dev/mapper/dynpart-vendor /mnt
cd /mnt/etc/firmware
# tar -c -j -f /sdcard/firmware.tar.bz2 *
cp * ${outdir}

cd ${outdir}

cp fw_bcm43455c0_ag_cy.bin brcm/brcmfmac43455-sdio.bin
cp nvram_ap6255_cy.txt brcm/brcmfmac43455-sdio.txt
cp fw_bcm43455c0_ag_cy.bin brcm/brcmfmac43455-sdio.pine64,pinenote.bin
cp nvram_ap6255_cy.txt brcm/brcmfmac43455-sdio.pine64,pinenote.txt
cp BCM4345C0.hcd brcm/BCM4345C0.hcd

umount  /mnt
dmsetup remove /dev/mapper/dynpart-*

cd /extlinux
./gen_uboot_image.sh

touch /extlinux/waveform_firmware_recovered
reboot
