#!/bin/bash
outfile="debian_image.img"
test -e "${outfile}" && rm "${outfile}"

fallocate -l 6G "${outfile}"
test -d mnt || mkdir mnt
mkfs.ext4 "${outfile}"
mount -o loop "${outfile}" mnt
cd mnt
tar xvzf ../10_pin_custom_debs.tar.gz 
cd ..

umount mnt

zstd "${outfile}"
rm "${outfile}"
echo "${outfile}".zst is ready
