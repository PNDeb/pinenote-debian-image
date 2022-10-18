#!/bin/bash

pwd=$PWD

cd overlays/custom_debs/
test -d mutter && rm -r mutter
mkdir mutter && cd mutter

wget https://github.com/m-weigand/pinenote_debian_mutter/releases/download/v20221017/mutter.zip
unzip mutter.zip *.deb
rm *.dbgsym*.deb
rm *.dev*.deb
rm mutter.zip
cd ${pwd}

cd overlays/custom_debs/
test -d mesa && rm -r mesa
mkdir mesa && cd mesa

wget https://github.com/m-weigand/pinenote_debian_mesa/releases/download/20221019/mesa_arm64_pinenote.zip

unzip mesa_arm64_pinenote.zip *.deb
rm *.dbgsym*.deb
rm *.dev*.deb
rm mesa-opencl-icd*_arm64.deb
rm mesa_arm64_pinenote.zip
cd ${pwd}
