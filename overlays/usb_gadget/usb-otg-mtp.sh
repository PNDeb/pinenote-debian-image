#!/bin/bash
# Set up USB-MTP gadget mode
# Only execute AFTER plugging in to the host computer

# requires uMTP
# https://github.com/viveris/uMTP-Responder.git
# Tested with commit 699def10a1b4055d4fe73c15112435cb02f0e588
#
# DO NOT USE THE VERY OLD VERISON INCLUDED IN DEBIAN!!!
#

cleanup()
{
	echo "Cleaning up"
	umount /dev/ffs-mtp
	modprobe -r g_ffs
}


modprobe g_ffs functions=mtp idVendor="0x1d6b" iSerialNumber="fedcba9876543210"


test -d /dev/ffs-mtp || mkdir /dev/ffs-mtp
mount -t functionfs mtp /dev/ffs-mtp

echo "Waiting a few seconds, hoping that everything sets up correctly"
sleep 2

# run the mtp responder

trap cleanup SIGINT SIGTERM
/home/user/uMTP-Responder/umtprd
trap - SIGINT SIGTERM

# clean up
