#!/bin/bash
# switch the bootable-flag between partitions 17 and 18 using parted

# active_partition=$(parted /dev/mmcblk0 print | grep -e "^17" -e "^18" | nl | grep "boot, esp" | tr -d ' ' | cut -f 1)
active_partition=$(parted /dev/mmcblk0 print | grep -e "^17" -e "^18" | nl | grep "legacy_boot" | tr -d ' ' | cut -f 1)
echo ${active_partition}

if [ ${active_partition} -eq 1 ]; then
	echo "Partition 17 active, toggling to partition 18"
	parted /dev/mmcblk0 set 18 legacy_boot on
	parted /dev/mmcblk0 set 17 legacy_boot off
else
	echo "Partition 18 active, toggling to partition 17"
	parted /dev/mmcblk0 set 17 legacy_boot on
	parted /dev/mmcblk0 set 18 legacy_boot off
fi
