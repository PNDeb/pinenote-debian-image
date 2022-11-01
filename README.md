# pinenote-debian-recipes

Creates a Debian rootfs for the PineNote eink tablet. It uses [debos](https://github.com/go-debos/debos) to build a set of recipes organized as a build pipeline. The end result, a `tar.gz` file can be extracted onto an existing partition on the PineNote.

Currently, in order to install a Linux distribution on the PineNote, someone would follow installation guides like the ones written by Martyn\[1\] or Dorian\[2\]. This project addresses the later steps in the guides where someone needs to put a rootfs on the prepared Linux partition. You should be familiar with the content of those guides, as this project doesn't provide an easy way to install Debian on the PineNote, but merely a simple rootfs. This project allows creation of such a rootfs for the Debian distribution (`bookworm` by default). The existing debos recipes would `debootstrap`, add the provided (by you) kernel and firmware, install some basic programs and do some setup. Booting it on the PineNote would get you to the console. No graphical environments are installed.

  \[1\]: [https://musings.martyn.berlin/dual-booting-the-pinenote-with-android-and-debian](https://musings.martyn.berlin/dual-booting-the-pinenote-with-android-and-debian)

  \[2\]:  [https://github.com/DorianRudolph/pinenotes](https://github.com/DorianRudolph/pinenotes)

Check also, the fork\[3\] maintained by Maximilian Weigand. It's aim is to provide a quick way to get a full Gnome user experience with all the settings included.

  \[3\]:  [https://github.com/m-weigand/pinenote-debian-recipes/releases](https://github.com/m-weigand/pinenote-debian-recipes/releases)

## Build

You need to install `debos`, to clone this repo, to provide the kernel components in the right places, and then call `./build.sh` as a normal user.

For example, to install `debos` on a Debian bullseye (like me):
```
# apt install debos
```

### Feeding the kernel and firmwares to the project

This is the expected content of the `overlays` directory after the kernel and firmwares has been provided:
```
pinenote-debian-recipes/overlays/
├── boot
│   └── sysbootcmd
├── default
│   └── u-boot
├── firmware
│   ├── original-firmware.tar.gz
│   └── waveform.bin
└── local-debs
    └── linux-image-5.17.0-rc6-next-20220304-g824c1340af29_5.17.0-rc6-next-20220304-g824c1340af29-7_arm64.deb
```
Symbolic links doesn't work(!) so either use hard links or simply copy the files in the right place.

Some details (check also the recipes to see how they are used):

- `original-firmware.tar.gz` contains the `firmware/` directory which is found on the PineNote in `/vendor/etc/`.

#### Linux kernel

Drop a linux image Debian package into `overlays/local-debs` directory. But, *very important*:

The original U-Boot (v. 2017.09) that came with PineNote Developer Edition (pinenote-1.2) doesn't support gzipped kernel images. So when you are building `deb` kernel packages, insert `KBUILD_IMAGE=arch/arm64/boot/Image` into the `make ... bindeb-pkg` command line. Else, the generated `KBUILD_IMAGE` would point to `Image.gz` variant.

### Build the recipes
As a normal user, just run inside the `pinenote-debian-recipes` directory:
```
./build.sh
```
That would build a Debian `bookworm` rootfs, with a hostname `pinenote`, a user `user` with password `1234` and `sudo` capabilities. Also, it hardcodes the target PineNote partition to `/dev/mmcblk0p17` (see `overlays/default/u-boot`. TODO: try to make that an option instead).
To do that, `./build.sh` would call `debos` on each recipe in the default pipeline -- the file `recipes-pipeline`. Here is its content:
```
# calls debootstrap
rootminfs.yaml

# installs base programs like network-manager, sudo, parted ...
baseprograms.yaml

# PineNote's firmware files
setupfirmware.yaml

# Install local provided deb packages (like the kernel)
localdebs.yaml

# setup hostname, first user, ...
finalsetup.yaml
```
The work done by each recipe is saved as a `.tar.gz` file. So you would take the last archive, `finalsetup.tar.gz`, to extract on the PineNote. Currently, the archive's size is about 240MB and extracted into the partition would occupy almost 700MB.

## Install the rootfs on the PineNote
Basically, you have to extract the `finalsetup.tar.gz` inside the prepared partition. You need to follow Martyn's and Dorian's guides to get to this point.

Here is how I'm installing the rootfs. On my laptop connected to the PineNote booted in Android, I do:
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

# License

This software is licensed under the terms of the GNU General Public License, version 3.

Inspiration and some code parts are from [mobian-recipes project](https://gitlab.com/mobian1/mobian-recipes).
