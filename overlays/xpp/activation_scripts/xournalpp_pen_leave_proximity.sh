#!/bin/sh

# echo auto > /sys/devices/platform/fdec0000.ebc/power/control
echo 0 > /sys/module/rockchip_ebc/parameters/prepare_prev_before_a2

# echo 4 > /sys/module/rockchip_ebc/parameters/default_waveform

# echo 1 > /sys/module/rockchip_ebc/parameters/diff_mode
echo 0 > /sys/module/rockchip_ebc/parameters/split_area_limit
