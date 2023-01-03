# Flashing the Debian image using usb/rkdeveloptools

**WARNING WARNING WARNING**

**These instructions are work in progress and are not (yet) tested thoroughly. Use with greatest care! May leave your Pinenote in a hard-to-recover unbootable state!**

* get rkdeveloptool
* get rk356x_spl_loader_v1.12.112.bin from one of the artifacts from https://gitlab.com/pgwipeout/quartz64_ci/-/pipelines
* select a partition layout that you want to realise (or create your own, see
  section below)
* put Pinenote into maskrom mode (https://wiki.pine64.org/wiki/PineNote_Development#Entering_Maskrom/Rockusb_Mode)
* boot the spl loader

	rkdeveloptool boot rk356x_spl_loader_v1.12.112.bin

* (optional, but STRONGLY recommended) make backup of pinenote
* check that everything is working:

	$ rkdeveloptool list-partitions
	#   LBA start (sectors)  LBA end (sectors)  Size (bytes)       Name
	00                16384              24575       4194304       uboot
	01                24576              32767       4194304       trust
	02                32768              36863       2097152       waveform
	[...]

* Write the new partition table:

	rkdeveloptool write-partition-table partition_table_full.txt

* Write the image to the starting sector of the root partition:

	rkdeveloptool write [START SECTOR] [IMGAE FILENAME]

* reset the Pinenote

	rkdeveloptool reset
