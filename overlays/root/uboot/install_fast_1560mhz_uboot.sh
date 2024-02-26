#!/bin/bash

cd /root/uboot/
dd if=u-boot-1560mhz/u-boot-pinenote/idblock.bin of=/dev/mmcblk0 seek=64
dd if=u-boot-1560mhz/u-boot-pinenote/uboot.img of=/dev/mmcblk0 seek=16384
echo "If not errors were reported, then the 1560 MHz u-boot/ram-blob was installed"
echo "Please reboot"
