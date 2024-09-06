#!/bin/bash

function quit_with_warning(){
	echo "Did not find /uboot_config/uboot.env"
	echo "Try mounting /uboot_config"
	exit
}

test -e /uboot_config/uboot.env || quit_with_warning


items=(1 "Partition 5 (OS 1)"
	   2 "Partition 6 (OS 2)"
       3 "AUTO")

choice=$(dialog --title "$TITLE" \
                 --menu "What default partition should be booted?" 15 80 4 "${items[@]}" \
                 2>&1 >/dev/tty)
case $choice in
        1)
		echo "Setting boot partition to: Partition 5"
		fw_setenv bootmenu_0 "Boot OS1=sysboot mmc 0:5 any \${scriptaddr} /boot/extlinux/extlinux.conf"
	       	;; # some action on 1
        2)
		echo "Setting boot partition to: Partition 6"
		fw_setenv bootmenu_0 "Boot OS2=sysboot mmc 0:6 any \${scriptaddr} /boot/extlinux/extlinux.conf"
		;; # some action on 2
	3)
		echo "Setting boot partition to: AUTO"
		fw_setenv bootmenu_0 "Search for extlinux.conf on all partitions=run scan_dev_for_boot_part"
		;;
        *) ;; # some action on other
esac
clear
