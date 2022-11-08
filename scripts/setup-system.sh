#!/bin/sh

# Setup hostname
echo $1 > /etc/hostname

update-initramfs -c -k all
u-boot-update
