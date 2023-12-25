# Using the PineNote Debian image on the Quartz64-A

## Partitioning

### Using the usb-to-mmc adapter

	parted -s /dev/sdd mklabel gpt
	parted -s /dev/sdd unit s mkpart loader 64 9MiB
	parted -s /dev/sdd unit s mkpart dummy1 ext4 9MiB 10MiB
	parted -s /dev/sdd unit s mkpart waveform ext4 10MiB 91MiB
	parted -s /dev/sdd unit s mkpart os1 ext4  91MiB 100% ;
	parted -s /dev/sdc set 4 boot on
