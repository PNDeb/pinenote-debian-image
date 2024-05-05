# Using the PineNote Debian image on the Quartz64-A

## Partitioning

### Using the usb-to-mmc adapter

	parted -s /dev/sdd mklabel gpt
	parted -s /dev/sdd unit s mkpart loader 64 9MiB
	parted -s /dev/sdd unit s mkpart dummy1 ext4 9MiB 10MiB
	parted -s /dev/sdd unit s mkpart waveform ext4 10MiB 91MiB
	parted -s /dev/sdd unit s mkpart os1 ext4  91MiB 100% ;
	parted -s /dev/sdc set 4 boot on

load mmc 0:4 ${kernel_addr_r} /boot/vmlinuz-6.3.10-pinenote-202312092104-gd4dec0cb83b9
load mmc 0:4 ${fdt_addr_r} /usr/lib/linux-image-6.3.10-pinenote-202312092104-gd4dec0cb83b9/rockchip/rk3566-quartz64-a.dtb
58431 bytes read in 37 ms (1.5 MiB/s)
load mmc 0:4 ${ramdisk_addr_r} /boot/initrd.img-6.3.10-pinenote-202312092104-gd4dec0cb83b9
setenv bootargs root=/dev/mmcblk1p4 mem=4G ignore_loglevel rw rootwait earlycon console=tty0 console=ttyS2,1500000n8 fw_devlink=off
booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
