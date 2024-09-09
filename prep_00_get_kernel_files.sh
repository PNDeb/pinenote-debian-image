#!/usr/bin/env sh
# get a known and working kernel package. This is primarily used as an
# emergency kernel with a fixed, known, filename so we can easily boot from the
# u-boot console

cd overlays/kernel/
rm *.deb

# 6.3.10_v1
wget https://github.com/m-weigand/linux/releases/download/v20230802/linux-image-6.3.10-pinenote-202308011945-ge6603de5834c_6.3.10-ge6603de5834c-1_arm64_no_compression.deb
wget https://github.com/m-weigand/linux/releases/download/v20230802/linux-headers-6.3.10-pinenote-202308011945-ge6603de5834c_6.3.10-ge6603de5834c-1_arm64.deb
cd ../../
