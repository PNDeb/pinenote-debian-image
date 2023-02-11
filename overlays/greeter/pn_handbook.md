# PineNote Debian Bookworm

## Introduction

Hi there, nice of you to install this Debian image on your PineNote!

Before you begin, please bear in mind that the PineNote, and this image, is
aimed a experienced users and developers, and many things need manual tweaking
or do not just work yet.
However, many things also use, and you can take control of quite a lot of
things.
If you have not done this yet, we strongly recommend to at least skim this
document before proceeding to use your PineNote.

If you want to improve this text, merge requests are very very much appreciated!
(https://github.com/m-weigand/pinenote-debian-recipes/blob/dev/overlays/greeter/pn_handbook.md")[Improve here]

## Getting started

* User/Password: You are logged in as user "user" with password "1234". sudo is
  activated. We suggest to set a root password:

	sudo su - root
  	passwd

* The **Documents/** directory contains one sample .pdf and one .epub file. Try
  opening them and start reading!

* You may want to reconfigure your locales:

	sudo dpkg-reconfigure locales

* The status bar at the top contains the refresh button and the PineNote-Helper
  Gnome extension, which helps you to control some aspects of the eink display.
  Both of these items will become important for an effective use of the
  PineNote in a Gnome environment.

## Updates

Apart from a number of tweaks aimed at producing an improved user experience on the PineNote, and a few patched packages, you are running a Debian Bookworm operating system which can be maintained as very other system. Use apt or aptititude to manage you packages.

The modified packages that were installed were also pinned, meaning they will not be overwritten by updates. At some point other packages will also not be automatically updated because they depend on newer versions of the pinned packages, which will need manual intervention at some point. Currently there is no easy way to update the modified packages and solutions are discussed in this issue: https://github.com/m-weigand/pinenote-debian-recipes/issues/38

## Using another partition for /home

By default /home is located on the root partition. However, a bash script is
provided in `/root/switch_home_to_other_partition.sh` which can be used to
change the partition that is used for /home. The script can also transfer data
from the current /home to the new partition. Call as root.

Example to switch /home to /dev/mmcblk0p19:

	cd /root
	switch_home_to_other_partition.sh /dev/mmcblk0p19

## How do I

* **Read a book (epub)/pdf**: Koreader is already installed and should be
  registered for corresponding file types
* **Take notes**: Xournalpp was slightly modified to provide an improved
  experience on the Pinenote.
* **Use the Pinenote as an external screen?**: TODO, link to weylus project
* **Use an external monitor with the Pinenote?**: TODO (won't directly work,
  need something like vnc and virtual monitor)

## Documentation for apps/systems

### EBC Kernel Driver

The EBC subsystem controls the eink (or epd) display and is one of components which require
most tweaking for each user.

	* ioctls

		* trigger global refresh
		* set offline-screen
		* [to implement] set standby screen mask & behavior
	* misc:

		* discuss the waveform-switching issues in a general DE environment:
		  recommend to always do a global refresh after switching waveforms,
		  unless you know that your buffer is compatible
### Usage

All module parameters are controlled using the sysfs parameters in
/sys/module/rockchip_ebc/parameters

The module parameters can also be set on module load time, for example using
the modprobe configuration file:

	root@pinenote:~# cat /etc/modprobe.d/rockchip_ebc.conf
	options rockchip_ebc direct_mode=0 auto_refresh=1 split_area_limit=0 panel_reflection=1

By default the parameters in /sys/module/rockchip_ebc/parameters need to be writen to as root, but this can be easily changed
via udev rules.

Overview of sysfs-parameters:

* TODO

In addition, two custom ioctls are currently implemented for the ebc driver:

* TODO

### Black and White mode

Activate with

	echo 1 > /sys/module/rockchip_ebc/parameters/bw_mode

the threshold value can be set using:

	echo 7 > /sys/module/rockchip_ebc/parameters/bw_threshold

7 is the default value, meaning that all pixel values lower than 7 will be cast
to 0 (black) and all values larger than, or equal to, 7 will be cast to 15
(white).

### Auto Refresh

Enabling automatic global (full screen) refreshes:

	echo 1 > /sys/module/rockchip_ebc/parameters/auto_refresh

Global refreshes are triggered based on the area drawing using partial
refreshes, in units of total screen area.

	echo 2 > /sys/module/rockchip_ebc/parameters/refresh_threshold

therefore will trigger a globlal refresh whenever 2 screen areas where drawn.

The threshold should be set according to the application used. For example,
evince and xournalpp really like to redraw the screen very often, so a value of
20 suffices.
Other require lower numbers.

The waveform to use for global refreshes can be set via

	echo 4 > /sys/module/rockchip_ebc/parameters/refresh_waveform

A value of 4 is the default.

### Waveforms

* the **default_waveform** parameter controls which waveform is used. Based on
  information from include/drm/drm_epd_helper.h, the integer values are
  associated with the following waveforms:

		0: @DRM_EPD_WF_RESET: Used to initialize the panel, ends with white
		1: @DRM_EPD_WF_A2: Fast transitions between black and white only
		2: @DRM_EPD_WF_DU: Transitions 16-level grayscale to monochrome
		3: @DRM_EPD_WF_DU4: Transitions 16-level grayscale to 4-level grayscale
		4: @DRM_EPD_WF_GC16: High-quality but flashy 16-level grayscale
		5: @DRM_EPD_WF_GCC16: Less flashy 16-level grayscale
		6: @DRM_EPD_WF_GL16: Less flashy 16-level grayscale
		7: @DRM_EPD_WF_GLR16: Less flashy 16-level grayscale, plus anti-ghosting
		8: @DRM_EPD_WF_GLD16: Less flashy 16-level grayscale, plus anti-ghosting

* (side note): Based on information from drivers/gpu/drm/drm_epd_helper.c, the
  Pinenote uses eps lut form 0x19, which associated waveform types with the
  luts stored in the file as:

		.versions = {
		    0x19,
		    0x43,
		},
		.format = DRM_EPD_LUT_5BIT_PACKED,
		.modes = {
		    [DRM_EPD_WF_RESET]  = 0,
		    [DRM_EPD_WF_DU]     = 1,
		    [DRM_EPD_WF_DU4]    = 7,
		    [DRM_EPD_WF_GC16]   = 2,
		    [DRM_EPD_WF_GL16]   = 3,
		    [DRM_EPD_WF_GLR16]  = 4,
		    [DRM_EPD_WF_GLD16]  = 5,
		    [DRM_EPD_WF_A2]     = 6,
		    [DRM_EPD_WF_GCC16]  = 4,
		},

  For example, if you want to inspect/modify the A2 waveform, this corresponds
  to the 7th waveform in the lut file (index 6), but is activated via
  **default_waveoform** by writing value 1.

### Trimming the A2 waveform

You can trim the A2 waveform for improved writing performance, with the
downside that black sometimes is displayed in gray tones.

The supplied script is very slow and unoptimized and therefore not run
automatically (run time on pinenote ca. 20 minutes).

Call these command in a root shell to trim the A2 waveform (note: this will
reboot the pinenote once):

	cd /root
	# this command should take ca. 20 minutes !!!
    time python3 parse_waveforms_and_modify.py
	# save the original waveforms for later use
    mv /lib/firmware/rockchip/ebc.wbf /lib/firmware/rockchip/ebc_orig.wbf
   	ln -s /lib/firmware/rockchip/ebc_modified.wbf /lib/firmware/rockchip/ebc.wbf
	update-initramfs -u -k all
	reboot

### Xournalpp/Writing

* At this point, despite disabling animations, GNOME still shows the spinning
  animation in the panel when xournalpp is started. This prevents proper and
  fast drawing of screen regions. For best experience, wait until the loading
  animation stops before you start drawing/writing.
* Switch to "BW+Dither" mode when working in Xpp
* The default configuration uses evsieve to merge events from the pen (for
  drawing) and the pen buttons. This is a solution to the problem that the pen
  input and the pen buttons are completely independent systems and therefore
  register as different inputs in the system.

  The evsieve solution add something like 15 ms lag to the input (according to
  the evsieve readme). You can disable this approach by running (in a root
  shell):

	systemctl stop evsieve.service
	systemctl disable evsieve.service

  Make sure to restart Xpp and to reconfigure the input sources in the
  settings.
* By default the touch screen is disabled as an input for Xpp. You need to
  activate it in the settings in order to scroll using touch gestures.
* If the pen buttons are configured, holding down the button nearest to the tip
  should allow you to scroll using the pen.
* After both pen and touch scrolling a global refresh is triggered

## What is not working?

* Open Issues

	* Gnome extension: There are issues when suspend/screen blanking (i.e.,
	  unloading of the extension is broken)
	* EBC artifacting
	* Cover detection ?
	* Resume/suspend
	* BT Issues (link to probably-working firmware?)

# Topics

* DBUS service

	* contrl ebc driver
	* [to implement] handle pen pairing/unpairing

* The GNOME extension
* Pen
* Blocked packages & updates
* Resources
