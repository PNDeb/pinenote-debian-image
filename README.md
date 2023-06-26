# Debian Bookworm Image for the Pine64 Pinenote

This repository provides means to build a full Debian rootfs and disc image for
the PineNote eink tablet that directly boots into GNOME, thereby providing a
robust linux experience.

The project originates in the work of Eugen Răhăian at
https://salsa.debian.org/eugenrh/pinenote-debian-recipes, which provides a
Debian base rootfs/image without any GUI.
It uses [debos](https://github.com/go-debos/debos) to build a set of recipes
organized as a build pipeline.
The end results, are a `tar.gz` file can be extracted onto an existing
partition on the PineNote and a filesystem image that can be directly flashed
using [rkdeveloptool](https://gitlab.com/pine64-org/quartz-bsp/rkdeveloptool),
or written to a partition using dd.

Currently, in order to install a Linux distribution on the PineNote, someone
would follow installation guides like the ones written by Martyn\[1\] or
Dorian\[2\], to prepare for dual booting linux alongside Android.

This project aims to simplifies things by providing disc images that can
(potentially) directly be flashed over USB using rkdeveloptool, without
touching the factory-testing Android installation.

  \[1\]: [https://musings.martyn.berlin/dual-booting-the-pinenote-with-android-and-debian](https://musings.martyn.berlin/dual-booting-the-pinenote-with-android-and-debian)

  \[2\]:  [https://github.com/DorianRudolph/pinenotes](https://github.com/DorianRudolph/pinenotes)

## First-boot activity

On first boot a shell script (/root/first_startup.sh) is executed that will
perform a few important tasks before executing an automatic reboot of the
system.
Depending in your method of booting you will need to supervise the UART output
for manual intervention of the boot process.

The Pinenote requires special waveform data to drive the epd display. It is
common to flash individualised waveform data to devices to accommodate
individual characteristics of the display panels.

This Debian install will extract the waveform data from partition number 3
(/dev/mmcblk0p03) and store it in /usr/lib/firmware/rockchip/ebc.wbf, where the
rockchip_ebc driver can find it.

Earlier versions of this install would attempt to extract firmware required for
WIFI and bluetooth from the factory Android installation.
However, this is not required anymore as all firmware can be obtained from the
Debian archives or directly from kernel.org (see
prep_04_firmware_kernel_archive.sh).

## Default user and hostname

Defaul hostname is `pinenote`, the configured (with auto-login via gdm3) user
is called `user` with password `1234` and `sudo` capabilities.

## Installation of disc image

### Installation via rkdeveloptool

See [partition_tables/Readme.md](partition_tables/Readme.md) for more
information.

### Installation from an already running linux system

Download the image file (here: debian.img.zst) and extract it, then copy it
using dd to the desired partition (here: /dev/mmcblk0p8)::

	zunstd debian.img.zst
	dd if=debian.img of=/dev/mmcblk0p8 bs=4MB status=progress

`debian.img` contains an `ext4` filesystem. You should probably flash it only
on the `ext4` marked partitions on the device, unless you change the partition
table too.

If you want to flash this image to another partition device, you can adjust the
`root` parameter inside the image using the helper script
`adjust-root-in-image.sh` before building the image. See the documentation
provided inside the script file.

However, the installation will automatically fix any issues with other root
partitions on first boot, and therefore it should not be necessary to rebuild
the image just to install to another partition. See above for information on
how to boot other partitions using the u-boot prompt.


## Installation of rootfs

The rootfs is a tar.gz file containing the compressed contents of the Debian
root filesystem, to be extracted on an empty ext4 partition on the Pinenote.

[...]

### Installation on partition /dev/mmcblk0p17

The rootfs, by default, is configured to cleanly boot using the u-boot
extlinux.conf mechanism when extracted to partition /dev/mmcblk0p17

[...]

For Android, the following commands have been used for the installation:

	$ adb push pinenote_arm64_debian_bookworm.tar.gz /sdcard/Download
	$ adb shell
	$ su
	# mkdir /sdcard/target
	# mount /dev/block/mmcblk2p17 /sdcard/target
	# cd /sdcard/Download
	# busybox tar xzf pinenote_arm64_debian_bookworm.tar.gz -C /sdcard/target
	# umount /sdcard/target
	# exit
	$ exit

Following this, insert the UART dongle into the Pinenote USB-C port (and start
`minicom -D /dev/ttyUSB0 -b 1500000` on the computer), restart the tablet, hold
`CTRL-C` to interrupt `u-boot` and get into the u-boot prompt.
Use the following `sysboot` command in the u-boot prompt to boot from partition
17
```
sysboot ${devtype} ${devnum}:11 any ${scriptaddr} /boot/extlinux/extlinux.conf
```

### Installation on other partitions

Example for first boot from the u-boot prompt for partition 8
(/dev/mmcblk0p8):

	load mmc 0:8 ${kernel_addr_r} /boot/emergency/image
	load mmc 0:8 ${fdt_addr_r} /boot/emergency/rk3566-pinenote-v1.2.dtb
	load mmc 0:8 ${ramdisk_addr_r} /boot/emergency/initrd_ub
	setenv bootargs ignore_loglevel root=/dev/mmcblk0p6 rw rootwait earlycon console=tty0 console=ttyS2,1500000n8 fw_devlink=off init=/sbin/init
	booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}

## Using another partition for /home

For now this only applies to partition 10 (/dev/mmcblk0p10) corresponding to
the data partition of the standard partition layout.

The standard partition layout contains a data partition that can be used to
mount user data (/home).

If you are completely reflashing your PineNote, then a small partition file
(data_part_dummy.bin) is provided that contains a valid ext4 file system with
the corresponding files (see below). On first boot the first_boot script will
check for those files and will change the fstab accordingly, as well as grow
the file system to the full size.

If you already got your home data on the partition, just make sure to create
the (empty) file pn_use_as_home on partition 10.

* Files to place on the partition:
	* pn_use_as_home: If this file on a partition, then mount it as /home
	* pn_grow_fs: if this file exists, grow the filesystem to the maximum size
	  using resize2fs

## First boot..

Things you might want to setup after the installation:

Change the **default password** before connection to public networks.

### PineNote-specific Debian repository

**builds after 26. June 2023 should include the repository configuration by default! **

Download the gpg key here: [pinenote_repo_key_2.gpg](overlays/keyrings/pinenote_repo_key_2.gpg)

At this point no stable update procedures for patched packages is implemented.
However, a package repository is being tested to provide updates to those
patches packages.

WARNING: At this point, do use at your own risk and make sure to always double
check any apt output before proceeding with updates.

The repository and the associated gpg key must be added manually:

	* Create the file **/etc/apt/preferences.d/98_pinenote.mweigand.net** to
	  make sure any package in the PineNote-specific repository will get
	  higher priority than any stock Debian package:

		Package: *
		Pin: origin "pinenote.mweigand.net"
		Pin-Priority: 1100

	* Download the public gpg key of the repository (note: this key is very
	  short-lived, with a life time of 1-6 months):

		wget -o /etc/apt/keyrings/pinenote_repo_key_2.gpg https://github.com/PNDeb/pinenote-debian-image/raw/dev/overlays/keyrings/pinenote_repo_key_2.gpg

	  sha256 checksum of the key file:

		f0493a4c400af773d472e3b8b5d2f6d687e131b2cd2a87e421fcf5c10bbb1943  pinenote_repo_key_2.gpg

	* Add the repository **AT THE TOP** of the sources list file **/etc/apt/sources.list**:

		deb [signed-by=/etc/apt/keyrings/pinenote_repo_key_2.gpg] http://pinenote.mweigand.net/repository/ bookworm main

	* apt update && apt upgrade

### Wifi

`sudo nmtui-connect`

(fixme: what needs to be set to do that without sudo?)

### Misc

* Ignore any ssh issues when testing the rootfs:

	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no user@pinenote

## Building the rootfs/disc image using debos

You need to install `debos`, to clone this repo, to provide the kernel
components in the right places, and then call `./build.sh` as a normal user.

For example, to install `debos` on a Debian bullseye (like me):
```
# apt install debos parted
```
`parted` is used by the project just for a check on the generated disk image.

Before the build can be started, some external files need to be downloaded
using the prep* scripts.
Those scripts download kernel packages, some patches Debian packages for the
Pinenote, and some additional programs useful for the Pinenote not found in the
official Debian repositories.
You are encouraged to check those scripts before executing them.
Following these preparations the actual build can be started.

	./prep_00_get_kernel_files.sh
	./prep_02_get_parse-android-dynparts.sh
	./prep_03_custom_debs.sh
	./prep_04_firmware_kernel_archive.sh
	./build.sh

Make sure to have something like 8-10 G of RAM available.

The work done by each recipe is saved as a `.tar.gz` file, except for the last
recipes who generate the image.

You could use the last archive, `pinenote_arm64_debian_bookworm.tar.gz` to
extract on the PineNote. Currently, the archive's size is about 1.5 GB and
extracted into the partition would occupy almost 5500MB.

Or, you can use directly the generated filesystem image, `debian.img` to flash
with `rkdeveloptool`. The image size is 6GB.

### Kernel requirements

The original U-Boot (v. 2017.09) that came with PineNote Developer Edition
(pinenote-1.2) doesn't support gzipped kernel images. So when you are building
`deb` kernel packages, insert `KBUILD_IMAGE=arch/arm64/boot/Image` into the
`make ... bindeb-pkg` command line. Else, the generated `KBUILD_IMAGE` would
point to `Image.gz` variant.

Pre-built kernel images/.deb files can be found here:
https://github.com/m-weigand/linux/releases

Take a look at the github action and Docker files in the `description` branch
of  https://github.com/m-weigand/linux for more information on kernel
compilation and preparation.

### Modifying the image build

`debos` is controlled using the build.sh script, which in turns uses the
various .yaml files for the actual building process. The various .yaml files
are chained together using the `recipes-pipeline` file and makes it easy to
modify the whole process.

# License

This software is licensed under the terms of the GNU General Public License,
version 3.

Inspiration and some code parts are from [mobian-recipes project](https://salsa.debian.org/Mobian-team/mobian-recipes).

# TEST: Video

https://github.com/m-weigand/pinenote-debian-recipes/raw/dev/videos/20221210_xpp_faster_faster_faster_small.mp4
