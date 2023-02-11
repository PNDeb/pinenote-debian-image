#!/usr/bin/env sh
workdir="part_logo"
test -d "${workdir}" && rm -r "${workdir}"
mkdir "${workdir}"
cp free_logos/*.png "${workdir}"/
cp logos_bootmenu/*.png "${workdir}"/


logotool_mod/logotool w logo_new.img "${workdir}"
