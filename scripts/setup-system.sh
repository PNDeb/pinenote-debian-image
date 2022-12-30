#!/bin/sh

# Setup hostname
echo $1 > /etc/hostname
# echo "Running as user $USER"
# echo $PATH
# ls -l /usr/bin/m*
# dpkg -L dracut
# dpkg -L dracut-core

# apt install -Y aptitude
# aptitude search dracut-core

echo Setup /etc/fstab
cat >>/etc/fstab << EOF
/dev/mmcblk0p17 /     ext4 defaults 0 0
EOF

echo Using dracut to generate the initrd:

# does not work in bookworm anymore
# mkinitrd --fstab /dracut-initrd.img $(ls /lib/modules/)

# --include ${PWD}/offscreen.bin /usr/lib/firmware/rockchip/rockchip_ebc_default_screen.bin \
/usr/bin/dracut -v \
	--fstab \
	-o "lvm luks plymouth systemd resume" \
	--add-drivers rockchip_ebc \
	--omit-drivers "bluetooth hidp" \
	dracut-initrd.img $(ls /lib/modules/)

mkimage -A arm -T ramdisk -C none -n uInitrd -d /dracut-initrd.img /extlinux/uInitrd.img

