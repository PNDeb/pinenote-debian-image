#!/usr/bin/env sh
# requires the whohas command (apt-get install whohas)

whohas --strict --shallow libglx-mesa0 -d debian | grep bookworm
ls overlays/custom_debs/mesa | grep libglx-mesa0

echo "------------------_"

whohas mutter --strict --shallow -d debian | grep bookworm
ls overlays/custom_debs/mutter | grep "^mutter"
