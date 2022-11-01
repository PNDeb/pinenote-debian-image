#!/bin/sh

# Setup hostname
echo $1 > /etc/hostname

# since we copied the default/u-boot file later
u-boot-update
