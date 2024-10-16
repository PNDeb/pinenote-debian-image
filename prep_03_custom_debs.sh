#!/bin/bash
pwd=$PWD

# koreader
cd overlays/custom_debs/
test -e koreader-2023.08-arm64.deb && rm koreader*.deb
wget -nv https://github.com/koreader/koreader/releases/download/v2024.04/koreader-2024.04-arm64.deb
cd ${pwd}

# evsieve
cd overlays/custom_debs/
test -e evsieve_1.3.1_arm64.deb && rm evsieve*.deb
wget https://github.com/m-weigand/evsieve_pn/releases/download/v1.3.1-arm64/evsieve_1.3.1_arm64.deb
cd "${pwd}"
