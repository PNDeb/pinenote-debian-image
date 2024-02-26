#!/bin/bash

cd /root/uboot/
dd if=u-boot-1056mhz/idblock.bin of=/dev/mmcblk0 seek=64
dd if=u-boot-1056mhz/uboot.img of=/dev/mmcblk0 seek=16384
echo "If not errors were reported, then the 1056 MHz u-boot/ram-blob was installed"
echo "Please reboot"
