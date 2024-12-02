#!/bin/bash

brightnessctl --restore --device=backlight_warm
brightnessctl --restore --device=backlight_cool
killall imv-wayland
