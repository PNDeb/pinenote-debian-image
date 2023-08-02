#!/usr/bin/env sh

cd overlays/kernel/
rm *.deb
# 6.3_v2 kernel
# wget https://github.com/m-weigand/linux/releases/download/v20230605/linux-image-6.3.0-pinenote-202306050736-g0f64a7bedfee_6.3.0-g0f64a7bedfee-1_arm64_no_compression.deb
# wget https://github.com/m-weigand/linux/releases/download/v20230605/linux-headers-6.3.0-pinenote-202306050736-g0f64a7bedfee_6.3.0-g0f64a7bedfee-1_arm64.deb

# 6.3.10_v1
# wget https://github.com/m-weigand/linux/releases/download/v20230727/linux-image-6.3.10-pinenote-202307271912-g616dc3bce559_6.3.10-g616dc3bce559-1_arm64_no_compression.deb
# wget https://github.com/m-weigand/linux/releases/download/v20230727/linux-headers-6.3.10-pinenote-202307271912-g616dc3bce559_6.3.10-g616dc3bce559-1_arm64.deb

# 6.3.10_v1
wget https://github.com/m-weigand/linux/releases/download/v20230802/linux-image-6.3.10-pinenote-202308011945-ge6603de5834c_6.3.10-ge6603de5834c-1_arm64_no_compression.deb
wget https://github.com/m-weigand/linux/releases/download/v20230802/linux-headers-6.3.10-pinenote-202308011945-ge6603de5834c_6.3.10-ge6603de5834c-1_arm64.deb
cd ../../
