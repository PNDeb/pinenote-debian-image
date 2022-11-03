#!/bin/sh

diskimage="$1"
partimage="$2"

if [ ! -f "$diskimage" ]; then
	echo Error: could not find the disk image: $diskimage
	exit 1
fi

# Confirm to ourselves that the partition starts at sector 34.
/sbin/parted --script "$diskimage" unit s  print | tail -n 2 | grep -e "\<34s" > /dev/null
if [ ! $? ]; then
	echo Unexpected start of partition. Aborting.
	exit 2
fi

# extract the partition
dd if="$diskimage" of="$partimage" skip=34 status=progress

