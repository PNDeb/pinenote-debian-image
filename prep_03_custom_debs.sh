#!/bin/bash

pwd=$PWD

cd overlays/custom_debs/
test -d mutter && rm -r mutter
mkdir mutter && cd mutter

# wget https://github.com/m-weigand/pinenote_debian_mutter/releases/download/v20221231/mutter.zip
# wget https://github.com/m-weigand/pinenote_debian_mutter/releases/download/v20230317/mutter.zip
# wget https://github.com/m-weigand/pinenote_debian_mutter/releases/download/v20230428/mutter.zip
wget https://github.com/m-weigand/pinenote_debian_mutter/releases/download/v20230517/mutter.zip
unzip mutter.zip *.deb
rm *dbgsym*.deb
rm *dev*.deb
rm *tests*.deb
rm mutter.zip
cd ${pwd}

cd overlays/custom_debs/
test -d mesa && rm -r mesa
mkdir mesa && cd mesa

# wget https://github.com/m-weigand/pinenote_debian_mesa/releases/download/v22.3.3-1_v1/mesa_arm64_pinenote.zip
wget https://github.com/m-weigand/pinenote_debian_mesa/releases/download/v20230517/mesa_arm64_pinenote.zip
unzip mesa_arm64_pinenote.zip *.deb
rm *dbgsym*.deb
rm *dev*.deb
rm libd3dadapter9-mesa*.deb
rm mesa-opencl-icd*_arm64.deb
rm mesa_arm64_pinenote.zip
cd ${pwd}

# koreader
cd overlays/custom_debs/
rm koreader*.deb*
# wget https://github.com/koreader/koreader/releases/download/v2022.10/koreader-2022.10-arm64.deb
wget https://github.com/koreader/koreader/releases/download/v2023.04/koreader-2023.04-arm64.deb
cd ${pwd}

# evsieve
cd overlays/custom_debs/
rm evsieve*.deb
wget https://github.com/m-weigand/evsieve_pn/releases/download/v1.3.1-arm64/evsieve_1.3.1_arm64.deb
cd "${pwd}"

# xournalpp
cd overlays/custom_debs/
rm xournalpp*.deb
# wget https://github.com/m-weigand/xournalpp_pn/releases/download/v20221201/xournalpp-1.1.2+dev--unknown-unknown.deb
wget https://github.com/m-weigand/xournalpp_pn/releases/download/v20221210/xournalpp-1.1.2+dev-Debian-bookworm-unknown.deb
cd "${pwd}"

# pinenote dbus service
cd overlays/custom_debs
rm pinenote_dbus_service*.deb
wget https://github.com/m-weigand/pinenote_dbus_service/releases/download/v20221207/pinenote_dbus_service_0.1.0_arm64.deb
cd "${pwd}"

# 2023.05.17: (temporarily) fixed brcm firmware
# https://salsa.debian.org/diederik/firmware-nonfree/-/jobs/4221052/artifacts/browse/debian/output/
cd overlays/custom_debs
test -e firmware-brcm80211_20230310-1~exp3+salsaci_all.deb && rm firmware-brcm80211_20230310-1~exp3+salsaci_all.deb
wget https://salsa.debian.org/diederik/firmware-nonfree/-/jobs/4221052/artifacts/raw/debian/output/firmware-brcm80211_20230310-1~exp3+salsaci_all.deb?inline=false -O firmware-brcm80211_20230310-1~exp3+salsaci_all.deb
cd "${pwd}"

cd overlays/custom_debs
rm pinenote-gnome-extension*.deb
wget https://github.com/PNDeb/pinenote-gnome-extension/releases/download/v1.0/pinenote-gnome-extension_1.0_all.deb
cd "${pwd}"
