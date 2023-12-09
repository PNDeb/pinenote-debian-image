#!/bin/bash
# https://www.kernel.org/doc/html/latest/usb/gadget_configfs.html

#
modprobe libcomposite

# go to configfs directory for USB gadgets
CONFIGFS_ROOT=/sys/kernel/config # adapt to your machine

cd "${CONFIGFS_ROOT}"/usb_gadget

# create gadget directory and enter it
mkdir g1
cd g1

# USB ids
echo 0x1d6b > idVendor
echo 0x104 > idProduct

# USB strings, optional
mkdir strings/0x409 # US English, others rarely seen
echo "Collabora" > strings/0x409/manufacturer
echo "ECM" > strings/0x409/product

# create the (only) configuration
mkdir configs/c.1 # dot and number mandatory
echo 250 > configs/c.1/MaxPower

# create the (only) function
mkdir functions/ecm.usb0 # .

# assign function to configuration
ln -s functions/ecm.usb0/ configs/c.1/

# https://patchwork.kernel.org/project/linux-usb/patch/c4a428ec617a954dc27221d8a9133d22c38b2447.1578537372.git.thinhn@synopsys.com/
# echo "full-speed" > max_speed

# bind!
echo fcc00000.usb > UDC # ls /sys/class/udc to see available UDCs

cleanup(){
	echo "Cleaning up"
	echo "" > /sys/kernel/config/usb_gadget/g1/UDC
}

trap cleanup SIGINT
echo "CTRL+C to end usb gadget mode"
read
trap - SIGINT

# to unbind:
# echo "" > UDC
# echo "" > /sys/kernel/config/usb_gadget/g1/UDC
