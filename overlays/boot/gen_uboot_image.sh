#!/bin/bash
# generate an initrd image using dracut

# kernel modules
version=$(ls -t1 /lib/modules | head -1)
echo "Using modules of version ${version}"

sync
depmod -a
test -e dracut-initrd.img && rm dracut-initrd.img
test -e initrd.img && rm initrd.img
/usr/bin/dracut -v \
	-o "lvm luks plymouth systemd resume" \
	--add-drivers rockchip_ebc \
	--omit-drivers "bluetooth hidp" \
	dracut-initrd.img ${version}

mkimage -A arm -T ramdisk -C none -n mw1 -d dracut-initrd.img /boot/uInitrd.img
