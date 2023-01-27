# Partition tables for flashing using rkdeveloptool

## Workflow for repartitioning and flashing

* Make sure to:
	* Have a full backup of the PineNote
	* Be ready to recover from any errors (i.e., have the UART-board ready or
	  tools to open up the PineNote)
	* You need to have a u-boot that can access data beyond 32 mb on the disc and that automatically detects extlinux.conf files on the partitions.
	  * See https://github.com/DorianRudolph/pinenotes#fix-uboot for fixing the 32mb problem (there is a link to a backup binary that you could use)
	  * Enabling the "search-for-exlinux.conf-file"-functionality in uboot can be accomplished by modifying the environment of the modified uboot partition (e.g., the backup provided by DorianRudolp). Use the file pinenote-uboot-envtool.py from  https://gist.github.com/charasyn/206b2537534b6679b0961be64cf9c35f, but instead of using the u-boot-patch provided by charasyn, just replace the *bootcmd* command of the environment with `bootcmd=run distro_bootcmd;` This modified image can be flashed using `rkdeveloptool write-partition uboot modifie_uboot.img

* Flashing commands:

	  # create backups (do this BEFORE altering any of the partitions!)
	  # If you already altered partitions, skip this step and write back
	  # partition backup you did before in the later step
	  rkdeveloptool read 0 41943040 first_40mb_of_disc.img
	  rkdeveloptool read-partition boot part_boot.img
	  rkdeveloptool read-partition trust part_trust.img
	  rkdeveloptool read-partition dtbo part_dtbo.img
	  rkdeveloptool read-partition waveform part_waveform.img
	  rkdeveloptool read-partition uboot part_uboot.img
	  rkdeveloptool read-partition logo part_logo.img
	  rkdeveloptool read-partition recovery part_recovery.img

	  # write new GPT partition table
	  rkdeveloptool write-partition-table partition_table_standard1.txt

	  # write new u-boot
	  rkdeveloptool write 64 idblock.bin
	  rkdeveloptool write-partition uboot uboot.img

	  # write partitions that were moved
	  rkdeveloptool write-partition boot part_boot.img
	  rkdeveloptool write-partition dtbo part_dtbo.img
	  rkdeveloptool write-partition logo part_logo.img

	  # write debian image to bootable partition
	  rkdeveloptool write-partition os1 debian.img
