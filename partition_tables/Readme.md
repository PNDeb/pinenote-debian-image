# Flashing the PineNote using rkdeveloptool

This approach, if successfull, allows you to flash a new operating system to the PineNote without the need for the UART adapter. A working usb-c cable and the pen (i.e., a magnet) should suffice.

**NOTE:** In case something goes wrong the UART adapter could be required. If things go really wrong, opening up the device could also be required!

## Workflow for repartitioning and flashing
* See troubleshooting sections below for solutions to common problems
* Refer to the next section for information on the standard partition layout that is promoted here
* Make sure to:
	* Read the main [Readme file](../README.md)
	* Have a working installation of Pine64's fork of
	  [rkdeveloptool](https://gitlab.com/pine64-org/quartz-bsp/rkdeveloptool).
	  Note as of 6. July 2023, this fork is in Debian unstable (check for version number beginning with 1.32+pine64).
	* Have a full backup of the PineNote
	* Be ready to recover from any errors (i.e., have the UART-board ready or
	  tools to open up the PineNote)
	* You need to have a u-boot that can access data beyond 32 mb on the disc and that automatically detects extlinux.conf files on the partitions.
	  There are (at least) two possible ways to get such a u-boot:
	    * Patch the factory-flashed u-boot (ONLY batch-1 PineNotes):
	      * See https://github.com/DorianRudolph/pinenotes#fix-uboot for fixing the 32mb problem (there is a link to a backup binary that you could use)
	      * Enabling the "search-for-exlinux.conf-file"-functionality in uboot can be accomplished by modifying the environment of the modified uboot partition (e.g., the backup provided by DorianRudolp). Use the file pinenote-uboot-envtool.py from  https://gist.github.com/charasyn/206b2537534b6679b0961be64cf9c35f, but instead of using the u-boot-patch provided by charasyn, just replace the *bootcmd* command of the environment with `bootcmd=run distro_bootcmd;` This modified image can be flashed using `rkdeveloptool write-partition uboot modifie_uboot.img
	    * **(preferred option)** An alternative u-boot (idblock.bin, uboot.img, trust.img) can be found in the **uboot files**-artifact of the CI builds of this repository. Note that this u-boot version does only boot extlinux.conf linux distributions by default - you will loose (easy) access to any android systems.
	* For writing the partition table, you need the `rk356x_spl_loader_v1.12.112.bin` file (there are newer ones available, but this version has been verified to work. See troubleshooting section at the end of this document). This file can either be directly created from the rkbin repository, or should be available as a pre-built artifact in the latest CI build or in the latest release.
 	To generate it from the rockchip-provided binaries, use the following commands::

            git clone --shallow-since="2022-01-02T00:00:00Z" https://github.com/rockchip-linux/rkbin
            cd rkbin
            git checkout b6354b9
            tools/boot_merger RKBOOT/RK3566MINIALL.ini

* Preparation:
        * Download the new partition table file (from this repository): [partition_table_standard2.txt](partition_table_standard2.txt)
	* From the latest release (or latest CI build), download the following artifacts:
         * the spl loader:
           * **rk356x_spl_loader_v1.12.112.bin**
         * (optional): the u-boot artifacts:
           * **idblock.bin**
           * **trust.img**
           * **uboot.img**
         * one disc image for either partition 5 (label: os1) or 6 (label: os2):
           * **debian_partition_5.img.zst**
           * or **debian_partition_6.img.zst**
         * (optional) a dummy partition for the data partition (nr 7, label: data). This small blob is flashed to the partition to indicate that it should be used to mount /home for the newly installed system. Not recommended when os installed to both os1 and os2 partitions.
           * **data_part_dummy_p5.img**
           * or **data_part_dummy_p6.img**
	* unzip the artifacts (and unzstd the disc image), for example:

			unzip debian_partition_5.zip && unzstd debian_partition_5.img.zst

* Flashing commands:

  * Backuping existing factory partitions (batch 1):
    
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

  * Flashing new partition layout and image:
    
		  # enable `write-partition-table` commands
		  rkdeveloptool reboot-maskrom
		  rkdeveloptool boot rk356x_spl_loader_v1.12.112.bin
	
		  # write new GPT partition table
		  rkdeveloptool write-partition-table partition_table_standard2.txt
	
		  # (optional) write new u-boot
		  # idblock.bin is only required if you compiled u-boot yourself (the rockchip u-boot)
		  rkdeveloptool write 64 idblock.bin
		  rkdeveloptool write-partition uboot uboot.img
	
		  # write partitions that were moved (only for old partition layouts - not required for batch 2)
      		  # for old PNs: use part_logo_new.img from recent release (ask in the chat if you do not find it - it's still in preparation)
		  rkdeveloptool write-partition logo part_logo.img
	
		  # write debian image to bootable partition
		  rkdeveloptool write-partition os1 debian_partition_5.img
	          # alternatively:
	  	  # rkdeveloptool write-partition os2 debian_partition_6.img
	
		  # (optional) write data partition dummy so this partition is used as /home
		  # Note: This image is too small to hold an ext4 journal, I'm not sure just
		  # calling resize2fs on it activates the journal. Consider this a bug in the
		  # first_boot script
		  rkdeveloptool write-partition data data_part_dummy_for_os_p5.bin
	  	  # alternatively, and only if you want p10 as /home for os2!!!
	  	  # rkdeveloptool write-partition data data_part_dummy_for_os_p6.bin
						  
		  # just to make sure, turn the PineNote off by holding the power button for more than 10 seconds
		  # then turn in on again and wait (takes a little bit for the first-boot script to extract the
		  # waveforms and to reboot before linux can access the epd panel

## The standard1 partition table will partition the PineNote disc as follows:

	root@pinenote:~# parted /dev/mmcblk0
	GNU Parted 3.5
	Using /dev/mmcblk0
	Welcome to GNU Parted! Type 'help' to view a list of commands.
	(parted) print
	Model: MMC Biwin (sd/mmc)
	Disk /dev/mmcblk0: 124GB
	Sector size (logical/physical): 512B/512B
	Partition Table: gpt
	Disk Flags:

	Number  Start   End     Size    File system  Name       Flags
	 1      8389kB  12.6MB  4194kB               uboot
	 2      12.6MB  16.8MB  4194kB               trust
	 3      16.8MB  18.9MB  2097kB               waveform
	 4      18.9MB  19.9MB  1049kB               uboot_env
	 5      19.9MB  36.7MB  16.8MB               logo
	 6      36.7MB  40.9MB  4194kB               dtbo
	 7      40.9MB  82.8MB  41.9MB               boot
	 8      82.8MB  10.8GB  10.7GB  ext4         os1        legacy_boot
	 9      10.8GB  21.6GB  10.7GB               os2
	10      21.6GB  124GB   102GB                data

	(parted) u
	Unit?  [compact]? s
	(parted) print
	Model: MMC Biwin (sd/mmc)
	Disk /dev/mmcblk0: 241827840s
	Sector size (logical/physical): 512B/512B
	Partition Table: gpt
	Disk Flags:

	Number  Start      End         Size        File system  Name       Flags
	 1      16384s     24575s      8192s                    uboot
	 2      24576s     32767s      8192s                    trust
	 3      32768s     36863s      4096s                    waveform
	 4      36864s     38911s      2048s                    uboot_env
	 5      38912s     71679s      32768s                   logo
	 6      71680s     79871s      8192s                    dtbo
	 7      79872s     161791s     81920s                   boot
	 8      161792s    21133311s   20971520s   ext4         os1        legacy_boot
	 9      21133312s  42104831s   20971520s                os2
	10      42104832s  241827806s  199722975s               data


## Troubleshooting

* Hanging during **write-partition** commands: Check your usb cable. Quite a lot of cables were reported to lead to all kinds of failures.
* Device booting directly into *Loader* mode instead of *Maskrom*: It has been reported that sometimes the PineNote boots directly into the *Loader* mode when the magnetic-pen-method is used. While this is probably some kind of bug, it can be easily fixed using the **reboot-maskrom** command contained in rkdeveloptool:

		$ rkdeveloptool list
		DevNo=1	Vid=0x2207,Pid=0x350a,LocationID=102	Loader
		$ rkdeveloptool reboot-maskrom
		Reset Device OK.
		$ rkdeveloptool list
		DevNo=1	Vid=0x2207,Pid=0x350a,LocationID=102	Maskrom

Note that the initial *Loader* mode **could** also be functional, just try writing/reading the partitions before going trough the effort to boot the rk356x_spl_loader_v1.12.112.bin
