#!/usr/bin/env sh
# Run this script in order to try to reverse burn-in
# Use the RESET waveform, this will always clear the screen to white
echo 0 > /sys/module/rockchip_ebc/parameters/refresh_waveform;
# trigger multiple refreshes
for i in `seq 1 5`; do
   	dbus-send --system --print-reply --dest=org.pinenote.ebc /ebc org.pinenote.ebc.TriggerGlobalRefresh;
   	sleep 2;
done;

# use the normal GC16 waveform for refreshing
echo 4 > /sys/module/rockchip_ebc/parameters/refresh_waveform;

# reset the screen content
dbus-send --system --print-reply --dest=org.pinenote.ebc /ebc org.pinenote.ebc.TriggerGlobalRefresh
