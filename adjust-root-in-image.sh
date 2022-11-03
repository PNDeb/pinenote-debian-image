#!/bin/sh

if [ $# -eq 0 ]; then
cat << EOF
This script creates a loop device from the given partition image file, mount it
and either displays or replaces the root parameter used in the kernel command
line. Then it unmounts and detach the loop device. This operations requires
root privileges.

USAGE:
 adjust-root-in-image.sh <imagefile> [<device>]

If <device> is missing, the script will only show the value of the root
parameter used inside the <imagefile>.

If <device> is present, the script will write this value for the root parameter
inside the <imagefile>.

Currently, it only does work on these files:
/boot/extlinux/extlinux.conf
/etc/default/u-boot

EOF

exit 0
fi

imagefile="$1"
device="$2"

if [ ! -f "$imagefile" ]; then
	echo Error: No such file: "$imagefile".
	exit 31
fi

loopdev=`/sbin/losetup --show --find "$imagefile"`

if [ ! "$?" -eq "0" ] ; then
	echo Error: It seems we were unable to create a loop device.
	exit 32
fi

mountdir=`mktemp --directory`

mount $loopdev $mountdir
cd $mountdir

# The files we are looking into for the root parameter
extlinux="boot/extlinux/extlinux.conf"
uboot="etc/default/u-boot"
files="$extlinux $uboot"

if [ -n "$device" ]; then
	echo == BEFORE ==
	grep -e "root="  $files

	what_to_find='^U_BOOT_ROOT=.*$'
	replace_with="U_BOOT_ROOT=\"root=$device\""
	sed -i -e "s#$what_to_find#$replace_with#" $uboot

	what_to_find=' root=[^ ]*'
	replace_with=" root=$device"
	sed -i -e "s#$what_to_find#$replace_with#" $extlinux

	echo == AFTER ==
fi
grep -e "root="  $files

# Cleaning up
cd ..
umount $mountdir
/sbin/losetup -d $loopdev
rmdir $mountdir
