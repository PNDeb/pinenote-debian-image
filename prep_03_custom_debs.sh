#!/bin/bash

pwd=$PWD

cd overlays/custom_debs/
test -d mutter && rm -r mutter
mkdir mutter && cd mutter

wget https://github.com/m-weigand/pinenote_debian_mutter/releases/download/v20221124_v1/mutter.zip
unzip mutter.zip *.deb
rm *dbgsym*.deb
rm *dev*.deb
rm *tests*.deb
rm mutter.zip
cd ${pwd}

cd overlays/custom_debs/
test -d mesa && rm -r mesa
mkdir mesa && cd mesa

wget https://github.com/m-weigand/pinenote_debian_mesa/releases/download/v20221125_v1/mesa_arm64_pinenote.zip

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
wget https://github.com/koreader/koreader/releases/download/v2022.10/koreader-2022.10-arm64.deb
cd ${pwd}

# evsieve
cd overlays/custom_debs/
wget https://github.com/m-weigand/evsieve_pn/releases/download/v1.3.1-arm64/evsieve_1.3.1_arm64.deb
cd "${pwd}"

# xournalpp
cd overlays/custom_debs/
# todo
cd "${pwd}"
