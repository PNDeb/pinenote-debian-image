# pinenote-debian-recipes

<<<<<<< HEAD
Creates a Debian rootfs for the PineNote eink tablet. It uses [debos](https://github.com/go-debos/debos) to build a set of recipes organized as a build pipeline. The end results, are a `tar.gz` file can be extracted onto an existing partition on the PineNote and a filesystem image that can be directly flashed using [rkdeveloptool](https://gitlab.com/pine64-org/quartz-bsp/rkdeveloptool).

Currently, in order to install a Linux distribution on the PineNote, someone would follow installation guides like the ones written by Martyn\[1\] or Dorian\[2\], to prepare for dual booting alongside Android. This project addresses the later steps in the guides where someone needs to put a rootfs on the prepared Linux partition. You should be familiar with the content of those guides, as this project doesn't provide an easy way to install Debian on the PineNote, but merely a simple rootfs/image. This project allows creation of such a rootfs for the Debian distribution (`bookworm` by default). The existing debos recipes would `debootstrap`, add the provided (by you) kernel and firmware, install some basic programs and do some setup. Booting it on the PineNote would get you to the console. No graphical environments are installed.
=======
Creates a Debian rootfs for the PineNote eink tablet. It uses
[debos](https://github.com/go-debos/debos) to build a set of recipes organized
as a build pipeline. The end result, a `tar.gz` file can be extracted onto an
existing partition on the PineNote.

Currently, in order to install a Linux distribution on the PineNote, someone
would follow installation guides like the ones written by Martyn\[1\] or
Dorian\[2\]. This project addresses the later steps in the guides where someone
needs to put a rootfs on the prepared Linux partition. You should be familiar
with the content of those guides, as this project doesn't provide an easy way
to install Debian on the PineNote, but merely a simple rootfs. This project
allows creation of such a rootfs for the Debian distribution (`bookworm` by
default). The existing debos recipes would `debootstrap`, add the provided (by
you) kernel and components, install some basic programs and do some setup
including creating the `initrd` using `dracut`. Booting it on the PineNote
would get you to the console. No graphical environments are installed.
>>>>>>> 21f1377 (update README)

  \[1\]: [https://musings.martyn.berlin/dual-booting-the-pinenote-with-android-and-debian](https://musings.martyn.berlin/dual-booting-the-pinenote-with-android-and-debian)

  \[2\]:  [https://github.com/DorianRudolph/pinenotes](https://github.com/DorianRudolph/pinenotes)

Check also, the fork\[3\] maintained by Maximilian Weigand. It's aim is to provide a quick way to get a full Gnome user experience with all the settings included.

  \[3\]:  [https://github.com/m-weigand/pinenote-debian-recipes/releases](https://github.com/m-weigand/pinenote-debian-recipes/releases)

## Build

You need to install `debos`, to clone this repo, to provide the kernel
components in the right places, and then call `./build.sh` as a normal user.

For example, to install `debos` on a Debian bullseye (like me):
```
# apt install debos parted
```
`parted` is used by the project just for a check on the generated disk image.

### Feeding the kernel and firmwares to the project

This is the expected content of the `overlays` directory after the kernel and
firmwares has been provided:
```
pinenote-debian-recipes/overlays/
├── boot
│   └── sysbootcmd
├── default
│   └── u-boot
├── firmware
│   ├── brcm
│   │   └── brcmfmac43455-sdio.AW-CM256SM.txt
│   └── rockchip
│       └── ebc.wbf
└── local-debs
    └── linux-image-5.17.0-rc6-next-20220304-gca1ad0720d8f_5.17.0-rc6-next-20220304-gca1ad0720d8f-8_arm64.deb
```
<<<<<<< HEAD
=======
Symbolic links doesn't work(!) so either use hard links or simply copy the
files in the right place.
>>>>>>> 21f1377 (update README)

#### The firmware

<<<<<<< HEAD
You have to provide these files inside `overlays/firmware`:
- `rockchip/ebc.wbf` is the waveform data that can be taken from the device using `rkdeveloptool`.
- `brcm/brcmfmac43455-sdio.AW-CM256SM.txt` can be taken from https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/brcm/brcmfmac43455-sdio.AW-CM256SM.txt

And we take these files by installing packages from the Debian's repo:
- `brcm/brcmfmac43455-sdio.bin` provided by `firmware-brcm80211`.
- `brcm/BCM4345C0.hcd` provided by `bluez-firmware`.

#### Linux kernel

Drop a linux image Debian package into `overlays/local-debs` directory. But, *very important*:

The original U-Boot (v. 2017.09) that came with PineNote Developer Edition (pinenote-1.2) doesn't support gzipped kernel images. So when you are building `deb` kernel packages, insert `KBUILD_IMAGE=arch/arm64/boot/Image` into the `make ... bindeb-pkg` command line. Else, the generated `KBUILD_IMAGE` would point to `Image.gz` variant.
=======
- `original-firmware.tar.gz` contains the `firmware/` directory which is found
  on the PineNote in `/vendor/etc/`.
- `kernel-modules.tar.gz` contains the `/lib/modules/..` directory (entire
  hierarchy including starting with `/lib`)
>>>>>>> 21f1377 (update README)

### Build preparations

Run `prep_00_get_kernel_files.sh` and `prep_03_custom_debs.sh` first,
to prepare the external packages to use in the later build steps.

### Build the recipes
Run inside the `pinenote-debian-recipes` directory:
```
./build.sh
```
<<<<<<< HEAD
<<<<<<< HEAD
That would build a Debian `bookworm` rootfs, with a hostname `pinenote`, a user `user` with password `1234` and `sudo` capabilities. Also, it hardcodes the target PineNote partition to `/dev/mmcblk0p17` (see `overlays/default/u-boot`).
To do that, `./build.sh` would call `debos` on each recipe in the default pipeline -- the file `recipes-pipeline`. Here is its content:
=======
=======
(depending on your system configuration, you might need to run this command with superuser rights)

>>>>>>> 119fd69 (Update the readme slightly)
That would build a Debian `bookworm` rootfs, with a hostname `pinenote`, a user
`user` with password `1234` and `sudo` capabilities. Also, it hardcodes the
target PineNote partition to `/dev/mmcblk0p17` (TODO: try to make that an
option instead).
To do that, `./build.sh` would call `debos` on each recipe in the default
pipeline -- the file `recipes-pipeline`. Here is its content:
>>>>>>> 21f1377 (update README)
```
# calls debootstrap
rootminfs.yaml

# installs base programs like network-manager, sudo, parted ...
baseprograms.yaml

# Install local provided deb packages (like the kernel)
localdebs.yaml

# setup remaining firmware, initrd, hostname, first user, ...
finalsetup.yaml

<<<<<<< HEAD
# create a gpt disk image, with one partition
creatediskimage.yaml

# take from the disk image only our partition
takeoutpartition.yaml
```
#### Artefacts
The work done by each recipe is saved as a `.tar.gz` file, except for the last recipes who generate the image.

You could use the last archive, `finalsetup.tar.gz`, to extract on the PineNote. Currently, the archive's size is about 240MB and extracted into the partition would occupy almost 700MB.

Or, you can use directly the generated filesystem image, `debian.img` to flash with `rkdeveloptool`. The image size is 900MB, which is enough to fit the `cache` partition ;).

## Deployment

### Flash the filesystem image with `rkdeveloptool`

`debian.img` is the resulted filesystem image containing the files from `finalsetup.tar.gz`. You can flash this image on the device.
Be aware, that this image is configured with a kernel `root=` parameter as provided by `overlays/default/u-boot`. If you want to flash this image to another partition device, you can adjust the `root` parameter inside the image using the helper script `adjust-root-in-image.sh`. See the documentation provided inside the script file.

`debian.img` contains an `ext4` filesystem. You should probably flash it only on the `ext4` marked partitions on the device, unless you change the partition table too.

### Alternatively, you can install the rootfs on the PineNote
Basically, you have to extract the `finalsetup.tar.gz` inside the prepared partition. You need to follow Martyn's and Dorian's guides to get to this point.
=======
## Install the rootfs on the PineNote
Take the `*.tag.gz` file after the latest step and extract it to the prepared partition.
You need to follow Martyn's and Dorian's guides to get to this point.
>>>>>>> 119fd69 (Update the readme slightly)

For example, let `finalsetup.tar.gz` be the resulting archive.
Then, to install the rootfs using my laptop connected to the PineNote booted in Android, I do:
```
$ adb push finalsetup.tar.gz /sdcard/Download
$ adb shell
$ su
# mkdir /sdcard/target
# mount /dev/block/mmcblk2p17 /sdcard/target
# cd /sdcard/Download
# busybox tar xzf finalsetup.tar.gz -C /sdcard/target
# umount /sdcard/target
# exit
$ exit
```
Then I insert the UART dongle (and start `minicom -D /dev/ttyUSB0 -b 1500000` on my laptop), restart the tablet, hold `CTRL-C` to interrupt `u-boot`. And then, paste the `sysboot` command that I also made it available inside `pinenote-debian-recipes/overlays/boot/sysbootcmd`:
```
Interrupt => sysboot ${devtype} ${devnum}:11 any ${scriptaddr} /boot/extlinux/extlinux.conf
```
And that would boot our system on partition 17 (11 in base 16).

<<<<<<< HEAD
<<<<<<< HEAD
## First boot..
Things you might want to setup after the installation:

### Resize the filesystem to host partition size
`sudo resize2fs /dev/mmcblk2pXX`

### Generate the ssh server host keys
These keys are removed from the artefacts as they should be unique per system. Because they are missing the ssh service fails to start. Simple generate them on PineNote with:
```
sudo ssh-keygen -A
sudo systemctl start ssh
```

Also, change the **default password** before connection to public networks.

### Wifi
`sudo nmtui-connect`

(fixme: what needs to be set to do that without sudo?)
=======
=======
Alternatively, use the following set of commands:

```
load mmc 0:11 ${kernel_addr_r} /extlinux/Image
load mmc 0:11 ${fdt_addr_r} /extlinux/rk3566-pinenote-v1.2.dtb
load mmc 0:11 ${ramdisk_addr_r} /extlinux/uInitrd.img
setenv bootargs ignore_loglevel root=/dev/mmcblk0p17 rw rootwait earlycon console=tty0 console=ttyS2,1500000n8 fw_devlink=off init=/sbin/init
booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
```

>>>>>>> 119fd69 (Update the readme slightly)
# Misc

* Ignore any ssh issues when testing the rootfs:

	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no user@pinenote
>>>>>>> b82f3d0 (prepare the next iteration of the rootfs)

# License

This software is licensed under the terms of the GNU General Public License, version 3.

Inspiration and some code parts are from [mobian-recipes project](https://salsa.debian.org/Mobian-team/mobian-recipes).
