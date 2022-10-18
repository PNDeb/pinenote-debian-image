#!/usr/bin/env sh
url="https://github.com/m-weigand/pinenote_debian_parse-android-dynparts/releases/download/v1/parse-android-dynparts.zip"
binary="overlays/root/parse-android-dynparts"

test -e ${binary} && exit

cd overlays/root
wget ${url}
unzip parse-android-dynparts.zip
chmod +x parse-android-dynparts
rm parse-android-dynparts_src.tar.gz  parse-android-dynparts.zip
