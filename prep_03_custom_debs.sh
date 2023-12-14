#!/bin/bash

pwd=$PWD

# koreader
cd overlays/custom_debs/
test -e koreader-2023.08-arm64.deb && rm koreader*.deb
wget -nv https://github.com/koreader/koreader/releases/download/v2023.08/koreader-2023.08-arm64.deb
cd ${pwd}

# evsieve
cd overlays/custom_debs/
test -e evsieve_1.3.1_arm64.deb && rm evsieve*.deb
wget https://github.com/m-weigand/evsieve_pn/releases/download/v1.3.1-arm64/evsieve_1.3.1_arm64.deb
cd "${pwd}"

# xournalpp
cd overlays/custom_debs/
rm xournalpp*.deb
# wget https://github.com/m-weigand/xournalpp_pn/releases/download/v20221201/xournalpp-1.1.2+dev--unknown-unknown.deb
# wget -nv https://github.com/m-weigand/xournalpp_pn/releases/download/v20221210/xournalpp-1.1.2+dev-Debian-bookworm-unknown.deb
wget -nv https://github.com/m-weigand/xournalpp_pn/releases/download/v20230729/xournalpp-1.1.2+dev-pinenote-Debian-bookworm-unknown.deb
cd "${pwd}"

# pinenote dbus service
cd overlays/custom_debs
test -e pinenote-dbus-service*.deb && rm pinenote-dbus-service*.deb
wget -nv https://github.com/PNDeb/pinenote_dbus_service/releases/download/v0.2.1-dev/pinenote-dbus-service_0.2.1-dev-1_arm64.deb
# wget -nv https://github.com/PNDeb/pinenote_dbus_service/releases/download/v20231208/pinenote-dbus-service_0.2.0-dev-1_arm64.deb
# wget -nv https://github.com/m-weigand/pinenote_dbus_service/releases/download/v20221207/pinenote_dbus_service_0.1.0_arm64.deb
cd "${pwd}"

# 2023.05.17: (temporarily) fixed brcm firmware
cd overlays/custom_debs
test -e firmware-brcm80211_20230625-1+salsaci_all.deb && rm firmware-brcm80211_20230625-1+salsaci_all.deb
# wget -nv -O firmware-brcm80211_20230625-1+salsaci_all.deb https://salsa.debian.org/diederik/firmware-nonfree/-/jobs/4652912/artifacts/raw/debian/output/firmware-brcm80211_20230625-1+salsaci_all.deb?inline=false
wget -nv -O firmware-brcm80211_20230625-1+salsaci_all.deb https://salsa.debian.org/diederik/firmware-nonfree/-/jobs/4774107/artifacts/raw/debian/output/firmware-brcm80211_20230625-1+salsaci_all.deb?inline=false
cd "${pwd}"

cd overlays/custom_debs
rm pinenote-gnome-extension*.deb
wget -nv https://github.com/PNDeb/pinenote-gnome-extension/releases/download/v1.0/pinenote-gnome-extension_1.0_all.deb
cd "${pwd}"
