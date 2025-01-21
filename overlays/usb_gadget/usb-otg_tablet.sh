#!/bin/bash
# https://www.kernel.org/doc/html/latest/usb/gadget_configfs.html

#
modprobe libcomposite

# go to configfs directory for USB gadgets
CONFIGFS_ROOT=/sys/kernel/config # adapt to your machine

# Unbind and remove any existing gadget named 'g1' to avoid conflicts
if [ -d "${CONFIGFS_ROOT}/usb_gadget/g1" ]; then
  # Unbind if bound
  echo "" > "${CONFIGFS_ROOT}/usb_gadget/g1/UDC" 2>/dev/null || true
  # Remove the gadget directory
  rm -rf "${CONFIGFS_ROOT}/usb_gadget/g1"
fi

cd "${CONFIGFS_ROOT}"/usb_gadget

# create gadget directory and enter it
mkdir g1
cd g1

# USB ids
# echo 0x1d6b > idVendor
# echo 0x104 > idProduct
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB # USB2

# USB strings, optional
mkdir strings/0x409 # US English, others rarely seen
echo "fedcba9876543210" > strings/0x409/serialnumber
echo "Pine64" > strings/0x409/manufacturer
echo "PineNote" > strings/0x409/product

# create the (only) configuration
# dot and number mandatory
mkdir configs/c.1
mkdir configs/c.1/strings/0x409
echo "Conf 1" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

# create the (only) function
mkdir functions/hid.usb0

# None
echo 2 > functions/hid.usb0/protocol
echo 1 > functions/hid.usb0/subclass
echo 15 > functions/hid.usb0/report_length

# HID Mouse e.g. copy from logitech mouse as follows:
# for i in $(usbhid-dump -a XXX:YYY |tail -n +2); do echo -n \\\\x$i; done |tr '[:upper:]' '[:lower:]'
# echo -ne \\x05\\x01\\x09\\x02\\xa1\\x01\\x09\\x01\\xa1\\x00\\x05\\x09\\x19\\x01\\x29\\x08\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x08\\x81\\x02\\x05\\x01\\x16\\x01\\xf8\\x26\\xff\\x07\\x75\\x0c\\x95\\x02\\x09\\x30\\x09\\x31\\x81\\x06\\x15\\x81\\x25\\x7f\\x75\\x08\\x95\\x01\\x09\\x38\\x81\\x06\\x05\\x0c\\x0a\\x38\\x02\\x95\\x01\\x81\\x06\\xc0\\xc0 > functions/hid.usb0/report_desc

# just pipe the report descriptor from the tablet hid to the usb gadget
cat /sys/bus/hid/devices/0018\:2D1F\:0095.0001/report_descriptor > functions/hid.usb0/report_desc
#
hexdump -C functions/hid.usb0/report_desc

# assign function to configuration
ln -s functions/hid.usb0/ configs/c.1/

# bind!
echo "Activating gadget"
# echo fcc00000.usb > UDC # ls /sys/class/udc to see available UDCs
echo fcc00000.usb > /sys/kernel/config/usb_gadget/g1/UDC

# to unbind:
# echo "" > UDC
# echo "" > /sys/kernel/config/usb_gadget/g1/UDC

cleanup() {
	echo "Cleaning up"
	echo "" > /sys/kernel/config/usb_gadget/g1/UDC
}
trap cleanup SIGINT
cat /dev/hidraw0  | tee > /dev/hidg0
trap - SIGINT
