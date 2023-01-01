#!/usr/bin/env sh

cd overlays/firmware/brcm
rm *.txt
wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/brcm/brcmfmac43455-sdio.AW-CM256SM.txt
cd ../../../
