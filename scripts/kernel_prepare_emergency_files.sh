#!/usr/bin/env sh
# We would like to store one kernel (image, initrd, dtb) in an easy-to-remember
# location with easy names in case we need to boot from u-boot prompt by hand

emergency_dir="/boot/emergency"
mkdir -p "${emergency_dir}"
kernel_file=`ls -1 /boot/vmlinuz* | tail -1`
initrd_file=`ls -1 /boot/initrd* | tail -1`
dtb_file=`cat /boot/extlinux/extlinux.conf  | grep fdt | head -1 | cut -d ' ' -f 2`

cp "${kernel_file}" "${emergency_dir}"/image
cp "${initrd_file}" "${emergency_dir}"/initrd
mkimage -A arm -T ramdisk -C none -n uInitrd -d "${emergency_dir}"/initrd "${emergency_dir}"/initrd_ub
rm "${emergency_dir}"/initrd
cp "${dtb_file}" "${emergency_dir}"
