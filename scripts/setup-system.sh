#!/bin/sh

# Setup hostname
echo $1 > /etc/hostname

echo Setup /etc/fstab
cat >>/etc/fstab << EOF
/dev/mmcblk0p17 /     ext4 defaults 0 0
EOF

echo Using dracut to generate the initrd:

mkinitrd --fstab /dracut-initrd.img $(ls /lib/modules/)
mkimage -A arm -T ramdisk -C none -n uInitrd -d /dracut-initrd.img /boot/uInitrd.img

