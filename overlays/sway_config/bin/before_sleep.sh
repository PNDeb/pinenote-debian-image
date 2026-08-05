#!/bin/bash

brightnessctl --save --device backlight_cool set 0
brightnessctl --save --device backlight_warm set 0
imv -f /etc/off_and_suspend_screen/Pinenotebg4.png
