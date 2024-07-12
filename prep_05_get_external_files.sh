#!/usr/bin/env sh
# get various external files

# get gnome theme
cd overlays/gnome_theme
test -d PNEink && rm -rf PNEink
# git clone https://github.com/MichiMolle/PNEink.git
git clone https://github.com/m-weigand/PNEink.git
cd ../../
