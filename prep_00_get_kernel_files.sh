#!/usr/bin/env sh

test -d tmp_kernel && rm -r tmp_kernel
mkdir tmp_kernel && cd tmp_kernel
# wget https://github.com/m-weigand/linux/releases/download/20221013/pinenote_kernel_modules_dtb.zip
wget https://github.com/m-weigand/linux/releases/download/v20221207/pinenote_kernel_modules_dtb.zip
unzip pinenote_kernel_modules_dtb.zip

# test -e overlays/modules/kernel-modules.tar.gz && rm overlays/modules/kernel-modules.tar.gz

# # image and dtb
# cp rk3566-pinenote-v1.2.dtb ../overlays/boot/
# cp Image ../overlays/boot/
# cp modules.tar.gz ../overlays/modules/kernel-modules.tar.gz

cp linux-image*no_compression.deb ../overlays/kernel/

cd ..
rm -r tmp_kernel
